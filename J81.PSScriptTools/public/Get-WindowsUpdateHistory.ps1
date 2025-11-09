function Get-WindowsUpdateHistory {
    <#
        .SYNOPSIS
            Retrieves Windows Update history with detailed information and filtering options.

        .DESCRIPTION
            This function retrieves the Windows Update history using the Microsoft Update Session COM object.
            It provides detailed information including KB articles, update categories, installation status, and
            supports filtering options to exclude Defender and driver updates.

        .PARAMETER First
            Specifies the number of most recent updates to return. If not specified, all updates are returned.

        .PARAMETER SkipDefenderUpdates
            Excludes Microsoft Defender updates from the results.

        .PARAMETER SkipDriverUpdates
            Excludes driver updates from the results.

        .OUTPUTS
            Returns an array of objects containing the update history, including date, result, title, KB article,
            category, description, support URL, product, update ID, and revision number.

        .EXAMPLE
            Get-WindowsUpdateHistory | ConvertTo-Csv -NoTypeInformation | Sort-Object -Property Date -Descending | out-file -FilePath "${Env:USERPROFILE}\Desktop\${Env:COMPUTERNAME} - Windows updates.csv"
            Exports all Windows Update history to a CSV file.

        .EXAMPLE
            Get-WindowsUpdateHistory | Where {$_.Title -notlike "*KB2267602*" -and $_.Title -notlike "*KB4052623*"} | Sort-Object -Property Date -Descending | Out-GridView
            Displays update history excluding specific KB articles in a grid view.

        .EXAMPLE
            Get-WindowsUpdateHistory -SkipDefenderUpdates -SkipDriverUpdates | Out-GridView
            Displays update history excluding Defender and driver updates.

        .EXAMPLE
            Get-WindowsUpdateHistory -First 20 | Format-Table Date, KB, Category, Title, Result -AutoSize
            Displays the 20 most recent updates with their category in a formatted table.

        .EXAMPLE
            Get-WindowsUpdateHistory | Group-Object Category | Select-Object Name, Count
            Groups all updates by category and displays the count for each category.

        .NOTES
            This function requires the Microsoft Update Session COM object, which is available on Windows systems with Windows Update functionality.
    #>
    [CmdletBinding()]
    param(
        [int]$First,

        [switch]$SkipDefenderUpdates,

        [switch]$SkipDriverUpdates
    )


    try {
        Write-Verbose "Querying Windows Update history..."
        $updateSession = New-Object -ComObject 'Microsoft.Update.Session'
        $resultCodeTable = @{
            0 = "Not Started"
            1 = "In Progress"
            2 = "Succeeded"
            3 = "Succeeded With Errors"
            4 = "Failed"
            5 = "Aborted"
        }

        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $historyCount = $updateSearcher.GetTotalHistoryCount()
        $historyQueryResults = $updateSession.QueryHistory("", 0, $historyCount)

        $output = @($historyQueryResults |
                Where-Object { -not [String]::IsNullOrWhiteSpace($($_.Title)) } |
                Select-Object @{Name = 'Date'; Expression = { $_.Date } },
                @{Name = 'Result'; Expression = { $resultCodeTable[$_.ResultCode] } },
                @{Name = 'Title'; Expression = { $_.Title } },
                @{Name = 'KB'; Expression = { if ($_.Title -match 'KB(\d+)') { "KB$($matches[1])" } else { $null } } },
                @{Name = 'Category'; Expression = {
                        $updateClassifications = @()
                        if ($_.Categories) {
                            foreach ($cat in $_.Categories) {
                                # Check various category types that might indicate update classification
                                if ($cat.Type -eq 'UpdateClassification' -or $cat.Type -eq 'Category') {
                                    $updateClassifications += $cat.Name
                                }
                            }
                        }
                        if ($updateClassifications.Count -gt 0) {
                            $updateClassifications -join ', '
                        } else {
                            # Fallback: try to determine from title
                            if ($_.Title -match 'Driver') { 'Driver' }
                            elseif ($_.Description -match 'driver update') { 'Driver' }
                            elseif ($_.Title -like '*security*update*defender*antivirus*') { 'Defender Update' }
                            elseif ($_.Title -match 'Definition') { 'Definition Update' }
                            elseif ($_.Title -match 'Security') { 'Security Update' }
                            elseif ($_.Title -match 'Feature') { 'Feature Pack' }
                            elseif ($_.Title -match 'Cumulative') { 'Cumulative Update' }
                            else { 'Update' }
                        }
                    }
                },
                @{Name = 'Description'; Expression = { $_.Description } },
                @{Name = 'SupportUrl'; Expression = { $_.SupportUrl } },
                @{Name = 'Product'; Expression = {
                        $product = $_.Categories | Where-Object { $_.Type -eq 'Product' } | Select-Object -First 1 -ExpandProperty Name
                        if ($null -ne $product) { $product } else { "N/A" }
                    }
                },
                @{Name = 'UpdateId'; Expression = { $_.UpdateIdentity.UpdateId } },
                @{Name = 'RevisionNumber'; Expression = { $_.UpdateIdentity.RevisionNumber } } |
                Sort-Object -Property Date -Descending
        )

        if ($SkipDefenderUpdates.IsPresent) {
            Write-Verbose "Skipping Microsoft Defender updates..."
            $output = $output | Where-Object { $_.Title -notmatch 'Microsoft Defender' }
        }
        if ($SkipDriverUpdates.IsPresent) {
            Write-Verbose "Skipping driver updates..."
            $output = $output | Where-Object { $_.Category -notlike '*Driver*' }
        }

        # Apply First parameter if specified
        if ($First -gt 0) {
            $output = $output | Select-Object -First $First
        }

        Write-Output $output

        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($updateSession) | Out-Null
        Remove-Variable updateSession
    } catch {
        Write-Error "Failed to query Windows Update history: $_"
    }
}
