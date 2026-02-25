function Get-WindowsAutoRunOverview {
    <#
    .SYNOPSIS
    Retrieves all autorun/startup applications and configurations from the Windows system.

    .DESCRIPTION
    Collects comprehensive information about all autorun locations on the system including:
    - Registry Run keys (HKLM and HKCU, including RunOnce and Policy Run keys)
    - Startup folders (All Users and Current User)
    - Scheduled tasks configured to run at computer startup (Machine scope - Boot triggers)
    - Scheduled tasks configured to run at user logon (User scope - Logon triggers)
    - Services set to automatic start
    - Active Setup registry entries
    - Winlogon registry keys (Userinit, Shell, VmApplet, AppSetup, System)
    - BootExecute registry entries
    - Group Policy startup/shutdown/logon/logoff scripts

    This function only retrieves data and returns it as objects. Use Get-WindowsAutoRunInventory
    to save the data to the system inventory JSON file.

    .OUTPUTS
    [PSCustomObject[]]
    Returns an array of autorun entries with properties: Name, Command, Location, RegistryPath, Scope, Type, Category

    .PARAMETER IncludeServices
    Include Windows Services that are set to Automatic start. Default is $false to reduce data volume.

    .PARAMETER IncludeScheduledTasks
    Include Scheduled Tasks that run at computer startup (Boot triggers) or user logon (Logon triggers). Default is $true.

    .EXAMPLE
    PS C:\> Get-WindowsAutoRunOverview
    Retrieves all autorun entries and returns them as objects

    .EXAMPLE
    PS C:\> Get-WindowsAutoRunOverview -IncludeServices
    Includes Windows Services set to automatic start in the results

    .EXAMPLE
    PS C:\> Get-WindowsAutoRunOverview | Where-Object { $_.Category -eq 'Registry' }
    Gets only registry-based autorun entries

    .EXAMPLE
    PS C:\> Get-WindowsAutoRunOverview | Where-Object { $_.Scope -eq 'Machine' }
    Gets only Machine scope entries (computer startup, not user logon)

    .EXAMPLE
    PS C:\> Get-WindowsAutoRunOverview | Where-Object { $_.Scope -eq 'User' }
    Gets only User scope entries (user logon tasks and registry)

    .EXAMPLE
    PS C:\> Get-WindowsAutoRunOverview | Export-Csv -Path C:\AutoRun.csv -NoTypeInformation
    Exports autorun data to CSV file

    .NOTES
    Function  : Get-WindowsAutoRunOverview
    Author    : John Billekens
    CoAuthor  : GitHub Copilot
    Copyright : Copyright (c) John Billekens Consultancy
    Version   : 2025.1116.1300
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$IncludeServices = $false,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeScheduledTasks = $true
    )

    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"

        # Define all registry run key locations
        $registryPaths = @(
            @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Scope = "Machine"; Type = "Run" }
            @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"; Scope = "Machine"; Type = "RunOnce" }
            @{Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Scope = "Machine"; Type = "Run (32-bit)" }
            @{Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce"; Scope = "Machine"; Type = "RunOnce (32-bit)" }
            @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Scope = "User"; Type = "Run" }
            @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"; Scope = "User"; Type = "RunOnce" }
            @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"; Scope = "Machine"; Type = "Shell Folders" }
            @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"; Scope = "Machine"; Type = "Shell Folders" }
            @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"; Scope = "User"; Type = "Shell Folders" }
            @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"; Scope = "User"; Type = "Shell Folders" }
            @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"; Scope = "Machine"; Type = "Policy Run" }
            @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"; Scope = "User"; Type = "Policy Run" }
            @{Path = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components"; Scope = "Machine"; Type = "Active Setup" }
        )

        # Startup folder locations
        $startupFolders = @(
            @{Path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"; Scope = "All Users" }
            @{Path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"; Scope = "Current User" }
        )
    }

    process {
        try {
            $autoRunResults = @()

            # Collect Registry Run Keys
            Write-Verbose "Retrieving autorun entries from registry"
            foreach ($regPath in $registryPaths) {
                if (Test-Path $regPath.Path) {
                    try {
                        $regItems = Get-ItemProperty -Path $regPath.Path -ErrorAction SilentlyContinue
                        if ($regItems) {
                            $regItems.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
                                Write-Verbose "Found registry entry: $($_.Name) in $($regPath.Path)"

                                $autoRunResults += [PSCustomObject]@{
                                    Name         = $_.Name
                                    Command      = $_.Value
                                    Location     = "Registry"
                                    RegistryPath = $regPath.Path
                                    Scope        = $regPath.Scope
                                    Type         = $regPath.Type
                                    Category     = "Registry"
                                }
                            }
                        }
                    } catch {
                        Write-Warning "Unable to access registry path: $($regPath.Path) - $($_.Exception.Message)"
                    }
                }
            }

            # Collect Startup Folder Items
            Write-Verbose "Retrieving autorun entries from startup folders"
            foreach ($folder in $startupFolders) {
                if (Test-Path $folder.Path) {
                    try {
                        $startupItems = Get-ChildItem -Path $folder.Path -File -ErrorAction SilentlyContinue
                        foreach ($item in $startupItems) {
                            Write-Verbose "Found startup item: $($item.Name) in $($folder.Path)"

                            # For shortcuts, try to resolve target
                            $command = ""
                            if ($item.Extension -eq ".lnk") {
                                try {
                                    $shell = New-Object -ComObject WScript.Shell
                                    $shortcut = $shell.CreateShortcut($item.FullName)
                                    $targetPath = $shortcut.TargetPath
                                    $arguments = $shortcut.Arguments
                                    $command = if ($arguments) { "$targetPath $arguments" } else { $targetPath }
                                } catch {
                                    $command = $item.FullName
                                }
                            } else {
                                $command = $item.FullName
                            }

                            $autoRunResults += [PSCustomObject]@{
                                Name         = $item.Name
                                Command      = $command
                                Location     = "Startup Folder"
                                RegistryPath = ""
                                Scope        = $folder.Scope
                                Type         = "Startup Folder"
                                Category     = "Startup Folder"
                            }
                        }
                    } catch {
                        Write-Warning "Unable to access startup folder: $($folder.Path) - $($_.Exception.Message)"
                    }
                }
            }

            # Collect Scheduled Tasks (if enabled)
            if ($IncludeScheduledTasks) {
                Write-Verbose "Retrieving scheduled tasks configured for startup/logon"
                try {
                    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
                        $_.State -eq 'Ready' -and (
                            $_.Triggers.CimClass.CimClassName -match 'MSFT_TaskBootTrigger|MSFT_TaskLogonTrigger'
                        )
                    }

                    foreach ($task in $tasks) {
                        # Determine scope based on trigger type
                        $trigger = $task.Triggers | Where-Object {
                            $_.CimClass.CimClassName -match 'MSFT_TaskBootTrigger|MSFT_TaskLogonTrigger'
                        } | Select-Object -First 1

                        $triggerType = $trigger.CimClass.CimClassName -replace 'MSFT_Task', '' -replace 'Trigger', ''

                        # Boot triggers are Machine scope, Logon triggers are User scope
                        $taskScope = if ($trigger.CimClass.CimClassName -eq 'MSFT_TaskBootTrigger') {
                            "Machine"
                        } else {
                            "User"
                        }

                        Write-Verbose "Found scheduled task: $($task.TaskName) - Scope: $taskScope, Trigger: $triggerType"

                        $action = $task.Actions | Select-Object -First 1
                        $command = if ($action.Execute) {
                            if ($action.Arguments) {
                                "$($action.Execute) $($action.Arguments)"
                            } else {
                                $action.Execute
                            }
                        } else {
                            ""
                        }

                        $autoRunResults += [PSCustomObject]@{
                            Name         = $task.TaskName
                            Command      = $command
                            Location     = "Scheduled Task"
                            RegistryPath = $task.TaskPath
                            Scope        = $taskScope
                            Type         = "Scheduled Task ($triggerType)"
                            Category     = "Scheduled Task"
                        }
                    }
                } catch {
                    Write-Warning "Unable to retrieve scheduled tasks: $($_.Exception.Message)"
                }
            }

            # Collect Windows Services (if enabled)
            if ($IncludeServices) {
                Write-Verbose "Retrieving Windows services set to automatic start"
                try {
                    $services = Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto' OR StartMode='Automatic'" -ErrorAction SilentlyContinue

                    foreach ($service in $services) {
                        Write-Verbose "Found service: $($service.Name)"

                        $autoRunResults += [PSCustomObject]@{
                            Name         = $service.Name
                            Command      = $service.PathName
                            Location     = "Service"
                            RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$($service.Name)"
                            Scope        = "Machine"
                            Type         = "Service ($($service.StartMode))"
                            Category     = "Service"
                        }
                    }
                } catch {
                    Write-Warning "Unable to retrieve services: $($_.Exception.Message)"
                }
            }

            # Collect Winlogon entries
            Write-Verbose "Retrieving Winlogon autorun entries"
            try {
                $winlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
                if (Test-Path $winlogonPath) {
                    $winlogon = Get-ItemProperty -Path $winlogonPath -ErrorAction SilentlyContinue

                    # Check critical Winlogon values
                    $winlogonValues = @('Userinit', 'Shell', 'VmApplet', 'AppSetup', 'System')
                    foreach ($valueName in $winlogonValues) {
                        if ($winlogon.PSObject.Properties.Name -contains $valueName) {
                            $value = $winlogon.$valueName
                            if (-not [string]::IsNullOrWhiteSpace($value)) {
                                Write-Verbose "Found Winlogon entry: $valueName = $value"

                                $autoRunResults += [PSCustomObject]@{
                                    Name         = $valueName
                                    Command      = $value
                                    Location     = "Registry"
                                    RegistryPath = $winlogonPath
                                    Scope        = "Machine"
                                    Type         = "Winlogon"
                                    Category     = "Registry"
                                }
                            }
                        }
                    }
                }
            } catch {
                Write-Warning "Unable to retrieve Winlogon entries: $($_.Exception.Message)"
            }

            # Collect BootExecute entries
            Write-Verbose "Retrieving BootExecute entries"
            try {
                $sessionManagerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
                if (Test-Path $sessionManagerPath) {
                    $sessionManager = Get-ItemProperty -Path $sessionManagerPath -ErrorAction SilentlyContinue

                    if ($sessionManager.PSObject.Properties.Name -contains 'BootExecute') {
                        $bootExecute = $sessionManager.BootExecute
                        if ($bootExecute) {
                            # BootExecute can be a string or array
                            $bootExecuteArray = if ($bootExecute -is [array]) { $bootExecute } else { @($bootExecute) }

                            foreach ($item in $bootExecuteArray) {
                                if (-not [string]::IsNullOrWhiteSpace($item)) {
                                    Write-Verbose "Found BootExecute entry: $item"

                                    $autoRunResults += [PSCustomObject]@{
                                        Name         = "BootExecute"
                                        Command      = $item
                                        Location     = "Registry"
                                        RegistryPath = $sessionManagerPath
                                        Scope        = "Machine"
                                        Type         = "BootExecute"
                                        Category     = "Registry"
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                Write-Warning "Unable to retrieve BootExecute entries: $($_.Exception.Message)"
            }

            # Collect GPO Startup/Shutdown Scripts
            Write-Verbose "Retrieving Group Policy startup and shutdown scripts"
            try {
                # Machine startup scripts
                $machineScriptsPath = "$env:SystemRoot\System32\GroupPolicy\Machine\Scripts\Startup"
                if (Test-Path $machineScriptsPath) {
                    $scriptFiles = Get-ChildItem -Path $machineScriptsPath -File -ErrorAction SilentlyContinue
                    foreach ($script in $scriptFiles) {
                        Write-Verbose "Found GPO machine startup script: $($script.Name)"

                        $autoRunResults += [PSCustomObject]@{
                            Name         = $script.Name
                            Command      = $script.FullName
                            Location     = "GPO Script"
                            RegistryPath = $machineScriptsPath
                            Scope        = "Machine"
                            Type         = "GPO Startup Script"
                            Category     = "GPO Script"
                        }
                    }
                }

                # Machine shutdown scripts
                $machineShutdownPath = "$env:SystemRoot\System32\GroupPolicy\Machine\Scripts\Shutdown"
                if (Test-Path $machineShutdownPath) {
                    $scriptFiles = Get-ChildItem -Path $machineShutdownPath -File -ErrorAction SilentlyContinue
                    foreach ($script in $scriptFiles) {
                        Write-Verbose "Found GPO machine shutdown script: $($script.Name)"

                        $autoRunResults += [PSCustomObject]@{
                            Name         = $script.Name
                            Command      = $script.FullName
                            Location     = "GPO Script"
                            RegistryPath = $machineShutdownPath
                            Scope        = "Machine"
                            Type         = "GPO Shutdown Script"
                            Category     = "GPO Script"
                        }
                    }
                }

                # User logon scripts
                $userScriptsPath = "$env:SystemRoot\System32\GroupPolicy\User\Scripts\Logon"
                if (Test-Path $userScriptsPath) {
                    $scriptFiles = Get-ChildItem -Path $userScriptsPath -File -ErrorAction SilentlyContinue
                    foreach ($script in $scriptFiles) {
                        Write-Verbose "Found GPO user logon script: $($script.Name)"

                        $autoRunResults += [PSCustomObject]@{
                            Name         = $script.Name
                            Command      = $script.FullName
                            Location     = "GPO Script"
                            RegistryPath = $userScriptsPath
                            Scope        = "User"
                            Type         = "GPO Logon Script"
                            Category     = "GPO Script"
                        }
                    }
                }

                # User logoff scripts
                $userLogoffPath = "$env:SystemRoot\System32\GroupPolicy\User\Scripts\Logoff"
                if (Test-Path $userLogoffPath) {
                    $scriptFiles = Get-ChildItem -Path $userLogoffPath -File -ErrorAction SilentlyContinue
                    foreach ($script in $scriptFiles) {
                        Write-Verbose "Found GPO user logoff script: $($script.Name)"

                        $autoRunResults += [PSCustomObject]@{
                            Name         = $script.Name
                            Command      = $script.FullName
                            Location     = "GPO Script"
                            RegistryPath = $userLogoffPath
                            Scope        = "User"
                            Type         = "GPO Logoff Script"
                            Category     = "GPO Script"
                        }
                    }
                }
            } catch {
                Write-Warning "Unable to retrieve GPO scripts: $($_.Exception.Message)"
            }

            # Return results
            Write-Verbose "AutoRun overview collection completed. Found $($autoRunResults.Count) entries."
            return $autoRunResults

        } catch {
            Write-Error "An error occurred during autorun overview collection: $($_.Exception.Message)"
            throw
        }
    }

    end {
        Write-Verbose "Completed $($MyInvocation.MyCommand)"
    }
}

# SIG # Begin signature block
# MIImdwYJKoZIhvcNAQcCoIImaDCCJmQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDZvM5jEqvg2b1v
# 5YOYrfjUlhUws6vvy88Ik5WRmonWW6CCIAowggYUMIID/KADAgECAhB6I67aU2mW
# D5HIPlz0x+M/MA0GCSqGSIb3DQEBDAUAMFcxCzAJBgNVBAYTAkdCMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxLjAsBgNVBAMTJVNlY3RpZ28gUHVibGljIFRpbWUg
# U3RhbXBpbmcgUm9vdCBSNDYwHhcNMjEwMzIyMDAwMDAwWhcNMzYwMzIxMjM1OTU5
# WjBVMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSwwKgYD
# VQQDEyNTZWN0aWdvIFB1YmxpYyBUaW1lIFN0YW1waW5nIENBIFIzNjCCAaIwDQYJ
# KoZIhvcNAQEBBQADggGPADCCAYoCggGBAM2Y2ENBq26CK+z2M34mNOSJjNPvIhKA
# VD7vJq+MDoGD46IiM+b83+3ecLvBhStSVjeYXIjfa3ajoW3cS3ElcJzkyZlBnwDE
# JuHlzpbN4kMH2qRBVrjrGJgSlzzUqcGQBaCxpectRGhhnOSwcjPMI3G0hedv2eNm
# GiUbD12OeORN0ADzdpsQ4dDi6M4YhoGE9cbY11XxM2AVZn0GiOUC9+XE0wI7CQKf
# OUfigLDn7i/WeyxZ43XLj5GVo7LDBExSLnh+va8WxTlA+uBvq1KO8RSHUQLgzb1g
# bL9Ihgzxmkdp2ZWNuLc+XyEmJNbD2OIIq/fWlwBp6KNL19zpHsODLIsgZ+WZ1AzC
# s1HEK6VWrxmnKyJJg2Lv23DlEdZlQSGdF+z+Gyn9/CRezKe7WNyxRf4e4bwUtrYE
# 2F5Q+05yDD68clwnweckKtxRaF0VzN/w76kOLIaFVhf5sMM/caEZLtOYqYadtn03
# 4ykSFaZuIBU9uCSrKRKTPJhWvXk4CllgrwIDAQABo4IBXDCCAVgwHwYDVR0jBBgw
# FoAU9ndq3T/9ARP/FqFsggIv0Ao9FCUwHQYDVR0OBBYEFF9Y7UwxeqJhQo1SgLqz
# YZcZojKbMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEAMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMIMBEGA1UdIAQKMAgwBgYEVR0gADBMBgNVHR8ERTBDMEGg
# P6A9hjtodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNUaW1lU3Rh
# bXBpbmdSb290UjQ2LmNybDB8BggrBgEFBQcBAQRwMG4wRwYIKwYBBQUHMAKGO2h0
# dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1B1YmxpY1RpbWVTdGFtcGluZ1Jv
# b3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTAN
# BgkqhkiG9w0BAQwFAAOCAgEAEtd7IK0ONVgMnoEdJVj9TC1ndK/HYiYh9lVUacah
# RoZ2W2hfiEOyQExnHk1jkvpIJzAMxmEc6ZvIyHI5UkPCbXKspioYMdbOnBWQUn73
# 3qMooBfIghpR/klUqNxx6/fDXqY0hSU1OSkkSivt51UlmJElUICZYBodzD3M/SFj
# eCP59anwxs6hwj1mfvzG+b1coYGnqsSz2wSKr+nDO+Db8qNcTbJZRAiSazr7KyUJ
# Go1c+MScGfG5QHV+bps8BX5Oyv9Ct36Y4Il6ajTqV2ifikkVtB3RNBUgwu/mSiSU
# ice/Jp/q8BMk/gN8+0rNIE+QqU63JoVMCMPY2752LmESsRVVoypJVt8/N3qQ1c6F
# ibbcRabo3azZkcIdWGVSAdoLgAIxEKBeNh9AQO1gQrnh1TA8ldXuJzPSuALOz1Uj
# b0PCyNVkWk7hkhVHfcvBfI8NtgWQupiaAeNHe0pWSGH2opXZYKYG4Lbukg7HpNi/
# KqJhue2Keak6qH9A8CeEOB7Eob0Zf+fU+CCQaL0cJqlmnx9HCDxF+3BLbUufrV64
# EbTI40zqegPZdA+sXCmbcZy6okx/SjwsusWRItFA3DE8MORZeFb6BmzBtqKJ7l93
# 9bbKBy2jvxcJI98Va95Q5JnlKor3m0E7xpMeYRriWklUPsetMSf2NvUQa/E5vVye
# fQIwggZFMIIELaADAgECAhAIMk+dt9qRb2Pk8qM8Xl1RMA0GCSqGSIb3DQEBCwUA
# MFYxCzAJBgNVBAYTAlBMMSEwHwYDVQQKExhBc3NlY28gRGF0YSBTeXN0ZW1zIFMu
# QS4xJDAiBgNVBAMTG0NlcnR1bSBDb2RlIFNpZ25pbmcgMjAyMSBDQTAeFw0yNDA0
# MDQxNDA0MjRaFw0yNzA0MDQxNDA0MjNaMGsxCzAJBgNVBAYTAk5MMRIwEAYDVQQH
# DAlTY2hpam5kZWwxIzAhBgNVBAoMGkpvaG4gQmlsbGVrZW5zIENvbnN1bHRhbmN5
# MSMwIQYDVQQDDBpKb2huIEJpbGxla2VucyBDb25zdWx0YW5jeTCCAaIwDQYJKoZI
# hvcNAQEBBQADggGPADCCAYoCggGBAMslntDbSQwHZXwFhmibivbnd0Qfn6sqe/6f
# os3pKzKxEsR907RkDMet2x6RRg3eJkiIr3TFPwqBooyXXgK3zxxpyhGOcuIqyM9J
# 28DVf4kUyZHsjGO/8HFjrr3K1hABNUszP0o7H3o6J31eqV1UmCXYhQlNoW9FOmRC
# 1amlquBmh7w4EKYEytqdmdOBavAD5Xq4vLPxNP6kyA+B2YTtk/xM27TghtbwFGKn
# u9Vwnm7dFcpLxans4ONt2OxDQOMA5NwgcUv/YTpjhq9qoz6ivG55NRJGNvUXsM3w
# 2o7dR6Xh4MuEGrTSrOWGg2A5EcLH1XqQtkF5cZnAPM8W/9HUp8ggornWnFVQ9/6M
# ga+ermy5wy5XrmQpN+x3u6tit7xlHk1Hc+4XY4a4ie3BPXG2PhJhmZAn4ebNSBwN
# Hh8z7WTT9X9OFERepGSytZVeEP7hgyptSLcuhpwWeR4QdBb7dV++4p3PsAUQVHFp
# wkSbrRTv4EiJ0Lcz9P1HPGFoHiFAQQIDAQABo4IBeDCCAXQwDAYDVR0TAQH/BAIw
# ADA9BgNVHR8ENjA0MDKgMKAuhixodHRwOi8vY2NzY2EyMDIxLmNybC5jZXJ0dW0u
# cGwvY2NzY2EyMDIxLmNybDBzBggrBgEFBQcBAQRnMGUwLAYIKwYBBQUHMAGGIGh0
# dHA6Ly9jY3NjYTIwMjEub2NzcC1jZXJ0dW0uY29tMDUGCCsGAQUFBzAChilodHRw
# Oi8vcmVwb3NpdG9yeS5jZXJ0dW0ucGwvY2NzY2EyMDIxLmNlcjAfBgNVHSMEGDAW
# gBTddF1MANt7n6B0yrFu9zzAMsBwzTAdBgNVHQ4EFgQUO6KtBpOBgmrlANVAnyiQ
# C6W6lJwwSwYDVR0gBEQwQjAIBgZngQwBBAEwNgYLKoRoAYb2dwIFAQQwJzAlBggr
# BgEFBQcCARYZaHR0cHM6Ly93d3cuY2VydHVtLnBsL0NQUzATBgNVHSUEDDAKBggr
# BgEFBQcDAzAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAEQsN8wg
# PMdWVkwHPPTN+jKpdns5AKVFjcn00psf2NGVVgWWNQBIQc9lEuTBWb54IK6Ga3hx
# QRZfnPNo5HGl73YLmFgdFQrFzZ1lnaMdIcyh8LTWv6+XNWfoyCM9wCp4zMIDPOs8
# LKSMQqA/wRgqiACWnOS4a6fyd5GUIAm4CuaptpFYr90l4Dn/wAdXOdY32UhgzmSu
# xpUbhD8gVJUaBNVmQaRqeU8y49MxiVrUKJXde1BCrtR9awXbqembc7Nqvmi60tYK
# lD27hlpKtj6eGPjkht0hHEsgzU0Fxw7ZJghYG2wXfpF2ziN893ak9Mi/1dmCNmor
# GOnybKYfT6ff6YTCDDNkod4egcMZdOSv+/Qv+HAeIgEvrxE9QsGlzTwbRtbm6gwY
# YcVBs/SsVUdBn/TSB35MMxRhHE5iC3aUTkDbceo/XP3uFhVL4g2JZHpFfCSu2TQr
# rzRn2sn07jfMvzeHArCOJgBW1gPqR3WrJ4hUxL06Rbg1gs9tU5HGGz9KNQMfQFQ7
# 0Wz7UIhezGcFcRfkIfSkMmQYYpsc7rfzj+z0ThfDVzzJr2dMOFsMlfj1T6l22GBq
# 9XQx0A4lcc5Fl9pRxbOuHHWFqIBD/BCEhwniOCySzqENd2N+oz8znKooSISStnkN
# aYXt6xblJF2dx9Dn89FK7d1IquNxOwt0tI5dMIIGYjCCBMqgAwIBAgIRAKQpO24e
# 3denNAiHrXpOtyQwDQYJKoZIhvcNAQEMBQAwVTELMAkGA1UEBhMCR0IxGDAWBgNV
# BAoTD1NlY3RpZ28gTGltaXRlZDEsMCoGA1UEAxMjU2VjdGlnbyBQdWJsaWMgVGlt
# ZSBTdGFtcGluZyBDQSBSMzYwHhcNMjUwMzI3MDAwMDAwWhcNMzYwMzIxMjM1OTU5
# WjByMQswCQYDVQQGEwJHQjEXMBUGA1UECBMOV2VzdCBZb3Jrc2hpcmUxGDAWBgNV
# BAoTD1NlY3RpZ28gTGltaXRlZDEwMC4GA1UEAxMnU2VjdGlnbyBQdWJsaWMgVGlt
# ZSBTdGFtcGluZyBTaWduZXIgUjM2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEA04SV9G6kU3jyPRBLeBIHPNyUgVNnYayfsGOyYEXrn3+SkDYTLs1crcw/
# ol2swE1TzB2aR/5JIjKNf75QBha2Ddj+4NEPKDxHEd4dEn7RTWMcTIfm492TW22I
# 8LfH+A7Ehz0/safc6BbsNBzjHTt7FngNfhfJoYOrkugSaT8F0IzUh6VUwoHdYDpi
# ln9dh0n0m545d5A5tJD92iFAIbKHQWGbCQNYplqpAFasHBn77OqW37P9BhOASdmj
# p3IijYiFdcA0WQIe60vzvrk0HG+iVcwVZjz+t5OcXGTcxqOAzk1frDNZ1aw8nFhG
# EvG0ktJQknnJZE3D40GofV7O8WzgaAnZmoUn4PCpvH36vD4XaAF2CjiPsJWiY/j2
# xLsJuqx3JtuI4akH0MmGzlBUylhXvdNVXcjAuIEcEQKtOBR9lU4wXQpISrbOT8ux
# +96GzBq8TdbhoFcmYaOBZKlwPP7pOp5Mzx/UMhyBA93PQhiCdPfIVOCINsUY4U23
# p4KJ3F1HqP3H6Slw3lHACnLilGETXRg5X/Fp8G8qlG5Y+M49ZEGUp2bneRLZoyHT
# yynHvFISpefhBCV0KdRZHPcuSL5OAGWnBjAlRtHvsMBrI3AAA0Tu1oGvPa/4yeei
# Ayu+9y3SLC98gDVbySnXnkujjhIh+oaatsk/oyf5R2vcxHahajMCAwEAAaOCAY4w
# ggGKMB8GA1UdIwQYMBaAFF9Y7UwxeqJhQo1SgLqzYZcZojKbMB0GA1UdDgQWBBSI
# YYyhKjdkgShgoZsx0Iz9LALOTzAOBgNVHQ8BAf8EBAMCBsAwDAYDVR0TAQH/BAIw
# ADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDBKBgNVHSAEQzBBMDUGDCsGAQQBsjEB
# AgEDCDAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzAIBgZn
# gQwBBAIwSgYDVR0fBEMwQTA/oD2gO4Y5aHR0cDovL2NybC5zZWN0aWdvLmNvbS9T
# ZWN0aWdvUHVibGljVGltZVN0YW1waW5nQ0FSMzYuY3JsMHoGCCsGAQUFBwEBBG4w
# bDBFBggrBgEFBQcwAoY5aHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVi
# bGljVGltZVN0YW1waW5nQ0FSMzYuY3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2Nz
# cC5zZWN0aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAYEAAoE+pIZyUSH5ZakuPVKK
# 4eWbzEsTRJOEjbIu6r7vmzXXLpJx4FyGmcqnFZoa1dzx3JrUCrdG5b//LfAxOGy9
# Ph9JtrYChJaVHrusDh9NgYwiGDOhyyJ2zRy3+kdqhwtUlLCdNjFjakTSE+hkC9F5
# ty1uxOoQ2ZkfI5WM4WXA3ZHcNHB4V42zi7Jk3ktEnkSdViVxM6rduXW0jmmiu71Z
# pBFZDh7Kdens+PQXPgMqvzodgQJEkxaION5XRCoBxAwWwiMm2thPDuZTzWp/gUFz
# i7izCmEt4pE3Kf0MOt3ccgwn4Kl2FIcQaV55nkjv1gODcHcD9+ZVjYZoyKTVWb4V
# qMQy/j8Q3aaYd/jOQ66Fhk3NWbg2tYl5jhQCuIsE55Vg4N0DUbEWvXJxtxQQaVR5
# xzhEI+BjJKzh3TQ026JxHhr2fuJ0mV68AluFr9qshgwS5SpN5FFtaSEnAwqZv3IS
# +mlG50rK7W3qXbWwi4hmpylUfygtYLEdLQukNEX1jiOKMIIGgjCCBGqgAwIBAgIQ
# NsKwvXwbOuejs902y8l1aDANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYD
# VQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBS
# U0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMjEwMzIyMDAwMDAwWhcNMzgw
# MTE4MjM1OTU5WjBXMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1p
# dGVkMS4wLAYDVQQDEyVTZWN0aWdvIFB1YmxpYyBUaW1lIFN0YW1waW5nIFJvb3Qg
# UjQ2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAiJ3YuUVnnR3d6Lkm
# gZpUVMB8SQWbzFoVD9mUEES0QUCBdxSZqdTkdizICFNeINCSJS+lV1ipnW5ihkQy
# C0cRLWXUJzodqpnMRs46npiJPHrfLBOifjfhpdXJ2aHHsPHggGsCi7uE0awqKggE
# /LkYw3sqaBia67h/3awoqNvGqiFRJ+OTWYmUCO2GAXsePHi+/JUNAax3kpqstbl3
# vcTdOGhtKShvZIvjwulRH87rbukNyHGWX5tNK/WABKf+Gnoi4cmisS7oSimgHUI0
# Wn/4elNd40BFdSZ1EwpuddZ+Wr7+Dfo0lcHflm/FDDrOJ3rWqauUP8hsokDoI7D/
# yUVI9DAE/WK3Jl3C4LKwIpn1mNzMyptRwsXKrop06m7NUNHdlTDEMovXAIDGAvYy
# nPt5lutv8lZeI5w3MOlCybAZDpK3Dy1MKo+6aEtE9vtiTMzz/o2dYfdP0KWZwZIX
# bYsTIlg1YIetCpi5s14qiXOpRsKqFKqav9R1R5vj3NgevsAsvxsAnI8Oa5s2oy25
# qhsoBIGo/zi6GpxFj+mOdh35Xn91y72J4RGOJEoqzEIbW3q0b2iPuWLA911cRxgY
# 5SJYubvjay3nSMbBPPFsyl6mY4/WYucmyS9lo3l7jk27MAe145GWxK4O3m3gEFEI
# kv7kRmefDR7Oe2T1HxAnICQvr9sCAwEAAaOCARYwggESMB8GA1UdIwQYMBaAFFN5
# v1qqK0rPVIDh2JvAnfKyA2bLMB0GA1UdDgQWBBT2d2rdP/0BE/8WoWyCAi/QCj0U
# JTAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zATBgNVHSUEDDAKBggr
# BgEFBQcDCDARBgNVHSAECjAIMAYGBFUdIAAwUAYDVR0fBEkwRzBFoEOgQYY/aHR0
# cDovL2NybC51c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJTQUNlcnRpZmljYXRpb25B
# dXRob3JpdHkuY3JsMDUGCCsGAQUFBwEBBCkwJzAlBggrBgEFBQcwAYYZaHR0cDov
# L29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEADr5lQe1oRLjl
# ocXUEYfktzsljOt+2sgXke3Y8UPEooU5y39rAARaAdAxUeiX1ktLJ3+lgxtoLQhn
# 5cFb3GF2SSZRX8ptQ6IvuD3wz/LNHKpQ5nX8hjsDLRhsyeIiJsms9yAWnvdYOdEM
# q1W61KE9JlBkB20XBee6JaXx4UBErc+YuoSb1SxVf7nkNtUjPfcxuFtrQdRMRi/f
# InV/AobE8Gw/8yBMQKKaHt5eia8ybT8Y/Ffa6HAJyz9gvEOcF1VWXG8OMeM7Vy7B
# s6mSIkYeYtddU1ux1dQLbEGur18ut97wgGwDiGinCwKPyFO7ApcmVJOtlw9FVJxw
# /mL1TbyBns4zOgkaXFnnfzg4qbSvnrwyj1NiurMp4pmAWjR+Pb/SIduPnmFzbSN/
# G8reZCL4fvGlvPFk4Uab/JVCSmj59+/mB2Gn6G/UYOy8k60mKcmaAZsEVkhOFuoj
# 4we8CYyaR9vd9PGZKSinaZIkvVjbH/3nlLb0a7SBIkiRzfPfS9T+JesylbHa1LtR
# V9U/7m0q7Ma2CQ/t392ioOssXW7oKLdOmMBl14suVFBmbzrt5V5cQPnwtd3UOTpS
# 9oCG+ZZheiIvPgkDmA8FzPsnfXW5qHELB43ET7HHFHeRPRYrMBKjkb8/IN7Po0d0
# hQoF4TeMM+zYAJzoKQnVKOLg8pZVPT8wgga5MIIEoaADAgECAhEAmaOACiZVO2Wr
# 3G6EprPqOTANBgkqhkiG9w0BAQwFADCBgDELMAkGA1UEBhMCUEwxIjAgBgNVBAoT
# GVVuaXpldG8gVGVjaG5vbG9naWVzIFMuQS4xJzAlBgNVBAsTHkNlcnR1bSBDZXJ0
# aWZpY2F0aW9uIEF1dGhvcml0eTEkMCIGA1UEAxMbQ2VydHVtIFRydXN0ZWQgTmV0
# d29yayBDQSAyMB4XDTIxMDUxOTA1MzIxOFoXDTM2MDUxODA1MzIxOFowVjELMAkG
# A1UEBhMCUEwxITAfBgNVBAoTGEFzc2VjbyBEYXRhIFN5c3RlbXMgUy5BLjEkMCIG
# A1UEAxMbQ2VydHVtIENvZGUgU2lnbmluZyAyMDIxIENBMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEAnSPPBDAjO8FGLOczcz5jXXp1ur5cTbq96y34vuTm
# flN4mSAfgLKTvggv24/rWiVGzGxT9YEASVMw1Aj8ewTS4IndU8s7VS5+djSoMcbv
# IKck6+hI1shsylP4JyLvmxwLHtSworV9wmjhNd627h27a8RdrT1PH9ud0IF+njvM
# k2xqbNTIPsnWtw3E7DmDoUmDQiYi/ucJ42fcHqBkbbxYDB7SYOouu9Tj1yHIohzu
# C8KNqfcYf7Z4/iZgkBJ+UFNDcc6zokZ2uJIxWgPWXMEmhu1gMXgv8aGUsRdaCtVD
# 2bSlbfsq7BiqljjaCun+RJgTgFRCtsuAEw0pG9+FA+yQN9n/kZtMLK+Wo837Q4QO
# ZgYqVWQ4x6cM7/G0yswg1ElLlJj6NYKLw9EcBXE7TF3HybZtYvj9lDV2nT8mFSkc
# SkAExzd4prHwYjUXTeZIlVXqj+eaYqoMTpMrfh5MCAOIG5knN4Q/JHuurfTI5XDY
# O962WZayx7ACFf5ydJpoEowSP07YaBiQ8nXpDkNrUA9g7qf/rCkKbWpQ5boufUnq
# 1UiYPIAHlezf4muJqxqIns/kqld6JVX8cixbd6PzkDpwZo4SlADaCi2JSplKShBS
# ND36E/ENVv8urPS0yOnpG4tIoBGxVCARPCg1BnyMJ4rBJAcOSnAWd18Jx5n858JS
# qPECAwEAAaOCAVUwggFRMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFN10XUwA
# 23ufoHTKsW73PMAywHDNMB8GA1UdIwQYMBaAFLahVDkCw6A/joq8+tT4HKbROg79
# MA4GA1UdDwEB/wQEAwIBBjATBgNVHSUEDDAKBggrBgEFBQcDAzAwBgNVHR8EKTAn
# MCWgI6Ahhh9odHRwOi8vY3JsLmNlcnR1bS5wbC9jdG5jYTIuY3JsMGwGCCsGAQUF
# BwEBBGAwXjAoBggrBgEFBQcwAYYcaHR0cDovL3N1YmNhLm9jc3AtY2VydHVtLmNv
# bTAyBggrBgEFBQcwAoYmaHR0cDovL3JlcG9zaXRvcnkuY2VydHVtLnBsL2N0bmNh
# Mi5jZXIwOQYDVR0gBDIwMDAuBgRVHSAAMCYwJAYIKwYBBQUHAgEWGGh0dHA6Ly93
# d3cuY2VydHVtLnBsL0NQUzANBgkqhkiG9w0BAQwFAAOCAgEAdYhYD+WPUCiaU58Q
# 7EP89DttyZqGYn2XRDhJkL6P+/T0IPZyxfxiXumYlARMgwRzLRUStJl490L94C9L
# GF3vjzzH8Jq3iR74BRlkO18J3zIdmCKQa5LyZ48IfICJTZVJeChDUyuQy6rGDxLU
# UAsO0eqeLNhLVsgw6/zOfImNlARKn1FP7o0fTbj8ipNGxHBIutiRsWrhWM2f8pXd
# d3x2mbJCKKtl2s42g9KUJHEIiLni9ByoqIUul4GblLQigO0ugh7bWRLDm0CdY9rN
# LqyA3ahe8WlxVWkxyrQLjH8ItI17RdySaYayX3PhRSC4Am1/7mATwZWwSD+B7eMc
# ZNhpn8zJ+6MTyE6YoEBSRVrs0zFFIHUR08Wk0ikSf+lIe5Iv6RY3/bFAEloMU+vU
# BfSouCReZwSLo8WdrDlPXtR0gicDnytO7eZ5827NS2x7gCBibESYkOh1/w1tVxTp
# V2Na3PR7nxYVlPu1JPoRZCbH86gc96UTvuWiOruWmyOEMLOGGniR+x+zPF/2DaGg
# K2W1eEJfo2qyrBNPvF7wuAyQfiFXLwvWHamoYtPZo0LHuH8X3n9C+xN4YaNjt2yw
# zOr+tKyEVAotnyU9vyEVOaIYMk3IeBrmFnn0gbKeTTyYeEEUz/Qwt4HOUBCrW602
# NCmvO1nm+/80nLy5r0AZvCQxaQ4xggXDMIIFvwIBATBqMFYxCzAJBgNVBAYTAlBM
# MSEwHwYDVQQKExhBc3NlY28gRGF0YSBTeXN0ZW1zIFMuQS4xJDAiBgNVBAMTG0Nl
# cnR1bSBDb2RlIFNpZ25pbmcgMjAyMSBDQQIQCDJPnbfakW9j5PKjPF5dUTANBglg
# hkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3
# DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEV
# MC8GCSqGSIb3DQEJBDEiBCAJ7WNMdIQh3YxOAVRff+Ft1dQDxn8zw40RwWp702uu
# qjANBgkqhkiG9w0BAQEFAASCAYC0UPw2nJGrSIejyXC6HHEkM6H/klvaLd6D844i
# f+9nL//gxHwwPR1eOIynzpNV9i2zAYKLbf8Ve3bOSLw5V4XeL46rX6zCBCLxHdUJ
# Du8bL1PlrhY3Ma0NTz6IdSwgeTd8tz9iWZ3+tF22JUSaXPqS0wN8D+YJNNnMTJaQ
# WaUxjaRvHf96nhUUe7nuLLwV7jsoSpgbMASPZJRezHxyAQxPvbw/dR8v4HnQHOEZ
# 32+twge+mUEaKxSVVf8ZPxpf0z2m6QrQ/GQhhPAiM/zklt0inaEdw3dErPeMv7xX
# gQrt4TyweCh7qffiJ4YxWwGREhkn256GSaEvj1y1cJ+HiTe7PLJNf2T68VV6RrWV
# uv9CPfaHlj0sQMBaoM5VH5hciM5hQS7sYSp0Q7H/S/LpGV54eWvifgZ6sBrorM5H
# IdtJp5s42I3cWurlQBFKslqstYAHe3ox+8/Y+7nyqZ/YrqHOodkCRrxcN+KBfzmo
# 2W3SvS2OOYNDMRVm4dZeAfzuWtChggMjMIIDHwYJKoZIhvcNAQkGMYIDEDCCAwwC
# AQEwajBVMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSww
# KgYDVQQDEyNTZWN0aWdvIFB1YmxpYyBUaW1lIFN0YW1waW5nIENBIFIzNgIRAKQp
# O24e3denNAiHrXpOtyQwDQYJYIZIAWUDBAICBQCgeTAYBgkqhkiG9w0BCQMxCwYJ
# KoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAyMjUwODU4NTdaMD8GCSqGSIb3
# DQEJBDEyBDDFFringZyqIvgUFPohha08DOkHls/mbYKYI1eoZGjUt3yDWk62BMpa
# 7EVJgqrBwBEwDQYJKoZIhvcNAQEBBQAEggIAq/lnaZvfCNOmK+cikqrCGBH6tMuo
# e4CiFwXTpTjiptCm1fYLcby9+ChX/ZBD13Aga/PTYmbdmw8eFlo5cOIb/ozWnSTS
# bdHPqaox0XPxWelmAOsCFIDzK/Yiu/Ltau3ubu3PUASoV4/I6wx6NGBCdLTiUmV7
# uNE3d1KPVQCTY/mLwUolzEd1kUp+tdDtwN3m4MR4FBUzEpMP6XfmZLX6bEuc+XmH
# +c/pVCZSIrNOWwkEdgbR7KKOYcOC1xnL9cZpobbMoGGwEiAr0KksYfM2B5ildj21
# gYgZsUzdzAX4GGqcUfF99rfFX+4j2zSNBH+Ff5JpvXcCwSB6mUS9dDejA8C+apZp
# eVxcCJ3F/46Ygtwvh4NyVttkNYQSejZ9S6E64i7ClMDzjeCtaRX6bBEa1NLM624i
# 7b027WjdnokZ0m8e5oYnXTb8ZJm18BamO2KHvINQQ9ZNJgPqA/m2rhbw3rAx7iUS
# /3e0kpJNtStR0UU5uVU//HQ1QckQhNPv2y0MWSZHwWzA+//5XZfHXZeIhatXnRIJ
# Sf95ugdbJjcOAbw4PtNyPkYoydaWtX7AhhTr2JNJ6bGnGHsKKpg7GfzfQGtDGfmi
# cJVb4C8RhV3R+FFJVvoxUedkzdc50IW4d6qycwwGqpp0h5IYn4LVkU7mdfins4cS
# JOxIo2ziIYNxi7Q=
# SIG # End signature block
