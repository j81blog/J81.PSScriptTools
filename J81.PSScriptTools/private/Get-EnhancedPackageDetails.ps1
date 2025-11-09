function Get-EnhancedPackageDetails {
    param($Package, $AppType, $ScopeValue, $IsProvisionedValue = $false)

    try {
        # Initialize with package data
        $applicationDisplayName = $Package.Name
        $publisherDisplayName = $Package.Publisher

        # Try to read AppxManifest.xml for better display names
        try {
            $installLocation = "$($Package.InstallLocation)"
            $installLocation = $installLocation -replace '^%SYSTEMDRIVE%', $env:SystemDrive

            if (-not [string]::IsNullOrWhiteSpace($installLocation)) {
                $manifestFilename = Join-Path -Path $installLocation -ChildPath "AppxManifest.xml"

                if (Test-Path -Path $manifestFilename) {
                    Write-Verbose "Processing manifest for $($Package.Name) at `"$manifestFilename`""
                    [xml]$manifest = Get-Content -Path $manifestFilename -ErrorAction SilentlyContinue

                    if ($null -ne $manifest) {
                        # Handle Bundle vs Package manifests
                        if ($manifest | Get-Member -Name Bundle -ErrorAction SilentlyContinue) {
                            $applicationDisplayName = $manifest.Bundle.Identity.Name
                            $publisherDisplayName = $manifest.Bundle.Identity.Publisher
                        } elseif ($manifest | Get-Member -Name Package -ErrorAction SilentlyContinue) {
                            $applicationDisplayName = $manifest.Package.Identity.Name
                            $publisherDisplayName = $manifest.Package.Identity.Publisher
                        } else {
                            Write-Verbose "Warning: Unknown manifest structure for $($Package.Name)"
                        }
                    }
                } else {
                    Write-Verbose "Manifest not found for $($Package.Name) at `"$manifestFilename`""
                }
            }
        } catch {
            Write-Verbose "Could not read manifest for $($Package.Name): $($_.Exception.Message)"
        }

        # Clean up the display name
        $applicationDisplayName = $applicationDisplayName | Split-NameOnCapital -DotsToSpaces
        $applicationDisplayName = $applicationDisplayName -replace "Language Experience Pack", "Language Experience Pack "

        # Clean up publisher name
        if ($publisherDisplayName -like "CN=*") {
            $publisherDisplayName = "$($publisherDisplayName.Split("=")[1])".Split(",")[0]
        }

        # If publisher is a GUID, use the first word of the app name
        if ($publisherDisplayName | Test-IsGUID) {
            $publisherDisplayName = $applicationDisplayName.Split(" ")[0]
        }

        # Convert architecture if needed
        $architecture = $Package.Architecture
        if ($architecture -is [uint32] -or $architecture -is [Windows.System.ProcessorArchitecture]) {
            $architecture = Convert-AppxArchitecture -Value $architecture
        } else {
            $architecture = $architecture.ToString()
        }

        # Build the enhanced object
        return [PSCustomObject]@{
            Name                   = $Package.Name
            DisplayName            = $applicationDisplayName
            Publisher              = $publisherDisplayName
            PublisherId            = if ($Package.PublisherId) { $Package.PublisherId } else { "N/A" }
            Version                = if ($Package.Version) { $Package.Version.ToString() } else { "N/A" }
            Architecture           = $architecture
            ResourceId             = if ($Package.ResourceId) { $Package.ResourceId } else { "N/A" }
            PackageFullName        = $Package.PackageFullName
            PackageFamilyName      = $Package.PackageFamilyName
            InstallLocation        = $Package.InstallLocation
            IsFramework            = if ($null -ne $Package.IsFramework) { $Package.IsFramework } else { $false }
            IsBundle               = if ($null -ne $Package.IsBundle) { $Package.IsBundle } else { $false }
            IsDevelopmentMode      = if ($null -ne $Package.IsDevelopmentMode) { $Package.IsDevelopmentMode } else { $false }
            IsResourcePackage      = if ($null -ne $Package.IsResourcePackage) { $Package.IsResourcePackage } else { $false }
            NonRemovable           = if ($null -ne $Package.NonRemovable) { $Package.NonRemovable } else { $false }
            SignatureKind          = if ($Package.SignatureKind) { $Package.SignatureKind } else { "N/A" }
            Status                 = if ($Package.Status) { $Package.Status } else { "N/A" }
            PackageUserInformation = if ($Package.PackageUserInformation) { $Package.PackageUserInformation } else { "N/A" }
            Dependencies           = if ($Package.Dependencies) { ($Package.Dependencies | ForEach-Object { $_.PackageFullName }) -join '; ' } else { "N/A" }
            AppType                = $AppType
            Scope                  = $ScopeValue
            IsProvisioned          = $IsProvisionedValue
        }
    } catch {
        Write-Log -Message "Error creating enhanced details for $($Package.Name): $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}
