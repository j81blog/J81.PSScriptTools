function New-SystemInventoryReport {
    <#
.SYNOPSIS
    Generates Markdown and HTML reports from SystemInventory.json

.DESCRIPTION
    Reads the SystemInventory.json file and generates professional Markdown and HTML reports
    with sortable/filterable tables. Output files are timestamped based on WindowsUpdatesLastChanged.

.PARAMETER JsonPath
    Path to the SystemInventory.json file. Defaults to C:\ProgramData\SystemInventory\SystemInventory.json

.PARAMETER OutputPath
    Directory where the MD and HTML files will be saved. Defaults to same directory as JSON file.

.EXAMPLE
    .\Generate-SystemInventoryReport.ps1
    .\Generate-SystemInventoryReport.ps1 -JsonPath "C:\Custom\Path\SystemInventory.json" -OutputPath "C:\Reports"
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$InventoryFilePath = "C:\ProgramData\SystemInventory\SystemInventory.json",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ReportBaseFileName = "SystemInventoryReport",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath = "C:\ProgramData\SystemInventory",

        [switch]$HTMLOnly,

        [switch]$MarkdownOnly
    )
    $Script:LogFile = Join-Path -Path (Split-Path $InventoryFilePath -Parent) -ChildPath "Inventory.log"
    $MarkDownReport = $true
    $HTMLReport = $true
    if ($HTMLOnly.IsPresent) {
        $MarkDownReport = $false
    }
    if ($MarkdownOnly.IsPresent) {
        $HTMLReport = $false
    }

    try {
        Write-Log "Starting report generation..."
        Write-Log "JSON Path: $InventoryFilePath"
        Write-Log "Output Path: $OutputPath"

        # Verify JSON file exists
        if (-not (Test-Path $InventoryFilePath)) {
            Write-Log "ERROR: SystemInventory.json not found at: $InventoryFilePath"
            throw "SystemInventory.json not found at: $InventoryFilePath"
        }

        # Load JSON data
        Write-Log "Loading SystemInventory.json..."
        $inventory = Get-Content $InventoryFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $formattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        $computerName = if ($inventory.ComputerName) { $inventory.ComputerName } else { "Unknown" }

        Write-Log "Report Date: $formattedDate"
        Write-Log "Computer Name: $computerName"

        if ($MarkDownReport) {
            $mdFileName = "$($ReportBaseFileName).md"
            $mdPath = Join-Path $OutputPath $mdFileName
            # ===== GENERATE MARKDOWN REPORT =====
            Write-Log "Generating Markdown report..."

            $markdown = @"
# System Inventory - $formattedDate
**Golden Master: $computerName**

---

"@

            # 1 System Information Section (keep as-is, custom formatting)
            if ($inventory.SystemInfo) {
                $markdown += "## System Information`n`n"
                $markdown += Format-SystemInfoMarkdown -SystemInfo $inventory.SystemInfo
                $markdown += "---`n`n"
            }

            # 2+ Dynamic sections based on AvailableItems and metadata
            $sortedItems = Get-SortedReportItems -InventoryData $inventory

            foreach ($itemName in $sortedItems) {
                Write-Log "Processing Markdown section: $itemName"

                # Get the data for this item
                $itemData = @($inventory.$itemName)

                # Generate dynamic table
                $section = New-DynamicMarkdownTable -ItemName $itemName -ItemData $itemData -InventoryData $inventory

                if (-not [string]::IsNullOrWhiteSpace($section)) {
                    $markdown += $section
                }
            }

            # Save Markdown file
            $markdown | Set-Content -Path $mdPath -Encoding UTF8
            Write-Log "Markdown report saved: $mdPath"
        }
        if ($HTMLReport) {
            $htmlFileName = "$($ReportBaseFileName).html"
            $htmlPath = Join-Path $OutputPath $htmlFileName
            # ===== GENERATE HTML REPORT =====
            Write-Log "Generating HTML report..."

            $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Inventory - $computerName</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f5f5f5;
            padding: 20px;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-radius: 8px;
        }

        header {
            border-bottom: 3px solid #0066cc;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }

        h1 {
            color: #0066cc;
            font-size: 2.2em;
            margin-bottom: 10px;
        }

        .subtitle {
            color: #666;
            font-size: 1.2em;
            font-weight: 500;
        }

        h2 {
            color: #0066cc;
            font-size: 1.8em;
            margin-top: 40px;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e0e0e0;
        }

        h3 {
            color: #333;
            font-size: 1.3em;
            margin-top: 25px;
            margin-bottom: 15px;
        }

        .section {
            margin-bottom: 30px;
        }

        .search-container {
            margin: 20px 0;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 5px;
        }

        .search-box {
            width: 100%;
            padding: 10px 15px;
            font-size: 14px;
            border: 1px solid #ddd;
            border-radius: 4px;
            outline: none;
        }

        .search-box:focus {
            border-color: #0066cc;
            box-shadow: 0 0 0 3px rgba(0,102,204,0.1);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background: white;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .info-table {
            max-width: 800px;
        }

        .info-table th {
            background: #f8f9fa;
            text-align: left;
            width: 30%;
            font-weight: 600;
        }

        .data-table thead {
            background: #0066cc;
            color: white;
        }

        th, td {
            padding: 12px 15px;
            border: 1px solid #e0e0e0;
            text-align: left;
        }

        .data-table th {
            cursor: pointer;
            user-select: none;
            position: relative;
            padding-right: 30px;
        }

        .data-table th:hover {
            background: #0052a3;
        }

        .data-table th::after {
            content: '\25B2\25BC';
            position: absolute;
            right: 10px;
            opacity: 0.5;
            font-size: 0.7em;
            letter-spacing: -0.3em;
        }

        .data-table th.sort-asc::after {
            content: '\25B2';
            opacity: 1;
        }

        .data-table th.sort-desc::after {
            content: '\25BC';
            opacity: 1;
        }

        tbody tr:nth-child(even) {
            background: #f8f9fa;
        }

        tbody tr:hover {
            background: #e3f2fd;
        }

        .result-succeeded {
            background-color: #d4edda !important;
            color: #155724;
            font-weight: 500;
        }

        .result-failed {
            background-color: #fff3cd !important;
            color: #856404;
            font-weight: 500;
        }

        .stats {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin: 15px 0;
            font-weight: 500;
        }

        @media print {
            body {
                background: white;
                padding: 0;
            }

            .container {
                box-shadow: none;
                padding: 20px;
            }

            .search-container {
                display: none;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>System Inventory - $formattedDate</h1>
            <div class="subtitle">Golden Master: $computerName</div>
        </header>

"@

            # System Information Section (keep as-is, custom formatting)
            if ($inventory.SystemInfo) {
                $htmlContent += "<h2>System Information</h2>`n"
                $htmlContent += Format-SystemInfoHtml -SystemInfo $inventory.SystemInfo
            }

            # Dynamic sections based on AvailableItems and metadata
            $sortedItems = Get-SortedReportItems -InventoryData $inventory

            foreach ($itemName in $sortedItems) {
                Write-Log "Processing HTML section: $itemName"

                # Get the data for this item
                $itemData = @($inventory.$itemName)

                # Generate dynamic table
                $section = New-DynamicHtmlTable -ItemName $itemName -ItemData $itemData -InventoryData $inventory

                if (-not [string]::IsNullOrWhiteSpace($section)) {
                    $htmlContent += $section
                }
            }

            # JavaScript for sorting and filtering
            $htmlContent += @"
    </div>

    <script>
        function sortTable(tableId, columnIndex) {
            const table = document.getElementById(tableId);
            const tbody = table.querySelector('tbody');
            const rows = Array.from(tbody.querySelectorAll('tr'));
            const th = table.querySelectorAll('th')[columnIndex];

            // Determine sort direction
            const isAsc = th.classList.contains('sort-asc');

            // Remove all sort classes
            table.querySelectorAll('th').forEach(header => {
                header.classList.remove('sort-asc', 'sort-desc');
            });

            // Add appropriate sort class
            if (isAsc) {
                th.classList.add('sort-desc');
            } else {
                th.classList.add('sort-asc');
            }

            // Sort rows
            rows.sort((a, b) => {
                const aValue = a.cells[columnIndex].textContent.trim();
                const bValue = b.cells[columnIndex].textContent.trim();

                // Try to parse as number or date
                const aNum = parseFloat(aValue);
                const bNum = parseFloat(bValue);

                if (!isNaN(aNum) && !isNaN(bNum)) {
                    return isAsc ? bNum - aNum : aNum - bNum;
                }

                // String comparison
                return isAsc ? bValue.localeCompare(aValue) : aValue.localeCompare(bValue);
            });

            // Rebuild tbody
            rows.forEach(row => tbody.appendChild(row));
        }

        function filterTable(tableId, searchId) {
            const searchTerm = document.getElementById(searchId).value.toLowerCase();
            const table = document.getElementById(tableId);
            const rows = table.querySelectorAll('tbody tr');

            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(searchTerm) ? '' : 'none';
            });
        }
    </script>
</body>
</html>
"@

            # Save HTML file
            $htmlContent | Set-Content -Path $htmlPath -Encoding UTF8
            Write-Log "HTML report saved: $htmlPath"
        }

        Write-Log "Report generation completed successfully"
        Write-Log "Generated files:"
        if ($MarkDownReport) {
            Write-Log "  - Markdown: $mdPath"
        }
        if ($HTMLReport) {
            Write-Log "  - HTML: $htmlPath"
        }

    } catch {
        Write-Log "Error during report generation: $($_.Exception.Message)" -Level "ERROR"
        Write-Log "Important Error details:"
        Write-Log "$($_ | Get-ExceptionDetails -AsText)"
        Throw $_
    } finally {
        $Script:LogFile = $null
    }
}
