function Get-AllVGpuReleaseData {
    <#
    .SYNOPSIS
        Internal function that fetches and parses ALL vGPU release data once.
    #>
    [CmdletBinding()]
    param()

    Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue

    # Check if we have valid cached data
    if ($script:NVCachedVGpuData -and $script:NVCacheTimestamp) {
        $cacheAge = (Get-Date) - $script:NVCacheTimestamp
        if ($cacheAge.TotalMinutes -lt $script:NVCacheExpiryMinutes) {
            Write-Verbose "Using cached vGPU data (age: $([math]::Round($cacheAge.TotalMinutes, 1)) minutes)"
            return $script:CachedVGpuData
        } else {
            Write-Verbose "Cache expired, fetching fresh data..."
        }
    }

    try {
        Write-Verbose "Fetching NVIDIA vGPU documentation from web..."

        $url = "https://docs.nvidia.com/vgpu/"
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
        $html = $response.Content

        Write-Verbose "Parsing HTML content..."

        # Data structure to hold all releases
        $allData = @{
            Summary  = @()
            Detailed = @()
        }

        # ===== PARSE SUMMARY TABLE =====
        Write-Verbose "Parsing summary release table..."

        $tableMatches = [regex]::Matches($html, '(?s)<table[^>]*>(.*?)</table>')

        foreach ($tableMatch in $tableMatches) {
            $tableHtml = $tableMatch.Value

            # Only process summary tables with vGPU Software Release Branch
            if ($tableHtml -notmatch 'vGPU Software Release Branch|Driver Branch') {
                continue
            }

            # Skip detailed version tables (they have different headers)
            if ($tableHtml -match 'Linux vGPU Manager|Windows vGPU Manager') {
                continue
            }

            $rowMatches = [regex]::Matches($tableHtml, '(?s)<tr[^>]*>(.*?)</tr>')
            $isFirstRow = $true

            foreach ($rowMatch in $rowMatches) {
                $rowHtml = $rowMatch.Value

                if ($isFirstRow) {
                    $isFirstRow = $false
                    if ($rowHtml -match '<th[^>]*>') {
                        continue
                    }
                }

                $cellMatches = [regex]::Matches($rowHtml, '(?s)<td[^>]*>(.*?)</td>')
                if ($cellMatches.Count -lt 6) { continue }

                $cells = @()
                foreach ($cellMatch in $cellMatches) {
                    $cellHtml = $cellMatch.Groups[1].Value
                    $cellText = $cellHtml -replace '<[^>]+>', ''
                    $cellText = [System.Web.HttpUtility]::HtmlDecode($cellText)
                    $cellText = $cellText.Trim() -replace '\s+', ' '
                    $cells += $cellText
                }

                if ([string]::IsNullOrWhiteSpace($cells[0])) { continue }

                # Extract major version
                $majorVer = $null
                if ($cells[0] -match 'vGPU\s+(\d+)') {
                    $majorVer = $matches[1]
                } elseif ($cells[0] -match 'GRID\s+(\d+)') {
                    $majorVer = "GRID$($matches[1])"
                }

                # Determine category
                $cat = if ($cells[2] -match '^EOL') { 'Older' }
                elseif ($cells[2] -match 'Long-Term Support|^Production$') { 'Active' }
                else { 'Unknown' }

                $summary = [PSCustomObject]@{
                    Category              = $cat
                    SoftwareReleaseBranch = $cells[0]
                    MajorVersion          = $majorVer
                    DriverBranch          = $cells[1]
                    BranchType            = $cells[2]
                    LatestRelease         = $cells[3]
                    ReleaseDate           = $cells[4]
                    EOLDate               = $cells[5]
                }

                $allData.Summary += $summary
            }
        }

        Write-Verbose "Found $($allData.Summary.Count) release branches"

        # ===== PARSE DETAILED VERSION TABLES =====
        Write-Verbose "Parsing detailed version tables..."

        foreach ($branch in $allData.Summary) {
            $versionNum = $branch.MajorVersion

            # Try to find detailed release table for this version
            $patterns = @(
                "(?si)vGPU\s+Software\s+$versionNum\s+Releases.*?<table[^>]*>(.*?)</table>",
                "(?si)NVIDIA\s+vGPU\s+$versionNum\s+Releases.*?<table[^>]*>(.*?)</table>",
                "(?si)vGPU\s+$versionNum\s+Releases.*?<table[^>]*>(.*?)</table>",
                "(?si)GRID\s+$versionNum\s+Software\s+Releases.*?<table[^>]*>(.*?)</table>"
            )

            $detailMatch = $null
            foreach ($pattern in $patterns) {
                $match = [regex]::Match($html, $pattern)
                if ($match.Success) {
                    $detailMatch = $match
                    break
                }
            }

            if (-not $detailMatch) {
                Write-Verbose "No detailed table found for version $versionNum"
                continue
            }

            $detailTableHtml = $detailMatch.Value

            # Verify this is a detailed version table
            if ($detailTableHtml -notmatch 'Linux.*vGPU Manager|Windows.*vGPU Manager|Linux.*Driver|Windows.*Driver') {
                Write-Verbose "Table for version $versionNum doesn't have detailed columns"
                continue
            }

            # Parse detailed table rows
            $rowMatches = [regex]::Matches($detailTableHtml, '(?s)<tr[^>]*>(.*?)</tr>')
            $isFirstRow = $true

            foreach ($rowMatch in $rowMatches) {
                $rowHtml = $rowMatch.Value

                if ($isFirstRow) {
                    $isFirstRow = $false
                    if ($rowHtml -match '<th[^>]*>') {
                        continue
                    }
                }

                $cellMatches = [regex]::Matches($rowHtml, '(?s)<td[^>]*>(.*?)</td>')
                if ($cellMatches.Count -lt 5) { continue }

                $cells = @()
                foreach ($cellMatch in $cellMatches) {
                    $cellHtml = $cellMatch.Groups[1].Value
                    $cellText = $cellHtml -replace '<[^>]+>', ''
                    $cellText = [System.Web.HttpUtility]::HtmlDecode($cellText)
                    $cellText = $cellText.Trim() -replace '\s+', ' '
                    $cells += $cellText
                }

                if ([string]::IsNullOrWhiteSpace($cells[0])) { continue }

                $detailed = [PSCustomObject]@{
                    Category              = $branch.Category
                    SoftwareReleaseBranch = $branch.SoftwareReleaseBranch
                    MajorVersion          = $branch.MajorVersion
                    DriverBranch          = $branch.DriverBranch
                    BranchType            = $branch.BranchType
                    Version               = $cells[0]
                    LinuxVGpuManager      = if ($cells.Count -gt 1) { $cells[1] } else { 'N/A' }
                    WindowsVGpuManager    = if ($cells.Count -gt 2) { $cells[2] } else { 'N/A' }
                    LinuxDriver           = if ($cells.Count -gt 3) { $cells[3] } else { 'N/A' }
                    WindowsDriver         = if ($cells.Count -gt 4) { $cells[4] } else { 'N/A' }
                    ReleaseDate           = if ($cells.Count -gt 5) { $cells[5] } else { $branch.ReleaseDate }
                    EOLDate               = $branch.EOLDate
                }

                $allData.Detailed += $detailed
            }
        }

        Write-Verbose "Found $($allData.Detailed.Count) detailed release version(s)"

        # Cache the results
        $script:NVCachedVGpuData = $allData
        $script:NVCacheTimestamp = Get-Date

        return $allData

    } catch {
        Write-Error "Failed to fetch and parse vGPU release data: $_"
        throw
    }
}