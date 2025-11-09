function Test-IsGUID {
    <#
    .SYNOPSIS
        Tests if a string is a valid GUID.

    .DESCRIPTION
        This function checks if the provided string is a valid GUID (Globally Unique Identifier).

    .PARAMETER InputString
        The string to test for GUID format.

    .EXAMPLE
        Test-IsGUID -InputString "12345678-1234-1234-1234-123456789012"
        Returns $true if the string is a valid GUID.

    .EXAMPLE
        "not-a-guid" | Test-IsGUID
        Returns $false.

    .OUTPUTS
        System.Boolean

    .NOTES
        Function Name : Test-IsGUID
        Version       : v1.0.0
        Author        : John Billekens
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [AllowEmptyString()]
        [string]$InputString
    )

    process {
        if ([string]::IsNullOrWhiteSpace($InputString)) {
            return $false
        }

        try {
            $guid = [System.Guid]::Empty
            return [System.Guid]::TryParse($InputString, [ref]$guid)
        } catch {
            return $false
        }
    }
}
