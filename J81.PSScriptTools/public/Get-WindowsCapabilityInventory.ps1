function Get-WindowsCapabilityInventory {
    [CmdletBinding()]
    param(
        [string]$InventoryFilePath = "C:\ProgramData\SystemInventory\SystemInventory.json"
    )
    $Script:LogFile = Join-Path -Path (Split-Path $InventoryFilePath -Parent) -ChildPath "$(([System.IO.FileInfo]$InventoryFilePath).BaseName).log"
    try {
        # ===== Retrieve Windows capabilities =====
        Write-Log "Retrieving Windows capabilities"
        $inventoryResults = @(Get-WindowsCapabilityOverview | ConvertTo-Hashtable)

        # ===== Save Inventory =====
        Write-Log "Saving SystemInventory..."

        $inventoryData = @{}
        # Add or update Windows Capabilities section
        $Item = "WindowsCapabilities"
        Write-Log "Saving $Item..."
        $inventoryData[$Item] = $inventoryResults
        $inventoryData["$($Item)Report"] = [Ordered]@{
            Order       = 4
            Title       = "Configured Windows Capabilities"
            Fields      = [Ordered]@{
                FriendlyName = "Name"
                State        = "State"
            }
            SortBy      = @("State", "FriendlyName")
            SortOrder   = @("Ascending", "Ascending")
            Highlight   = [Ordered]@{
                State = "Installed"
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
