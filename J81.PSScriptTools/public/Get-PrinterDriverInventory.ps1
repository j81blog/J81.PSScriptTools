function Get-PrinterDriverInventory {
    <#
        .SYNOPSIS
            Get installed printer drivers and save them to a JSON file.
        .DESCRIPTION
            This script retrieves the installed printer drivers on a Windows machine, excluding specified drivers, and saves the information to a JSON file in a specified inventory path. It also updates the computer name and last changed timestamp in the inventory file.

    .PARAMETER Exclusions
    An array of printer driver names to exclude from the inventory. Default is "Generic / Text Only".

    .PARAMETER InventoryPath
    The path where the inventory file will be saved. Default is "C:\ProgramData\SystemInventory".

    .EXAMPLE
    Get-InstalledPrinterDrivers -Exclusions @("Generic / Text Only") -InventoryPath "C:\ProgramData\SystemInventory"

    This command retrieves installed printer drivers, excluding "Generic / Text Only", formats the output as JSON, and saves it to the specified inventory path.
    .NOTES
    function Name : Get-InstalledPrinterDrivers
    Version : v1.0.0
    Author : John Billekens Consultancy

    #>
    [CmdletBinding()]
    param(
        [string[]]$Exclusions = @("Generic / Text Only"),

        [string]$InventoryFilePath = "C:\ProgramData\SystemInventory\SystemInventory.json"
    )

    try {
        $Script:LogFile = Join-Path -Path (Split-Path $InventoryFilePath -Parent) -ChildPath "$(([System.IO.FileInfo]$InventoryFilePath).BaseName).log"
        Import-Module -Name PrintManagement -ErrorAction Stop
        # ===== Retrieve Installed Printer Drivers =====
        Write-Log "Retrieving installed printer drivers"
        $printerDriversInstalled = Get-PrinterDriver | Where-Object { $_.InfPath -notmatch "printqueue.dll" }
        $printers = $printerDriversInstalled | Where-Object { $_.Name -notin $exclusions }
        $inventoryResults = @()
        foreach ($printer in $printers) {
            Write-Log "Processing printer driver: $($printer.Name)"
            try {
                $driverInfPath = $printer.InfPath
                $driverFilename = "$driverInfPath".replace("C:\WINDOWS\System32\DriverStore\FileRepository\", $null)
                $driverParentFolder = Split-Path -Path $driverFilename -Parent -ErrorAction SilentlyContinue
                $driverInfFileName = Split-Path -Path $driverFilename -Leaf -ErrorAction SilentlyContinue
            } catch {

            }
            $major = ($printer.DriverVersion -shr 48) -band 0xFFFF
            $minor = ($printer.DriverVersion -shr 32) -band 0xFFFF
            $build = ($printer.DriverVersion -shr 16) -band 0xFFFF
            $revision = $printer.DriverVersion -band 0xFFFF
            $driverVersion = "$($major).$($minor).$($build).$($revision)"

            $inventoryResults += @{
                Name               = $printer.Name
                Provider           = $printer.provider
                Manufacturer       = $(if ($printer.Manufacturer) { $printer.Manufacturer } else { "Unknown" })
                Version            = $(if ($driverVersion) { $driverVersion } else { "Unknown" })
                MajorVersion       = $printer.MajorVersion
                InfPath            = $driverParentFolder
                InfFileName        = $driverInfFileName
                PrinterEnvironment = $printer.PrinterEnvironment
            }
        }

        # ===== Save Inventory =====
        Write-Log "Saving SystemInventory..."

        $inventoryData = @{}
        # Add or update PrinterDrivers section
        $Item = "PrinterDrivers"
        Write-Log "Saving $Item..."
        $inventoryData[$Item] = $inventoryResults
        $inventoryData["$($Item)Report"] = @{
            Order       = 7
            Title       = "Installed Printer Drivers"
            ReportFields = [Ordered]@{
                Name               = "Name"
                Version            = "Version"
                Manufacturer       = "Manufacturer"
                PrinterEnvironment = "Environment"
            }
            SortBy      = @("Name")
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
