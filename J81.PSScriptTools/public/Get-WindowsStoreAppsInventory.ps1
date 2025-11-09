function Get-WindowsStoreAppsInventory {
    <#
    .SYNOPSIS
        Collects Windows Store and MSIX apps inventory and saves it to a JSON file.

    .DESCRIPTION
        This function retrieves a complete inventory of Windows Store apps and MSIX packages
        installed on the system (for all users and provisioned apps) and saves the results
        to a JSON inventory file. It uses Get-WindowsStoreAppsOverview to gather the data
        and Save-Inventory to persist it.

        The function is designed for unattended deployments and system inventory scenarios,
        including running under SYSTEM context.

    .PARAMETER InventoryFilePath
        The path to the JSON inventory file where results will be saved.
        Default: "C:\ProgramData\SystemInventory\SystemInventory.json"

    .PARAMETER Scope
        Specifies the scope of apps to inventory:
        - 'AllUsers': All apps installed for any user on the system (default)
        - 'CurrentUser': Apps installed only for the current user
        - 'Provisioned': Apps provisioned for new user accounts

    .PARAMETER IncludeFrameworks
        Include framework packages in the inventory. By default, frameworks are excluded.

    .EXAMPLE
        Get-WindowsStoreAppsInventory
        Collects all Store apps and MSIX packages (all users + provisioned) and saves to default location.

    .EXAMPLE
        Get-WindowsStoreAppsInventory -InventoryFilePath "C:\Temp\MyInventory.json"
        Saves the inventory to a custom file path.

    .EXAMPLE
        Get-WindowsStoreAppsInventory -Scope CurrentUser -IncludeFrameworks
        Collects only current user apps including framework packages.

    .EXAMPLE
        Get-WindowsStoreAppsInventory -Scope Provisioned
        Collects only provisioned apps (staged for new users).

    .OUTPUTS
        None. The function saves results to a JSON file and logs to a log file.

    .NOTES
        Function Name : Get-WindowsStoreAppsInventory
        Version       : v1.0.0
        Author        : John Billekens
        Requires      : PowerShell 5.1+, Windows 10/11 or Windows Server 2016+

    .LINK
        Get-WindowsStoreAppsOverview
        Save-Inventory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$InventoryFilePath = "C:\ProgramData\SystemInventory\SystemInventory.json",

        [Parameter()]
        [ValidateSet('AllUsers', 'CurrentUser', 'Provisioned')]
        [string]$Scope = 'AllUsers',

        [Parameter()]
        [switch]$IncludeFrameworks
    )

    $Script:LogFile = Join-Path -Path (Split-Path $InventoryFilePath -Parent) -ChildPath "$(([System.IO.FileInfo]$InventoryFilePath).BaseName).log"

    try {
        # ===== Retrieve Windows Store Apps =====
        Write-Log "Retrieving Windows Store Apps (Scope: $Scope)"

        $overviewParams = @{
            Scope = $Scope
        }

        if ($IncludeFrameworks) {
            $overviewParams['IncludeFrameworks'] = $true
        }

        $inventoryResults = @(Get-WindowsStoreAppsOverview @overviewParams | ConvertTo-Hashtable)

        Write-Log "Retrieved $($inventoryResults.Count) Store apps"

        # ===== Save Inventory =====
        Write-Log "Saving SystemInventory..."

        $inventoryData = @{}
        # Add or update Windows Store Apps section
        $Item = "WindowsStoreApps"
        Write-Log "Saving $Item..."
        $inventoryData[$Item] = $inventoryResults
        $inventoryData["$($Item)Report"] = [Ordered]@{
            Order      = 6
            Title      = "Installed Windows Store Apps and MSIX Packages"
            Fields     = [Ordered]@{
                DisplayName  = "Name"
                Version      = "Version"
                Publisher    = "Publisher"
                Architecture = "Architecture"
            }
            SortBy     = @("DisplayName")
            SortOrder  = @("Ascending")
            Highlight  = @{}
            Searchable = $true
        }
        $inventoryData["$($Item)LastChanged"] = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')

        Save-Inventory -InventoryFilePath $InventoryFilePath -Data $inventoryData -Item $Item

        Write-Log "Windows Store Apps inventory collection completed successfully"
        Write-Log "Inventory saved to: $InventoryFilePath"
    } catch {
        Write-Log "Error during collection: $($_.Exception.Message)" -Level "ERROR"
        Write-Log "Important Error details:"
        Write-Log "$($_ | Get-ExceptionDetails -AsText)"
    } finally {
        $Script:LogFile = $null
    }
}
