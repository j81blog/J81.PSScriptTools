function Save-Inventory {
    [CmdletBinding()]
    param(
        [string]$InventoryFilePath = "C:\ProgramData\SystemInventory\SystemInventory.json",

        [ValidateNotNullOrEmpty()]
        [string]$Item,

        [ValidateNotNullOrEmpty()]
        [hashtable]$Data
    )

    $Script:LogFile = Join-Path -Path (Split-Path $InventoryFilePath -Parent) -ChildPath "Inventory.log"

    try {
        # ===== Update or Create JSON File =====
        Write-Log "Updating SystemInventory.json..."

        $inventoryData = [ordered]@{
            ComputerName = $Env:ComputerName
            LastChanged  = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
            AvailableItems = @()
            SystemInfo = @{}
        }

        # Load existing JSON if it exists
        if (Test-Path $InventoryFilePath) {
            Write-Log "Loading existing JSON file..."
            $inventoryContent = Get-Content $InventoryFilePath -Raw | ConvertFrom-Json

            # Convert PSCustomObject to Hashtable for easier manipulation
            $inventoryData = $inventoryContent | ConvertTo-Hashtable
            Write-Log "Existing data loaded successfully"
        } else {
            Write-Log "Creating new SystemInventory.json file..."
            $inventoryPath = Split-Path $InventoryFilePath -Parent
            if (-not (Test-Path $inventoryPath)) {
                New-Item -ItemType Directory -Path $inventoryPath -Force | Out-Null
                Write-Log "Created directory: $inventoryPath"
            }
        }

        # Add or update item data
        $inventoryData["$($Item)"] = $Data["$($Item)"]

        # Add Report metadata if present (nested structure)
        if ($Data.ContainsKey("$($Item)Report")) {
            $inventoryData["$($Item)Report"] = $Data["$($Item)Report"]
        }

        # Add LastChanged timestamp for this item
        if ($Data.ContainsKey("$($Item)LastChanged")) {
            $inventoryData["$($Item)LastChanged"] = $Data["$($Item)LastChanged"]
        }

        # Update global LastChanged
        $inventoryData["LastChanged"] = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')

        # Update AvailableItems array (exclude SystemInfo)
        if ($Item -ine "SystemInfo") {
            if ($inventoryData["AvailableItems"] -is [array] -and $inventoryData["AvailableItems"].Count -gt 0) {
                $inventoryData["AvailableItems"] += $Item
            } else {
                $inventoryData["AvailableItems"] = @($Item)
            }
            $inventoryData["AvailableItems"] = @($inventoryData["AvailableItems"] | Select-Object -Unique)
        }
        # Convert to JSON and save
        $inventoryData | ConvertTo-Json -Depth 10 | Set-Content -Path $InventoryFilePath -Encoding UTF8
        Write-Log "SystemInventory.json updated successfully at: $InventoryFilePath"
    } catch {
        $errorDetails = Get-ExceptionDetails -ErrorRecord $_ -AsText
        Write-Log "ERROR updating SystemInventory.json: `n$errorDetails" -Level "ERROR"
        throw $_
    } finally {
        $Script:LogFile = $null
    }
}