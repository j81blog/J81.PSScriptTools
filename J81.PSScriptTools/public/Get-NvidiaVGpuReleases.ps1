<#
    .SYNOPSIS
        Retrieves NVIDIA vGPU software release information (optimized version).

    .DESCRIPTION
        Fetches and parses the NVIDIA vGPU documentation page once, extracts all release
        information (both summary and detailed versions), and returns filtered results
        based on parameters. Much more efficient than making multiple web requests.

    .PARAMETER Latest
        Returns only the latest release in each branch (summary view).

    .PARAMETER MajorVersion
        Filters results to a specific major version (e.g., 19, 18, 16).

    .PARAMETER DriverBranch
        Filters results to a specific driver branch (e.g., 'R580', 'R570').

    .PARAMETER Category
        Filters results by category: 'Active' or 'Older'.

    .PARAMETER Detailed
        Returns detailed version information for all sub-releases (e.g., 19.0, 19.1, 19.2).
        Without this switch, only summary information is returned.

    .EXAMPLE
        Get-NvidiaVGpuReleases
        Returns summary of all vGPU branches

    .EXAMPLE
        Get-NvidiaVGpuReleases -MajorVersion 19 -Detailed
        Returns all detailed 19.x releases

    .EXAMPLE
        Get-NvidiaVGpuReleases -Category Active
        Returns only active releases (summary)

    .EXAMPLE
        Get-NvidiaVGpuReleases -DriverBranch R580 -Detailed
        Returns all detailed releases for R580 driver branch

    .EXAMPLE
        Get-NvidiaVGpuReleases -Category Active -Detailed
        Returns detailed version info for all active branches

    .OUTPUTS
        PSCustomObject with comprehensive release information

    .NOTES
        Function Name   : Set-GistContent
        Version         : v2025.817.1705
        Author          : John Billekens Consultancy

#>

function Get-NvidiaVGpuReleases {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Latest,

        [Parameter(Mandatory = $false)]
        [int]$MajorVersion,

        [Parameter(Mandatory = $false)]
        [string]$DriverBranch,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Active', 'Older')]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    try {
        # Fetch all data (uses cache if available)
        $allData = Get-AllVGpuReleaseData

        # Determine which dataset to use
        if ($Detailed) {
            $results = $allData.Detailed
            Write-Verbose "Using detailed release data"
        } else {
            $results = $allData.Summary
            Write-Verbose "Using summary release data"
        }

        # Apply filters
        if ($MajorVersion) {
            $results = $results | Where-Object { $_.MajorVersion -eq $MajorVersion.ToString() }
            Write-Verbose "Filtered to MajorVersion: $MajorVersion"
        }

        if ($DriverBranch) {
            $results = $results | Where-Object { $_.DriverBranch -eq $DriverBranch }
            Write-Verbose "Filtered to DriverBranch: $DriverBranch"
        }

        if ($Category) {
            $results = $results | Where-Object { $_.Category -eq $Category }
            Write-Verbose "Filtered to Category: $Category"
        }

        if ($Latest) {
            # If Latest is specified with Detailed, return only the latest version per branch
            if ($Detailed) {
                $results = $results | Group-Object MajorVersion | ForEach-Object {
                    $_.Group | Sort-Object Version -Descending | Select-Object -First 1
                }
                Write-Verbose "Filtered to latest version per branch (detailed)"
            }
            # For summary, Latest doesn't change anything (already shows latest)
        }

        Write-Verbose "Returning $($results.Count) result(s)"
        return $results

    } catch {
        Write-Error "Error executing Get-NvidiaVGpuReleases: $_"
        throw
    }
}

# When script is run directly (not dot-sourced), execute with passed parameters
if ($MyInvocation.InvocationName -ne '.') {
    Get-NvidiaVGpuReleases @PSBoundParameters
}

<#
.NOTES
    Author: Generated for Golden Master Image Documentation
    Version: 2.0 (Optimized)
    Last Updated: 2025-11-08

    Performance Improvements:
    - Single web request instead of multiple
    - Results cached for 60 minutes
    - All parsing done once upfront
    - Filtering done in-memory with PowerShell

    Usage Examples:

    # Get summary of all releases (fast - uses summary data)
    Get-NvidiaVGpuReleases

    # Get only active releases
    Get-NvidiaVGpuReleases -Category Active

    # Get all detailed versions for vGPU 19
    Get-NvidiaVGpuReleases -MajorVersion 19 -Detailed

    # Get latest detailed version for each active branch
    Get-NvidiaVGpuReleases -Category Active -Detailed -Latest

    # Get all R580 releases with full details
    Get-NvidiaVGpuReleases -DriverBranch R580 -Detailed

    # Combine filters: Active LTS releases with details
    Get-NvidiaVGpuReleases -Category Active -Detailed |
        Where-Object { $_.BranchType -match 'Long-Term Support' }

    # Export to CSV
    Get-NvidiaVGpuReleases -Category Active |
        Export-Csv "Active-vGPU-Summary.csv" -NoTypeInformation

    # Compare all versions of vGPU 19
    Get-NvidiaVGpuReleases -MajorVersion 19 -Detailed |
        Format-Table Version, LinuxDriver, WindowsDriver, ReleaseDate -AutoSize

    # Get cache info
    Write-Host "Cache age: $((Get-Date) - $script:NVCacheTimestamp)"
    Write-Host "Cached summary count: $($script:CachedVGpuData.Summary.Count)"
    Write-Host "Cached detailed count: $($script:CachedVGpuData.Detailed.Count)"

    # Clear cache to force fresh fetch
    $script:NVCachedVGpuData = $null
#>
