function New-DynamicHtmlTable {
    <#
    .SYNOPSIS
        Generates an HTML table section from inventory data using metadata.

    .DESCRIPTION
        Creates an HTML table section with title, optional highlights, optional description,
        search box (based on ReportSearchable), and sortable table data based on ReportFields
        metadata. Skips items with empty data arrays.

    .PARAMETER ItemName
        The name of the inventory item (e.g., "WindowsUpdates").

    .PARAMETER ItemData
        The array of data objects for this item.

    .PARAMETER InventoryData
        The full inventory data object containing metadata.

    .OUTPUTS
        String containing the HTML formatted section.
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

        $html = ""

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

        $html += "        <h2>$title</h2>`n"

        # Add description or last changed date
        if ($report.PSObject.Properties['Description']) {
            $html += "        <p>$($report.Description)</p>`n"
        } elseif ($InventoryData.PSObject.Properties[$lastChangedProp]) {
            $html += "        <p><em>Data collected: $($InventoryData.$lastChangedProp)</em></p>`n"
        }

        # Add highlights if specified
        if ($report.PSObject.Properties['Highlight']) {
            $highlights = $report.Highlight
            $highlightParts = @("Total: $($ItemData.Count)")

            # Process each highlight
            foreach ($property in $highlights.PSObject.Properties) {
                $fieldName = $property.Name
                $fieldValue = $property.Value

                # Count matching items
                $count = @($ItemData | Where-Object { $_.$fieldName -eq $fieldValue }).Count
                $highlightParts += "$($fieldValue): $count"
            }

            $html += "        <div class=`"stats`">$($highlightParts -join ' | ')</div>`n"
        }

        # Determine if searchable (default true if not specified)
        $searchable = $true
        if ($report.PSObject.Properties['Searchable']) {
            $searchable = $report.Searchable
        }

        # Add search box if searchable
        $tableId = "$($ItemName)Table"
        $searchId = "$($ItemName)Search"

        if ($searchable) {
            $html += @"
        <div class="search-container">
            <input type="text" class="search-box" id="$searchId" placeholder="Search..." onkeyup="filterTable('$tableId', '$searchId')">
        </div>

"@
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
        $columnIndex = 0
        foreach ($property in $reportFields.PSObject.Properties) {
            $fieldKeys += $property.Name
            $headers += @"
                    <th onclick="sortTable('$tableId', $columnIndex)">$($property.Value)</th>
"@
            $columnIndex++
        }

        $html += @"
        <table class="data-table" id="$tableId">
            <thead>
                <tr>
$($headers -join "`n")
                </tr>
            </thead>
            <tbody>

"@

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
            $html += "                <tr>`n"

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

                $html += "                    <td>$value</td>`n"
            }

            $html += "                </tr>`n"
        }

        $html += @"
            </tbody>
        </table>

"@

        return $html

    } catch {
        Write-Verbose "Error generating HTML table for $($ItemName): $($_.Exception.Message)"
        return ""
    }
}
