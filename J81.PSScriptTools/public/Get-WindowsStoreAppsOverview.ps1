function Get-WindowsStoreAppsOverview {
    <#
    .SYNOPSIS
        Get an inventory of all Windows Store and MSIX apps available on a Windows machine.

    .DESCRIPTION
        This function inventories Windows Store apps and MSIX packages available on Windows 10/11
        and Windows Server 2016+. It can enumerate apps for all users, current user only, and
        provisioned apps (staged for new users). The function is designed to run in unattended
        deployments, including under SYSTEM context, to generate deployment reports.

    .PARAMETER Scope
        Specifies the scope of apps to inventory:
        - 'AllUsers': All apps installed for any user on the system (default)
        - 'CurrentUser': Apps installed only for the current user
        - 'Provisioned': Apps provisioned for new user accounts

    .PARAMETER Name
        Filter apps by name pattern. Supports wildcards.

    .PARAMETER Publisher
        Filter apps by publisher pattern. Supports wildcards.

    .PARAMETER SignatureKind
        Filter apps by signature type:
        - 'Store': Microsoft Store apps
        - 'System': System apps
        - 'Developer': Developer-signed apps
        - 'Enterprise': Enterprise-signed apps

    .PARAMETER IncludeFrameworks
        Include framework packages in the results. By default, frameworks are excluded.

    .PARAMETER IncludeNonRemovable
        Include non-removable system apps in the results. By default, non-removable apps are excluded.

    .PARAMETER AsJSON
        If this switch is present, the output will be in JSON format.

    .EXAMPLE
        Get-WindowsStoreAppsOverview
        Returns all apps installed for all users and provisioned apps on the system.

    .EXAMPLE
        Get-WindowsStoreAppsOverview -Scope CurrentUser
        Returns apps installed only for the current user.

    .EXAMPLE
        Get-WindowsStoreAppsOverview -Name "*Microsoft*" -AsJSON
        Returns all Microsoft apps in JSON format.

    .EXAMPLE
        Get-WindowsStoreAppsOverview -SignatureKind Store | Export-Csv -Path "StoreApps.csv"
        Exports all Microsoft Store apps to a CSV file.

    .EXAMPLE
        Get-WindowsStoreAppsOverview -Scope Provisioned
        Returns only apps that are provisioned for new users.

    .EXAMPLE
        Get-WindowsStoreAppsOverview -IncludeNonRemovable -IncludeFrameworks
        Returns all apps including system apps and frameworks that are normally excluded.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Returns an array of custom objects containing detailed app information.

    .NOTES
        Function Name : Get-WindowsStoreAppsOverview
        Version       : v1.0.0
        Author        : John Billekens
        Requires      : PowerShell 5.1+, Windows 10/11 or Windows Server 2016+

    .LINK
        Get-AppxPackage
        Get-AppxProvisionedPackage
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('AllUsers', 'CurrentUser', 'Provisioned')]
        [string]$Scope = 'AllUsers',

        [Parameter()]
        [string]$Name,

        [Parameter()]
        [string]$Publisher,

        [Parameter()]
        [ValidateSet('Store', 'System', 'Developer', 'Enterprise')]
        [string]$SignatureKind,

        [Parameter()]
        [switch]$IncludeFrameworks,

        [Parameter()]
        [switch]$IncludeNonRemovable,

        [Parameter()]
        [switch]$AsJSON
    )

    begin {
        Write-Log -Message "Starting Windows Store Apps inventory (Scope: $Scope)" -Level "INFO"
        $results = @()
        $errorCount = 0
    }

    process {
        try {
            # Gather installed packages based on scope
            if ($Scope -eq 'AllUsers') {
                Write-Log -Message "Gathering apps for all users..." -Level "INFO"

                # Get all user-installed packages
                try {
                    $installedPackages = Get-AppxPackage -AllUsers -ErrorAction Stop
                    Write-Log -Message "Found $($installedPackages.Count) installed packages for all users" -Level "INFO"
                } catch {
                    Write-Log -Message "Error gathering AllUsers packages: $($_.Exception.Message)" -Level "ERROR"
                    $installedPackages = @()
                    $errorCount++
                }

                # Get provisioned packages
                try {
                    $provisionedPackages = Get-AppxProvisionedPackage -Online -ErrorAction Stop
                    Write-Log -Message "Found $($provisionedPackages.Count) provisioned packages" -Level "INFO"
                } catch {
                    Write-Log -Message "Error gathering provisioned packages: $($_.Exception.Message)" -Level "ERROR"
                    $provisionedPackages = @()
                    $errorCount++
                }

                # Process installed packages
                foreach ($package in $installedPackages) {
                    try {
                        # Check if also provisioned
                        $isProvisioned = $provisionedPackages.DisplayName -contains $package.Name

                        # Use helper function to get enhanced details
                        $appObject = Get-EnhancedPackageDetails -Package $package -AppType 'Installed' -ScopeValue 'AllUsers' -IsProvisionedValue $isProvisioned

                        $results += $appObject
                    } catch {
                        Write-Log -Message "Error processing package $($package.Name): $($_.Exception.Message)" -Level "ERROR"
                        $errorCount++
                        continue
                    }
                }

                # Process provisioned packages (only those not already in installed list)
                foreach ($package in $provisionedPackages) {
                    try {
                        # Skip if already processed as installed
                        if ($installedPackages.Name -contains $package.DisplayName) {
                            continue
                        }

                        # Create a compatible package object for provisioned apps
                        $provPackageObj = [PSCustomObject]@{
                            Name              = $package.DisplayName
                            Publisher         = "N/A"
                            PublisherId       = $null
                            Version           = $package.Version
                            Architecture      = $package.Architecture
                            ResourceId        = $null
                            PackageFullName   = $package.PackageName
                            PackageFamilyName = "N/A"
                            InstallLocation   = $package.InstallLocation
                            IsFramework       = $false
                            IsBundle          = $false
                            IsDevelopmentMode = $false
                            IsResourcePackage = $false
                            NonRemovable      = $false
                            SignatureKind     = $null
                            Status            = "Provisioned"
                            PackageUserInformation = $null
                            Dependencies      = $null
                        }

                        # Use helper function to get enhanced details
                        $appObject = Get-EnhancedPackageDetails -Package $provPackageObj -AppType 'Provisioned' -ScopeValue 'System' -IsProvisionedValue $true

                        $results += $appObject
                    } catch {
                        Write-Log -Message "Error processing provisioned package $($package.DisplayName): $($_.Exception.Message)" -Level "ERROR"
                        $errorCount++
                        continue
                    }
                }

            } elseif ($Scope -eq 'CurrentUser') {
                Write-Log -Message "Gathering apps for current user..." -Level "INFO"

                try {
                    $installedPackages = Get-AppxPackage -ErrorAction Stop
                    Write-Log -Message "Found $($installedPackages.Count) installed packages for current user" -Level "INFO"

                    foreach ($package in $installedPackages) {
                        try {
                            # Use helper function to get enhanced details
                            $appObject = Get-EnhancedPackageDetails -Package $package -AppType 'Installed' -ScopeValue 'CurrentUser' -IsProvisionedValue $false

                            $results += $appObject
                        } catch {
                            Write-Log -Message "Error processing package $($package.Name): $($_.Exception.Message)" -Level "ERROR"
                            $errorCount++
                            continue
                        }
                    }
                } catch {
                    Write-Log -Message "Error gathering CurrentUser packages: $($_.Exception.Message)" -Level "ERROR"
                    $errorCount++
                }

            } elseif ($Scope -eq 'Provisioned') {
                Write-Log -Message "Gathering provisioned apps..." -Level "INFO"

                try {
                    $provisionedPackages = Get-AppxProvisionedPackage -Online -ErrorAction Stop
                    Write-Log -Message "Found $($provisionedPackages.Count) provisioned packages" -Level "INFO"

                    foreach ($package in $provisionedPackages) {
                        try {
                            # Create a compatible package object for provisioned apps
                            $provPackageObj = [PSCustomObject]@{
                                Name              = $package.DisplayName
                                Publisher         = "N/A"
                                PublisherId       = $null
                                Version           = $package.Version
                                Architecture      = $package.Architecture
                                ResourceId        = $null
                                PackageFullName   = $package.PackageName
                                PackageFamilyName = "N/A"
                                InstallLocation   = $package.InstallLocation
                                IsFramework       = $false
                                IsBundle          = $false
                                IsDevelopmentMode = $false
                                IsResourcePackage = $false
                                NonRemovable      = $false
                                SignatureKind     = $null
                                Status            = "Provisioned"
                                PackageUserInformation = $null
                                Dependencies      = $null
                            }

                            # Use helper function to get enhanced details
                            $appObject = Get-EnhancedPackageDetails -Package $provPackageObj -AppType 'Provisioned' -ScopeValue 'System' -IsProvisionedValue $true

                            $results += $appObject
                        } catch {
                            Write-Log -Message "Error processing provisioned package $($package.DisplayName): $($_.Exception.Message)" -Level "ERROR"
                            $errorCount++
                            continue
                        }
                    }
                } catch {
                    Write-Log -Message "Error gathering provisioned packages: $($_.Exception.Message)" -Level "ERROR"
                    $errorCount++
                }
            }

            # Apply filters
            if ($results.Count -gt 0) {
                Write-Log -Message "Applying filters to $($results.Count) apps..." -Level "INFO"

                # Filter by Name
                if ($PSBoundParameters.ContainsKey('Name')) {
                    $results = $results | Where-Object { $_.Name -like $Name }
                    Write-Log -Message "After Name filter: $($results.Count) apps" -Level "INFO"
                }

                # Filter by Publisher
                if ($PSBoundParameters.ContainsKey('Publisher')) {
                    $results = $results | Where-Object { $_.Publisher -like $Publisher }
                    Write-Log -Message "After Publisher filter: $($results.Count) apps" -Level "INFO"
                }

                # Filter by SignatureKind
                if ($PSBoundParameters.ContainsKey('SignatureKind')) {
                    $results = $results | Where-Object { $_.SignatureKind -eq $SignatureKind }
                    Write-Log -Message "After SignatureKind filter: $($results.Count) apps" -Level "INFO"
                }

                # Exclude frameworks unless explicitly requested
                if (-not $IncludeFrameworks) {
                    $results = $results | Where-Object { -not $_.IsFramework }
                    Write-Log -Message "After excluding frameworks: $($results.Count) apps" -Level "INFO"
                }

                # Exclude non-removable apps unless explicitly requested
                if (-not $IncludeNonRemovable) {
                    $results = $results | Where-Object { -not $_.NonRemovable }
                    Write-Log -Message "After excluding non-removable apps: $($results.Count) apps" -Level "INFO"
                }
            }

        } catch {
            Write-Log -Message "Unexpected error during inventory: $($_.Exception.Message)" -Level "ERROR"
            $errorCount++
        }
    }

    end {
        Write-Log -Message "Inventory complete. Found $($results.Count) apps with $errorCount errors" -Level "INFO"

        if ($AsJSON) {
            return ($results | ConvertTo-Json -Depth 3)
        } else {
            return $results
        }
    }
}
