function New-DynamicMarkdownTable {
    <#
    .SYNOPSIS
        Generates a Markdown table section from inventory data using metadata.

    .DESCRIPTION
        Creates a Markdown table section with title, optional highlights, optional description,
        and table data based on ReportFields metadata. Skips items with empty data arrays.

    .PARAMETER ItemName
        The name of the inventory item (e.g., "WindowsUpdates").

    .PARAMETER ItemData
        The array of data objects for this item.

    .PARAMETER InventoryData
        The full inventory data object containing metadata.

    .OUTPUTS
        String containing the Markdown formatted section.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ItemName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$ItemData,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$InventoryData
    )

    try {
        # Skip if data is empty
        if ($ItemData.Count -eq 0) {
            Write-Verbose "Skipping $ItemName - no data"
            return ""
        }

        $markdown = ""

        # Get Report object
        $reportProperty = "$($ItemName)Report"
        if (-not $InventoryData.PSObject.Properties[$reportProperty]) {
            Write-Verbose "No Report metadata found for $ItemName"
            return ""
        }

        $report = $InventoryData.$reportProperty
        $lastChangedProp = "$($ItemName)LastChanged"

        # Get title (use Title from Report, fallback to ItemName)
        $title = if ($report.PSObject.Properties['Title']) {
            $report.Title
        } else {
            $ItemName
        }

        $markdown += "## $title`n`n"

        # Add description or last changed date
        if ($report.PSObject.Properties['Description']) {
            $markdown += "$($report.Description)`n`n"
        } elseif ($InventoryData.PSObject.Properties[$lastChangedProp]) {
            $markdown += "_Data collected: $($InventoryData.$lastChangedProp)_`n`n"
        }

        # Add highlights if specified
        if ($report.PSObject.Properties['Highlight']) {
            $highlights = $report.Highlight
            $highlightParts = @("**Total:** $($ItemData.Count)")

            # Process each highlight
            foreach ($property in $highlights.PSObject.Properties) {
                $fieldName = $property.Name
                $fieldValue = $property.Value

                # Count matching items
                $count = @($ItemData | Where-Object { $_.$fieldName -eq $fieldValue }).Count
                $highlightParts += "**$($fieldValue):** $count"
            }

            $markdown += $($highlightParts -join " | ")
            $markdown += "`n`n"
        }

        # Get Fields (required)
        if (-not $report.PSObject.Properties['Fields']) {
            Write-Verbose "No Report.Fields found for $ItemName"
            return ""
        }

        $reportFields = $report.Fields

        # Build table header
        $headers = @()
        $fieldKeys = @()
        foreach ($property in $reportFields.PSObject.Properties) {
            $fieldKeys += $property.Name
            $headers += $property.Value
        }

        $markdown += "| $($headers -join ' | ') |`n"
        $markdown += "|" + ($headers | ForEach-Object { "---" }) -join "|" + "|`n"

        # Sort data if specified
        $sortedData = $ItemData
        if ($report.PSObject.Properties['SortBy'] -and $report.PSObject.Properties['SortOrder']) {
            $sortBy = @($report.SortBy)
            $sortOrder = @($report.SortOrder)

            # Build sort parameters
            $sortParams = @{}
            $sortParams['Property'] = $sortBy

            # Check if any sort order is Descending
            if ($sortOrder -contains "Descending") {
                $sortParams['Descending'] = $true
            }

            $sortedData = $ItemData | Sort-Object @sortParams
        }

        # Build table rows
        foreach ($item in $sortedData) {
            $rowValues = @()
            foreach ($fieldKey in $fieldKeys) {
                $value = if ($item.PSObject.Properties[$fieldKey]) {
                    $item.$fieldKey
                } else {
                    "N/A"
                }

                # Handle empty values
                if ([string]::IsNullOrWhiteSpace($value)) {
                    $value = "N/A"
                }

                $rowValues += $value
            }

            $markdown += "| $($rowValues -join ' | ') |`n"
        }

        $markdown += "`n---`n`n"

        return $markdown

    } catch {
        Write-Verbose "Error generating Markdown table for $($ItemName): $($_.Exception.Message)"
        return ""
    }
}
