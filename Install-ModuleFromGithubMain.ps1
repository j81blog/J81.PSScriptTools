$RemoteBranch = "main"
$Uri = 'https://github.com/j81blog/J81.PSScriptTools'
$ModuleName = 'J81.PSScriptTools'

#Requires -Version 5.1

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $InstallPath = [System.IO.Path]::Combine(([Environment]::GetFolderPath('MyDocuments')), 'WindowsPowerShell\Modules')
} elseif ($IsWindows) {
    $InstallPath = [System.IO.Path]::Combine(([Environment]::GetFolderPath('MyDocuments')), 'PowerShell\Modules')
} else {
    $InstallPath = [System.IO.Path]::Combine($env:HOME, '.local/share/powershell/Modules')
}
Write-Verbose "InstallPath: $InstallPath"

$ExecutionPolicy = Get-ExecutionPolicy
if (('PSEdition' -notin $PSVersionTable.Keys -or $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) -and ($ExecutionPolicy -notin 'Unrestricted', 'RemoteSigned', 'Bypass')) {
    Write-Host "Setting process execution policy to RemoteSigned" -ForegroundColor Cyan
    Set-ExecutionPolicy RemoteSigned -Scope Process -Force
} else {
    Write-Host "Current execution policy: $ExecutionPolicy" -ForegroundColor Yellow
}

if (-not (Test-Path -Path $InstallPath)) {
    Write-Host "Creating module path: $InstallPath" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null
}
$ScriptPath = if ($PSScriptRoot) {
    $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent -Path $MyInvocation.MyCommand.Path
} else {
    $null
}
Write-Verbose "ScriptPath: $ScriptPath"

if ([String]::IsNullOrWhiteSpace($ScriptPath)) {

    # GitHub now requires TLS 1.2
    # https://blog.github.com/2018-02-23-weak-cryptographic-standards-removed/
    $CurrentMaxTls = [Math]::Max([Net.ServicePointManager]::SecurityProtocol.value__, [Net.SecurityProtocolType]::Tls.value__)
    $newTlsTypes = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -gt $CurrentMaxTls }
    $newTlsTypes | ForEach-Object {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $_
    }

    $HostUrl, $Owner, $Repo = $Uri.TrimStart('https://') -split ('/')
    $Url = 'https://{0}/{1}/{2}/archive/refs/heads/{3}.zip' -f $HostUrl, $Owner, $Repo, $RemoteBranch
    Write-Verbose "Url: $Url"

    Write-Host "Downloading latest version of $ModuleName from $Url" -ForegroundColor Cyan
    $File = [System.IO.Path]::Combine([system.io.path]::GetTempPath(), "$ModuleName.zip")
    $webclient = New-Object System.Net.WebClient
    try {
        $webclient.DownloadFile($Url, $File)
        Write-Verbose "File downloaded: $File"
    } catch {
        Write-Host "Failed to download the file from $Url, Error $($_.Exception.Message)" -ForegroundColor Red
        throw $_
    }
    Write-Host "File saved to $File" -ForegroundColor Green

    Write-Host "Expanding $ModuleName.zip to $($InstallPath)" -ForegroundColor Cyan
    Expand-Archive -Path $File -DestinationPath $InstallPath

    #Extract module version from module manifest
    $ModuleManifest = Get-ChildItem -Path $InstallPath -Filter "$ModuleName*.psd1" -Recurse | Select-Object -First 1
    if ($null -eq $ModuleManifest) {
        Write-Host "Module manifest not found in $($InstallPath)" -ForegroundColor Red
        throw "Module manifest not found"
    } else {
        $ModuleInfo = Import-PowerShellDataFile -Path $ModuleManifest.FullName
        $ModuleVersion = $ModuleInfo.ModuleVersion
        Write-Host "Module version: $($ModuleVersion)" -ForegroundColor Green
    }

    if (Test-Path -Path "$($InstallPath)\$($ModuleName)") {
        Write-Host "Removing any old copy" -ForegroundColor Cyan
        Remove-Item -Path "$($InstallPath)\$($ModuleName)" -Recurse -Force -ErrorAction Continue
    }
    Write-Host "Renaming folder" -ForegroundColor Cyan
    Copy-Item -Path "$($InstallPath)\$($ModuleName)-$($RemoteBranch)\$($ModuleName)" -Destination $InstallPath -Recurse -Force -ErrorAction Continue
    Remove-Item -Path "$($InstallPath)\$($ModuleName)-$($RemoteBranch)" -Recurse -Force
    Write-Host "Importing module from local path, force reloading" -ForegroundColor Cyan
    Import-Module -Name $ModuleName -Force
} else {
    Write-Host "Running locally from $($PSScriptRoot)" -ForegroundColor Cyan
    Remove-Item -Path "$($InstallPath)\$($ModuleName)" -Recurse -Force -ErrorAction Ignore
    Copy-Item -Path "$($PSScriptRoot)\$($ModuleName)" -Destination $InstallPath -Recurse -Force -ErrorAction Continue
    Write-Host "Importing module from local path, force reloading" -ForegroundColor Cyan
    Import-Module -Name $ModuleName -Force
}
Write-Host 'Module has been installed' -ForegroundColor Green

Get-Command -Module $ModuleName | Format-Table -AutoSize
