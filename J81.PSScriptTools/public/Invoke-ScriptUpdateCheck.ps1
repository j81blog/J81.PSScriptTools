function Invoke-ScriptUpdateCheck {
    <#
    .SYNOPSIS
        Checks for a new version of the script and optionally performs an update.

    .DESCRIPTION
        This function connects to a GitHub repository to check for new script versions based on a
        specified file. It supports signed scripts via GitHub Releases, dependency checking,
        update throttling, and multiple update channels.

    .PARAMETER CurrentVersion
        The version of the currently running script.

    .PARAMETER AutoUpdate
        A switch to automatically download and apply an available update.

    .PARAMETER RestartAfterUpdate
        A switch to restart the script with its original parameters after a successful update.

    .PARAMETER UpdateChannel
        The update channel to check ('stable' or 'dev').

    .PARAMETER Rollback
        A switch to initiate a rollback to the most recent backup file.

    .PARAMETER NoUpdateCheck
        A switch to bypass the update check.

    .PARAMETER CheckIntervalHours
        The number of hours to wait before checking for an update again.

    .NOTES
        Function Name   : Invoke-ScriptUpdateCheck
        Version         : v2025.815.2205
        Author          : John Billekens

    .LINK
        https://blog.j81.nl
#>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Github')]
    [OutputType([boolean])]
    param(

        [Parameter(Mandatory = $true, ParameterSetName = 'Github')]
        [string]$CurrentVersion,

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [switch]$AutoUpdate,

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [switch]$RestartAfterUpdate,

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [ValidateSet('stable', 'dev')]
        [string]$UpdateChannel = 'stable',

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [switch]$Rollback,

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [switch]$NoUpdateCheck,

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [Alias('ShowDevInfo')]
        [Switch]$ShowDevInfoIfNewerVersion = $false,

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [int]$CheckIntervalHours = 24,

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [String]$GithubRepo = $Global:GithubRepo,

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [String]$GithubOwner = $Global:GithubOwner,

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [ValidateNotNullOrEmpty()]
        [string]$GistId = $Global:GistId,

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [ValidateNotNullOrEmpty()]
        [String]$GistFilename = 'versioninfo.json',

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [Switch]$ForceCheckUpdate,

        [Parameter(Mandatory = $false, ParameterSetName = 'Github')]
        [Switch]$Silent
    )

    #region --- SETUP VARIABLES ---
    $script:Silent = $Silent.IsPresent

    $SourceName = ""
    if ($PSCmdlet.ParameterSetName -eq 'Github') {
        $SourceName = "GitHub"
        if ([String]::IsNullOrEmpty($GithubOwner)) {
            Write-Error -Message "GitHub owner not specified. Please set the `$GithubOwner variable."
            return $false
        }
        if ([String]::IsNullOrEmpty($GithubRepo)) {
            Write-Error -Message "GitHub repository not specified. Please set the `$GithubRepo variable."
            return $false
        }
        if ([String]::IsNullOrEmpty($GistId)) {
            Write-Error -Message "Gist ID not specified. Please set the `$GistId variable."
            return $false
        }
        $jsonUrl = "https://gist.githubusercontent.com/$($GithubOwner)/$($GistId)/raw/$($GistFilename)"
        Write-Verbose -Message "Using Github URL: $($jsonUrl)"
    }

    # Script determines its own context
    $PSCallStack = Get-PSCallStack
    if ($PSCallStack.Count -eq 0) {
        Write-Error -Message "No call stack found. This function must be called from a script or function."
        return $false
    }
    $SourceScriptName = $PSCallStack[0].InvocationInfo.ScriptName
    $pattern = '(?<=\.ps1\s).*?$'
    if ($PSCallStack[-1].InvocationInfo.MyCommand -match $pattern) {
        $SourceParameters = $matches[0]
    } else {
        $SourceParameters = $null
    }
    if (-not $SourceScriptName) {
        Write-Error -Message "No script name found in call stack. This function must be called from a script."
        return $false
    }
    $scriptFullName = Split-Path -Path $SourceScriptName -Leaf
    Write-Verbose -Message "Script full name: $($scriptFullName)"
    $scriptPath = $SourceScriptName
    Write-Verbose -Message "Script path: $($scriptPath)"
    $scriptRoot = Split-Path -Path $scriptPath -Parent
    Write-Verbose -Message "Script root: $($scriptRoot)"
    Write-Verbose -Message "Source parameters: $($SourceParameters | Out-String)"
    #endregion

    #region --- INITIAL CHECKS & MODES (Rollback/NoCheck) ---
    if ($NoUpdateCheck) {
        Write-Verbose -Message "Update check explicitly skipped."
        return $true
    }

    if ($Rollback) {
        Write-Verbose -Message "Rollback mode activated."
        $backupFile = Get-ChildItem -Path $scriptRoot -Filter "$($scriptFullName -replace '\.ps1$', '*.bak')" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
        if (-not $backupFile) {
            Write-Error -Message "No backup file (.bak) found to roll back to."
            return $false
        }
        if ($PSCmdlet.ShouldProcess($scriptFullName, "Rollback to version from '$($backupFile.Name)'")) {
            $brokenScriptPath = "$($scriptPath).broken_$(Get-Date -Format 'yyyyMMddHHmmss')"
            Rename-Item -Path $scriptPath -NewName $brokenScriptPath -Force | Out-Null
            Rename-Item -Path $backupFile.FullName -NewName $scriptFullName -Force | Out-Null
            Write-InformationColored "Rollback successful. Please start the script again." -ForegroundColor Green
        }
        exit
    }
    #endregion

    #region --- THROTTLING ---
    Write-Verbose -Message "Checking if update check is throttled..."
    $lastCheckFile = Join-Path -Path $env:TEMP -ChildPath "$($scriptFullName)_lastupdatecheck.txt"
    if ((Test-Path -Path $lastCheckFile) -and $CheckIntervalHours -gt 0) {
        Write-Verbose -Message "Last update check file found at $($lastCheckFile)."
        try {
            if ($ForceCheckUpdate) {
                Write-Verbose -Message "Forced update check, ignoring last check time."
            } elseif ((Get-Date) -lt ([datetime]::FromFileTimeUtc($(Get-Content -Path $lastCheckFile))).AddHours($CheckIntervalHours)) {
                Write-Verbose -Message "Update check skipped; last check was recent."
                return $true
            }
        } catch {
            Write-Warning -Message "Could not parse last update check time. Checking now."
        }
    }
    #endregion

    #region --- FETCH UPDATE INFO ---
    Write-Verbose -Message "Checking for updates... (Channel: $($UpdateChannel))"
    try {
        $versionInfo = Invoke-RestMethod -Uri $jsonUrl -ErrorAction Stop
        Write-Verbose -Message "Retrieved version information from $($jsonUrl)"
        Set-Content -Path $lastCheckFile -Value ((Get-Date).ToFileTimeUtc())
    } catch {
        Write-Warning -Message "Could not retrieve update information from Gist. Continuing with current version."
        return $true
    }

    $channelData = $versionInfo.channels.$UpdateChannel
    $latestVersionString = $channelData.version
    $currentVersionObj = [System.Version]$CurrentVersion
    $latestVersionObj = [System.Version]$latestVersionString
    $versionDetails = $versionInfo.changelog.$latestVersionString
    $requiredCertificateSubject = $versionDetails.CertificateSubject
    #endregion

    #region --- VERSION & DEPENDENCY CHECK ---
    if ($channelData.forceUpdateBelowVersion -and ($currentVersionObj -lt [System.Version]$channelData.forceUpdateBelowVersion)) {
        Write-Error -Message "CRITICAL: Your script version ($($CurrentVersion)) is outdated. Update to $($latestVersionString) is required. Please run with '-AutoUpdate'."
        return $false
    }

    if ($latestVersionObj -le $currentVersionObj) {
        Write-Verbose -Message "Your script is up-to-date (Latest Version: $($latestVersionString), Script Version: $($CurrentVersion))."
        return $true
    }

    Write-InformationColored "`r`nA new version ($($latestVersionString)) is available for the '$($UpdateChannel)' channel!" -ForegroundColor Yellow

    if ($versionDetails.notes -or $versionDetails.notes.Count -gt 0) {
        Write-InformationColored -Message "`r`nRelease Notes for version $($latestVersionString):" -ForegroundColor Cyan
        $versionDetails.notes | ForEach-Object { Write-InformationColored -Message " => $_" }
    }
    if (($ShowDevInfoIfNewerVersion -or $channelData.showDevInfo) -and [version]$versionInfo.channels.dev.version -gt $latestVersionObj) {
        Write-InformationColored -Message "`r`nIMPORTANT: A newer development version ($($versionInfo.channels.dev.version)) is available in the 'dev' channel." -ForegroundColor Yellow
        Write-InformationColored -Message "Consider switching to the 'dev' channel for the latest features and fixes." -ForegroundColor Yellow
        if ($versionInfo.changelog.$($versionInfo.channels.dev.version).notes -or $versionInfo.changelog.$($versionInfo.channels.dev.version).notes.Count -gt 0) {
            Write-InformationColored -Message "`r`nDevelopment Release Notes for version $($versionInfo.channels.dev.version):" -ForegroundColor Cyan
            $versionInfo.changelog.$($versionInfo.channels.dev.version).notes | ForEach-Object { Write-InformationColored -Message " => $_" }
        }
    }
    #endregion

    #region --- UPDATE EXECUTION ---
    if (-not $AutoUpdate) {
        Write-InformationColored -Message "Run with '-AutoUpdate' to install."
        return $true
    }
    if (-not $PSCmdlet.ShouldProcess($scriptPath, "Update to version $($latestVersionString)")) {
        return $true
    }

    try {
        $releaseApiUrl = "https://api.github.com/repos/$($GithubOwner)/$($GithubRepo)/releases/tags/$($latestVersionString)"
        Write-Verbose -Message "Getting release information from $($releaseApiUrl)"
        try {
            $releaseInfo = Invoke-RestMethod -Uri $releaseApiUrl -ErrorAction Stop
            Write-InformationColored -Message "Successfully retrieved release information from $SourceName." -ForegroundColor Green
        } catch {
            if ($_.ErrorDetails.Message -and ($ErrorDetails = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue)) {
                if ($ErrorDetails.status -eq 404) {
                    Write-Host "Failed to retrieve release information from $SourceName. [$($ErrorDetails.status)] $($ErrorDetails.message), trying again with alternative option..."
                    $releaseApiUrl = "https://api.github.com/repos/$($GithubOwner)/$($GithubRepo)/releases/tags/v$($latestVersionString)"
                    Write-Verbose -Message "Retrying with URL: $($releaseApiUrl)"
                    try {
                        $releaseInfo = Invoke-RestMethod -Uri $releaseApiUrl -ErrorAction Stop
                        Write-InformationColored -Message "Successfully retrieved release information from $SourceName." -ForegroundColor Green
                    } catch {
                        if ($_.ErrorDetails.Message -and ($ErrorDetails = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue)) {
                            Write-Error -Message "Failed to retrieve release information from $SourceName. [$($ErrorDetails.status)] $($ErrorDetails.message)"
                            return $false
                        } else {
                            Write-Error -Message "Failed to retrieve release information from $SourceName. Error: $($_.Exception.Message)"
                            return $false
                        }
                    }
                } else {
                    Write-Error -Message "Failed to retrieve release information from $SourceName. [$($ErrorDetails.status)] $($ErrorDetails.message)"
                    return $false
                }
            }
        }
        Write-Verbose -Message "Release information retrieved successfully."
        $downloadUrl = ($releaseInfo.assets | Where-Object { $_.name -ieq $scriptFullName }).browser_download_url
        if (-not $downloadUrl) { throw "Could not find asset '$($scriptFullName)' in release '$($latestVersionString)'." }

        $tempPath = Join-Path -Path $env:TEMP -ChildPath $scriptFullName
        Write-Verbose -Message "Downloading update from $($downloadUrl)..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -ErrorAction Stop
        if (-not [String]::IsNullOrEmpty($requiredCertificateSubject)) {
            Write-Verbose -Message "Verifying Authenticode signature..."
            $signature = Get-AuthenticodeSignature -FilePath $tempPath
            if ($signature.Status -ne 'Valid') { throw "Signature check failed! Status: $($signature.Status)." }

            # The function uses the $requiredCertificateSubject variable from the parent script scope
            if ($signature.SignerCertificate.Subject -ne $requiredCertificateSubject) { throw "Certificate subject mismatch! Expected '$($requiredCertificateSubject)', but got '$($signature.SignerCertificate.Subject)'." }
            Write-Verbose -Message "Signature valid and matches expected subject."
        } else {
            Write-Verbose -Message "No certificate subject specified for signature verification."
        }
        Unblock-File -Path $tempPath
        $backupPath = "$($scriptPath -replace '\.ps1$', "_v$($CurrentVersion).bak")"
        Write-Verbose -Message "Creating backup of current script at $($backupPath)"
        Rename-Item -Path $scriptPath -NewName $backupPath -Force -ErrorAction Stop
        Write-Verbose -Message "Moving new script to $($scriptPath)"
        Move-Item -Path $tempPath -Destination $scriptPath -Force -ErrorAction Stop
        Write-InformationColored "Script successfully updated to version $($latestVersionString)." -ForegroundColor Green
    } catch {
        Write-Error -Message "Update failed: $($_.Exception.Message)"
        if (Test-Path -Path $backupPath) {
            Move-Item -Path $backupPath -Destination $scriptPath -Force
            Write-InformationColored "Restored previous version." -ForegroundColor Green
        }
        return $false
    }

    if ($RestartAfterUpdate) {
        Write-InformationColored -Message "Restarting script..."
        $currentPSEngine = (Get-Process -Id $PID).Path
        Write-Verbose -Message "Restarting with engine: $($currentPSEngine)"
        Write-Verbose -Message "Script path: $($scriptPath)"
        Write-Verbose -Message "Source parameters: $($SourceParameters -join ' ')"
        Start-Process -FilePath $currentPSEngine -NoNewWindow -Wait -ArgumentList "-NoProfile -Command `"$(&{& "$scriptPath" $SourceParameters})`""
        exit
    } else {
        Write-InformationColored -Message "Please restart the script to apply the update. The current running version is still $($CurrentVersion)." -ForegroundColor Yellow
        Write-InformationColored -Message "If you want to continue with the new version the next time, run the script with '-RestartAfterUpdate'." -ForegroundColor Yellow
    }
    #endregion

    return $true
}
