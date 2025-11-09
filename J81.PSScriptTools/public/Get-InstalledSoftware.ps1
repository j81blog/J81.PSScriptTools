function Get-InstalledSoftware {
    [CmdletBinding()]
    param()
    $msiProducts = try { @(Get-MsiProducts) } catch { @() }
    $packages = Get-Package -IncludeWindowsInstaller -AllVersions -IncludeSystemComponent | Select-Object *
    $results = @()
    $versionRegex = '(\s?-?\s?\d{1,5}(\.\d{1,6}){1,3})'
    foreach ($item in $packages) {
        if ($productcode = $item.FastPackageReference.Split('\')[-1]) {
            $msiProduct = $msiProducts | Where-Object { $_.ProductCode -like $productcode }
        } else {
            $msiProduct = try { $msiProducts | Where-Object { $_.ProductName -eq $item.Name } } catch { $null }
        }
        $meta = ([xml]$item.SwidTagText).SoftwareIdentity.Meta
        $results += $([PSCustomObject]@{
                ProductName          = $(try { "$($item.Name -replace $versionRegex, $null)".Trim() } catch { $item.Name })
                ProductNameOriginal  = $( $item.Name )
                InstalledProductName = $(try { $meta.DisplayName } catch { "null" })
                VersionString        = $(try { "$($meta.DisplayVersion)".Trim() } catch { "null" })
                InstallDate          = $(try { [datetime]::ParseExact($($meta.InstallDate), "yyyyMMdd", $null).ToString("yyyy-MM-dd") } catch { $meta.InstallDate })
                ProductVersion       = "$($item.Version)".Trim()
                Manufacturer         = $(try { $meta.Publisher } catch { "null" })
                ProductCode          = $(try { if ($msiProduct.ProductCode -is [array]) { $msiProduct.ProductCode -join ',' } else { $msiProduct.ProductCode } } catch { "null" })
                PackageName          = $(try { $msiProduct.PackageName } catch { "null" })
            })

    }
    Write-Output $($results | Sort-Object -Property ProductName | Select-Object -Property * -Unique)
}