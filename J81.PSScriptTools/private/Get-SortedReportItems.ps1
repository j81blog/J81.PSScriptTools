function Get-SortedReportItems {
    <#
    .SYNOPSIS
        Gets and sorts inventory items by their Report.Order metadata.

    .DESCRIPTION
        Reads the AvailableItems array from inventory data and sorts them by
        their corresponding {Item}Report.Order values. Items without Order
        are placed at the end.

    .PARAMETER InventoryData
        The inventory data object (PSCustomObject from JSON).

    .OUTPUTS
        Array of item names sorted by Report.Order.
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$InventoryData
    )

    try {
        $availableItems = @($InventoryData.AvailableItems)

        if ($availableItems.Count -eq 0) {
            Write-Verbose "No items found in AvailableItems array"
            return @()
        }

        # Create array of objects with item name and order
        $itemsWithOrder = foreach ($item in $availableItems) {
            $reportProperty = "$($item)Report"
            $order = if ($InventoryData.PSObject.Properties[$reportProperty] -and
                         $InventoryData.$reportProperty.PSObject.Properties['Order']) {
                $InventoryData.$reportProperty.Order
            } else {
                999  # Default high number for items without order
            }

            [PSCustomObject]@{
                Name  = $item
                Order = $order
            }
        }

        # Sort by Order and return just the names
        $sorted = $itemsWithOrder | Sort-Object Order | Select-Object -ExpandProperty Name

        Write-Verbose "Sorted $($sorted.Count) items by Report.Order"
        return @($sorted)

    } catch {
        Write-Verbose "Error sorting items: $($_.Exception.Message)"
        return @()
    }
}
