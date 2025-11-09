function Write-Log {
    param(
        [string]$Message,

        [string]$Source,

        [string]$Level = "INFO",

        [string]$LogFile = $Script:LogFile
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    # If source is empty, check if we can determine the name of the function or script calling the write-log function
    if ([string]::IsNullOrEmpty($Source)) {
        $callStack = Get-PSCallStack
        if ($callStack.Count -gt 1) {
            $Source = $callStack[1].FunctionName
            if ([string]::IsNullOrEmpty($Source)) {
                $Source = Split-Path -Leaf $callStack[1].ScriptName
            }
        }
    }

    if ([string]::IsNullOrEmpty($Source)) {
        $messageToShow = $Message
        $logMessage = "[$timestamp] [$Level] $Message"
    } else {
        $messageToShow = "$($Source): $($Message)"
        $logMessage = "[$timestamp] [$Level] [$Source] $Message"
    }
    if (-not [string]::IsNullOrEmpty($LogFile)) {
        if (!(Test-Path $LogFile)) {
            New-Item -ItemType File -Path $LogFile -Force | Out-Null
        }
        Add-Content -Path $LogFile -Value $logMessage -Force
    }
    if ($Level -eq "ERROR") {
        Write-Error $messageToShow
    } else {
        Write-Verbose $messageToShow
    }
}
