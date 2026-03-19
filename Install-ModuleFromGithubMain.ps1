$ModuleName = 'J81.PSScriptTools'
$RemoteBranch = 'main'
$GitHubOwner = 'j81blog'

# set the user module path based on edition and platform
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $installpath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
} elseif ($IsWindows) {
    $installpath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
} else {
    $installpath = Join-Path $env:HOME '.local/share/powershell/Modules'
}

# deal with execution policy on Windows
if (('PSEdition' -notin $PSVersionTable.Keys -or
        $PSVersionTable.PSEdition -eq 'Desktop' -or
        $IsWindows) -and
    (Get-ExecutionPolicy) -notin 'Unrestricted', 'RemoteSigned', 'Bypass') {
    Write-Host "Setting user execution policy to RemoteSigned" -ForegroundColor Cyan
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

if (-not (Test-Path -Path $installpath)) {
    Write-Host "Creating module path: $installpath" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $installpath | Out-Null
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
    $Uri = "https://github.com/$($GitHubOwner)/$($ModuleName)"

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

    Write-Host "Downloading latest version of $($ModuleName) from $url" -ForegroundColor Cyan
    $file = Join-Path -Path ([system.io.path]::GetTempPath()) -ChildPath "$($ModuleName).zip"
    $webclient = New-Object System.Net.WebClient
    try {
        $webclient.DownloadFile($url, $file)
    } catch {
        throw "Failed to download $($ModuleName) from $url. Error: $($_.Exception.Message)"
    } finally {
        $webclient.Dispose()
    }
    Write-Host "File saved to $file" -ForegroundColor Green

    # extract the zip
    Write-Host "Expanding $($ModuleName).zip to $($installpath)" -ForegroundColor Cyan
    Expand-Archive $file -DestinationPath $installpath

    Write-Host "Removing any old copy" -ForegroundColor Cyan
    Remove-Item "$($installpath)\$($ModuleName)" -Recurse -Force -ErrorAction Ignore
    Write-Host "Renaming folder" -ForegroundColor Cyan
    Copy-Item "$($installpath)\$($ModuleName)-$($RemoteBranch)\$($ModuleName)" $installpath -Recurse -Force -ErrorAction Continue
    Remove-Item "$($installpath)\$($ModuleName)-$($RemoteBranch)" -Recurse -Force
    Import-Module -Name $($ModuleName) -Force
    # Clean Zip file
    Remove-Item -Path $file -Force
} else {
    Write-Host "Running locally" -ForegroundColor Cyan
    Remove-Item "$($installpath)\$($ModuleName)" -Recurse -Force -ErrorAction Ignore
    Copy-Item "$PSScriptRoot\$($ModuleName)" $installpath -Recurse -Force -ErrorAction Continue
    # force re-load the module (assuming you're editing locally and want to see changes)
    Import-Module -Name $($ModuleName) -Force
}
Write-Host 'Module has been installed' -ForegroundColor Green

Get-Command -Module $($ModuleName)
