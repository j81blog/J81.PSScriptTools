[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$remoteBranch = 'main',

    [Parameter(Mandatory = $false)]
    $uri = 'https://github.com/j81blog/J81.PSScriptTools/archive'
)

#Requires -Version 5.1

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $installpath = [System.IO.Path]::Combine(([Environment]::GetFolderPath('MyDocuments')), 'WindowsPowerShell\Modules')
} elseif ($IsWindows) {
    $installpath = [System.IO.Path]::Combine(([Environment]::GetFolderPath('MyDocuments')), 'PowerShell\Modules')
} else {
    $installpath = [System.IO.Path]::Combine($env:HOME, '.local/share/powershell/Modules')
}

$executionPolicy = Get-ExecutionPolicy
if (('PSEdition' -notin $PSVersionTable.Keys -or $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) -and ($executionPolicy -notin 'Unrestricted', 'RemoteSigned', 'Bypass')) {
    Write-Host "Setting process execution policy to RemoteSigned" -ForegroundColor Cyan
    Set-ExecutionPolicy RemoteSigned -Scope Process -Force
} else {
    Write-Host "Current execution policy: $executionPolicy" -ForegroundColor Yellow
}

if (-not (Test-Path -Path $installpath)) {
    Write-Host "Creating module path: $installpath" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $installpath | Out-Null
}

if ([String]::IsNullOrWhiteSpace($PSScriptRoot)) {

    # GitHub now requires TLS 1.2
    # https://blog.github.com/2018-02-23-weak-cryptographic-standards-removed/
    $currentMaxTls = [Math]::Max([Net.ServicePointManager]::SecurityProtocol.value__, [Net.SecurityProtocolType]::Tls.value__)
    $newTlsTypes = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -gt $currentMaxTls }
    $newTlsTypes | ForEach-Object {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $_
    }


    $url = "{0}/{1}.zip" -f $Uri.TrimEnd('/'), $RemoteBranch
    Write-Host "Downloading latest version of $ModuleName from $url" -ForegroundColor Cyan
    $file = [System.IO.Path]::Combine([system.io.path]::GetTempPath(), "$ModuleName.zip")
    $webclient = New-Object System.Net.WebClient
    try {
        $webclient.DownloadFile($url, $file)
    } catch {
        Write-Host "Failed to download the file from $url, Error $($_.Exception.Message)" -ForegroundColor Red
        throw $_
    }
    Write-Host "File saved to $file" -ForegroundColor Green

    Write-Host "Expanding $ModuleName.zip to $($installpath)" -ForegroundColor Cyan
    Expand-Archive $file -DestinationPath $installpath

    #Extract module version from module manifest
    $moduleManifest = Get-ChildItem -Path $installpath -Filter "$ModuleName*.psd1" -Recurse | Select-Object -First 1
    if ($null -eq $moduleManifest) {
        Write-Host "Module manifest not found in $installpath" -ForegroundColor Red
        throw "Module manifest not found"
    } else {
        $moduleInfo = Import-PowerShellDataFile -Path $moduleManifest.FullName
        $moduleVersion = $moduleInfo.ModuleVersion
        Write-Host "Module version: $moduleVersion" -ForegroundColor Green
    }

    Write-Host "Removing any old copy" -ForegroundColor Cyan
    Remove-Item "$installpath\$ModuleName" -Recurse -Force -ErrorAction Ignore
    Write-Host "Renaming folder" -ForegroundColor Cyan
    Copy-Item "$installpath\$ModuleName-$RemoteBranch\$ModuleName" $installpath -Recurse -Force -ErrorAction Continue
    Remove-Item "$installpath\$ModuleName-$RemoteBranch" -Recurse -Force
    Import-Module -Name $ModuleName -Force
} else {
    Write-Host "Running locally from $PSScriptRoot" -ForegroundColor Cyan
    Remove-Item "$installpath\$ModuleName" -Recurse -Force -ErrorAction Ignore
    Copy-Item "$PSScriptRoot\$ModuleName" $installpath -Recurse -Force -ErrorAction Continue
    Write-Host "Importing module from local path, force reloading" -ForegroundColor Cyan
    Import-Module -Name $ModuleName -Force
}
Write-Host 'Module has been installed' -ForegroundColor Green

Get-Command -Module $ModuleName | Format-Table -AutoSize