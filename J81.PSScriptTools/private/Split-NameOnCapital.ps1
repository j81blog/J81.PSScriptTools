function Split-NameOnCapital {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline)]
        [string]$InputString,

        [Switch]$DotsToSpaces
    )

    if ($DotsToSpaces) {
        # Replace dots with spaces unless the dot is between two digits.
        # This pattern matches a dot that is either not preceded by a digit or not followed by a digit.
        $InputString = [regex]::Replace($InputString, '(?:(?<!\d)\.|\.(?!\d))', ' ')
    }

    # Split the string by whitespace to handle each chunk separately.
    $words = $InputString -split '\s+'

    # Process each word: if it isn't composed entirely of uppercase letters and numbers,
    # insert spaces based on capital letters.
    for ($i = 0; $i -lt $words.Length; $i++) {
        if ($words[$i] -cmatch '^[A-Z0-9]+$') {
            continue
        }
        $words[$i] = [regex]::Replace($words[$i], '(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])', ' ')
    }
    return ($words -join ' ')
}