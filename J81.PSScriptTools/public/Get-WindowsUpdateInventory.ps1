function Get-WindowsUpdateInventory {
    [CmdletBinding()]
    param(
        [string]$InventoryFilePath = "C:\ProgramData\SystemInventory\SystemInventory.json"
    )
    $Script:LogFile = Join-Path -Path (Split-Path $InventoryFilePath -Parent) -ChildPath "$(([System.IO.FileInfo]$InventoryFilePath).BaseName).log"
    try {
        # ===== Retrieve Windows Updates =====
        Write-Log "Retrieving Windows updates"
        $inventoryResults = @(Get-WindowsUpdateHistory | Sort-Object -Property Date, KB -Descending | Select-Object -Property @{ Name = "Date"; Expression = { $_.Date.ToString("yyyy-MM-dd HH:mm:ss") } }, KB, Result, Title, Product, Category, SupportUrl, RevisionNumber, Description)

        # ===== Save Inventory =====
        Write-Log "Saving SystemInventory..."

        $inventoryData = @{}
        # Add or update WindowsUpdates section
        $Item = "WindowsUpdates"
        Write-Log "Saving $Item..."
        $inventoryData[$Item] = $inventoryResults
        $inventoryData["$($Item)Report"] = [Ordered]@{
            ReportFields = [Ordered]@{
                Date     = "Date"
                KB       = "KB"
                Result   = "Result"
                Category = "Category"
                Title    = "Title"
            }
            ReportOrder  = 2
            ReportTitle  = "Installed Windows Updates"
            SortBy       = @("Date", "KB")
            SortOrder    = @("Descending", "Descending")
            Highlight   = @{
                Result = "Succeeded"
            }
            Searchable  = $true
        }
        $inventoryData["$($Item)LastChanged"] = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')

        Save-Inventory -InventoryFilePath $InventoryFilePath -Data $inventoryData -Item $Item

        Write-Log "System information collection completed successfully"
    } catch {
        Write-Log "Error during collection: $($_.Exception.Message)" -Level "ERROR"
        Write-Log "Important Error details:"
        Write-Log "$($_ | Get-ExceptionDetails -AsText)"
    } finally {
        $Script:LogFile = $null
    }
}
