function Convert-AppxArchitecture {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [object]$Value

    )
    if ($Value -is [uint32]) {
        switch ($Value) {
            0 { $result = "x86" }
            5 { $result = "ARM" }
            9 { $result = "x64" }
            11 { $result = "Neutral" }
            12 { $result = "ARM64" }
            default { $result = $Value.ToString() }
        }
    } elseif ($Value -is [Windows.System.ProcessorArchitecture]) {
        switch ($Value) {
            "X86" { $result = "x86" }
            "Arm" { $result = "ARM" }
            "X64" { $result = "x64" }
            "Neutral" { $result = "Neutral" }
            "Arm64" { $result = "ARM64" }
            "Unknown" { $result = "Unknown" }
            "X86OnArm64" { $result = "x86 on ARM64" }
            default { $result = $Value.ToString() }
        }
    } else {
        $result = $Value.ToString()
    }
    return $result
}
