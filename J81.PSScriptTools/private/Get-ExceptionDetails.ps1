function Get-ExceptionDetails {
    <#
    .SYNOPSIS
        Extracts detailed information from a PowerShell ErrorRecord object.

    .DESCRIPTION
        The Get-ExceptionDetails function processes a PowerShell ErrorRecord object
        and extracts comprehensive error information including exception messages,
        stack traces, location details, and nested inner exceptions. This is useful
        for detailed error logging and debugging.

    .PARAMETER ErrorRecord
        The ErrorRecord object to extract details from. This is typically obtained
        from $_ in a catch block or from $Error[0].

    .PARAMETER AsText
        If specified, returns the error details as a formatted text string instead
        of a PSCustomObject.

    .EXAMPLE
        try {
            Get-Item "C:\NonExistent\Path" -ErrorAction Stop
        }
        catch {
            $details = Get-ExceptionDetails -ErrorRecord $_
            $details | Format-List
        }

        Captures an error and extracts detailed information from it.

    .EXAMPLE
        $details = Get-ExceptionDetails -ErrorRecord $Error[0]
        Write-Host "Error occurred at line $($details.LineNumber) in $($details.ScriptName)"

        Processes the most recent error from the $Error automatic variable.

    .OUTPUTS
        System.Collections.Specialized.OrderedDictionary
        Returns an ordered hashtable containing detailed error information.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [switch]$AsText
    )

    # Recursively collect all inner exceptions
    $innerExceptions = @()
    $currentException = $ErrorRecord.Exception.InnerException
    while ($null -ne $currentException) {
        $innerExceptions += [ordered]@{
            Message = $currentException.Message
            Type    = $currentException.GetType().FullName
        }
        $currentException = $currentException.InnerException
    }

    $errorDetails = [ordered]@{
        Timestamp         = Get-Date
        Message           = $ErrorRecord.Exception.Message
        ExceptionType     = $ErrorRecord.Exception.GetType().FullName
        ErrorId           = $ErrorRecord.FullyQualifiedErrorId
        Category          = $ErrorRecord.CategoryInfo.Category
        ScriptName        = $ErrorRecord.InvocationInfo.ScriptName
        LineNumber        = $ErrorRecord.InvocationInfo.ScriptLineNumber
        CharacterPosition = $ErrorRecord.InvocationInfo.OffsetInLine
        Line              = $ErrorRecord.InvocationInfo.Line
        PositionMessage   = $ErrorRecord.InvocationInfo.PositionMessage
        CategoryInfo      = $ErrorRecord.CategoryInfo
        TargetObject      = $ErrorRecord.TargetObject
        StackTrace        = $ErrorRecord.ScriptStackTrace
        InnerExceptions   = if ($innerExceptions.Count -gt 0) { $innerExceptions } else { $null }
    }

    if ($AsText) {
        return ("`r`n$(( [PSCustomObject]$errorDetails | Out-String).Trim())`r`n")
    } else {
        return [PSCustomObject]$errorDetails
    }
}