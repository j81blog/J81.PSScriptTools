function Get-SoftwareInventory {
    [CmdletBinding()]
    param(
        [string]$InventoryFilePath = "C:\ProgramData\SystemInventory\SystemInventory.json"
    )
    $Script:LogFile = Join-Path -Path (Split-Path $InventoryFilePath -Parent) -ChildPath "Inventory.log"
    Write-Log "Importing PackageManagement module"
    Import-Module PackageManagement -Force
    Write-Log "Module imported successfully"
    try {
        # ===== Retrieve Installed Software =====
        Write-Log "Retrieving installed software packages"
        $inventoryResults = @(Get-InstalledSoftware | ConvertTo-Hashtable)

        # ===== Save Inventory =====
        Write-Log "Saving SystemInventory..."

        $inventoryData = @{}
        # Add or update InstalledSoftware section
        $Item = "InstalledSoftware"
        Write-Log "Saving $Item..."
        $inventoryData[$Item] = $inventoryResults
        $inventoryData["$($Item)Report"] = @{
            Order       = 3
            Title       = "Installed Software"
            Fields      = [Ordered]@{
                ProductName     = "Product Name"
                ProductVersion  = "Version"
                Manufacturer    = "Manufacturer"
                InstallDate     = "Install Date"
            }
            SortBy      = @("ProductName")
            SortOrder   = @("Ascending")
            Highlight   = @{}
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
