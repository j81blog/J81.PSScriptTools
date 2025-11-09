function Get-MsiProducts {
    [CmdletBinding()]
    param()
    $Installer = New-Object -ComObject WindowsInstaller.Installer
    $Type = $Installer.GetType()
    $Products = $Type.InvokeMember('Products', [System.Reflection.BindingFlags]::GetProperty, $null, $Installer, $null)
    $MsiProducts = foreach ($Product in $Products) {
        try {
            $MsiProduct = New-Object -TypeName PSObject -Property @{
                ProductCode = $Product
            }
            $MsiProperties = @('Language', 'ProductName', 'PackageCode', 'Transforms', 'AssignmentType', 'PackageName', 'InstalledProductName', 'VersionString', 'RegCompany', 'RegOwner', 'ProductID', 'ProductIcon', 'InstallLocation', 'InstallSource', 'InstallDate', 'Publisher', 'LocalPackage', 'HelpLink', 'HelpTelephone', 'URLInfoAbout', 'URLUpdateInfo')
            foreach ($MsiProperty in $MsiProperties) {
                $MsiProduct | Add-Member -MemberType NoteProperty -Name $MsiProperty -Value $Type.InvokeMember('ProductInfo', [System.Reflection.BindingFlags]::GetProperty, $null, $Installer, @($Product, $MsiProperty))
            }
            $MsiProduct | Add-Member -MemberType ScriptProperty -Name 'ProductVersion' -Value { $this.VersionString }
            $MsiProduct | Add-Member -MemberType ScriptProperty -Name 'Manufacturer' -Value { $this.Publisher }
            $MsiProduct.InstallDate = try { [datetime]::ParseExact($MsiProduct.InstallDate, "yyyyMMdd", $null).ToString("yyyy-MM-dd") } catch { $MsiProduct.InstallDate }

            Write-Output $MsiProduct
        } catch [System.Exception] {
            Write-Warning -Message "Failed to get product information for product code '$Product': $_ $($_.Exception.Message)"
        }
    }
    $MsiProducts | Sort-Object ProductName
}
