function Get-SystemInfoInventory {
    <#
.SYNOPSIS
    Collects system information and adds it to SystemInventory.json

.DESCRIPTION
    Gathers OS, hardware, network, security, and application information for golden master images.
    Updates or creates the SystemInfo section in the existing SystemInventory.json file.

.PARAMETER JsonPath
    Path to the SystemInventory.json file. Defaults to C:\ProgramData\SystemInventory\SystemInventory.json

.EXAMPLE
    .\Get-SystemInfoInventory.ps1
    .\Get-SystemInfoInventory.ps1 -JsonPath "C:\Custom\Path\SystemInventory.json"
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$InventoryFilePath = "C:\ProgramData\SystemInventory\SystemInventory.json"
    )

    $ErrorActionPreference = 'Stop'
    $Script:LogFile = Join-Path -Path (Split-Path $InventoryFilePath -Parent) -ChildPath "$(([System.IO.FileInfo]$InventoryFilePath).BaseName).log"

    try {
        Write-Log "Starting system information collection..."

        # Initialize SystemInfo object
        $inventoryResults = @{
            CollectedAt  = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            OS           = @{}
            Hardware     = @{}
            Network      = @{}
            Security     = @{}
            Applications = @{}
        }

        # ===== OS Information =====
        Write-Log "Collecting OS information..."
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem

        $inventoryResults.OS = @{
            Version      = $os.Version
            BuildNumber  = $os.BuildNumber
            Edition      = $os.Caption
            Architecture = $os.OSArchitecture
            Domain       = if ($computerSystem.PartOfDomain) { $computerSystem.Domain } else { "WORKGROUP: $($computerSystem.Workgroup)" }
        }

        # ===== Hardware Information (C: Drive only) =====
        Write-Log "Collecting hardware information..."
        $cDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"

        $inventoryResults.Hardware = @{
            CDrive = @{
                TotalSizeGB = [math]::Round($cDrive.Size / 1GB, 2)
                FreeSpaceGB = [math]::Round($cDrive.FreeSpace / 1GB, 2)
                UsedSpaceGB = [math]::Round(($cDrive.Size - $cDrive.FreeSpace) / 1GB, 2)
                PercentFree = [math]::Round(($cDrive.FreeSpace / $cDrive.Size) * 100, 2)
            }
        }

        # Check for NVIDIA GPU
        Write-Log "Checking for NVIDIA GPU..."
        $nvidiaGPU = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }
        $nvidiaSoftware = Get-Package -Name "NVIDIA Graphics*" -ErrorAction SilentlyContinue | Sort-Object Version | Select-Object -Last 1

        if ($nvidiaGPU) {
            $inventoryResults.Hardware.NvidiaGPU = @{
                Name           = $nvidiaGPU.Name
                DriverVersion  = $nvidiaGPU.DriverVersion
                DriverDate     = $nvidiaGPU.DriverDate.ToString("yyyy-MM-dd")
                VideoProcessor = $nvidiaGPU.VideoProcessor
                AdapterRAM_GB  = if ($nvidiaGPU.AdapterRAM) { [math]::Round($nvidiaGPU.AdapterRAM / 1GB, 2) } else { "N/A" }
            }
            Write-Log "NVIDIA GPU detected: $($nvidiaGPU.Name)"
            if (-not ([string]::IsNullOrEmpty($nvidiaSoftware.Version))) {
                Write-Log "NVIDIA Software Version detected: $($nvidiaSoftware.Version)"
                $nvResults = Get-NvidiaVGpuReleases -Detailed
                $releaseInfo = $nvResults | Where-Object { $_.WindowsVGpuManager -like $nvidiaSoftware.Version }
                if ($releaseInfo) {
                    $inventoryResults.Hardware.NvidiaGPU['SoftwareReleaseBranch'] = $(if ([string]::IsNullOrEmpty($releaseInfo.SoftwareReleaseBranch)) { "N/A" } else { $releaseInfo.SoftwareReleaseBranch })
                    $inventoryResults.Hardware.NvidiaGPU['DriverBranch'] = $(if ([string]::IsNullOrEmpty($releaseInfo.DriverBranch)) { "N/A" } else { $releaseInfo.DriverBranch })
                    $inventoryResults.Hardware.NvidiaGPU['BranchType'] = $(if ([string]::IsNullOrEmpty($releaseInfo.BranchType)) { "N/A" } else { $releaseInfo.BranchType })
                    $inventoryResults.Hardware.NvidiaGPU['ReleaseDate'] = $(if ([string]::IsNullOrEmpty($releaseInfo.ReleaseDate)) { "N/A" } else { $releaseInfo.ReleaseDate })
                    $inventoryResults.Hardware.NvidiaGPU['EOLDate'] = $(if ([string]::IsNullOrEmpty($releaseInfo.EOLDate)) { "N/A" } else { $releaseInfo.EOLDate })
                    $inventoryResults.Hardware.NvidiaGPU['SoftwareVersion'] = $(if ([string]::IsNullOrEmpty($nvidiaGPU.DriverVersion)) { "N/A" } else { $nvidiaSoftware.Name })
                    Write-Log "NVIDIA Software release information added"
                } else {
                    Write-Log "No matching NVIDIA vGPU release information found for version $($nvidiaSoftware.Version)" -Level "WARNING"
                }
            } else {
                Write-Log "No NVIDIA Software package detected"
            }
        } else {
            $inventoryResults.Hardware.NvidiaGPU = $null
            Write-Log "No NVIDIA GPU detected"
        }

        # ===== Network Information =====
        Write-Log "Collecting network information..."
        $networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        $inventoryResults.Network = @{
            Adapters = @()
        }

        foreach ($adapter in $networkAdapters) {
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue |
                Where-Object { $_.AddressFamily -eq 'IPv4' } |
                Select-Object -First 1

            $adapterInfo = @{
                Name        = $adapter.Name
                Description = $adapter.InterfaceDescription
                MACAddress  = $adapter.MacAddress
                Status      = $adapter.Status
                LinkSpeed   = $adapter.LinkSpeed
                IPAddress   = if ($ipConfig) { $ipConfig.IPAddress } else { "N/A" }
            }

            $inventoryResults.Network.Adapters += $adapterInfo
        }
        Write-Log "Found $($networkAdapters.Count) active network adapter(s)"

        # ===== Security Information =====
        Write-Log "Collecting security information..."

        # Windows Defender Status
        try {
            $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
            $inventoryResults.Security.WindowsDefender = @{
                AntivirusEnabled              = $defenderStatus.AntivirusEnabled
                RealTimeProtectionEnabled     = $defenderStatus.RealTimeProtectionEnabled
                AntivirusSignatureLastUpdated = $defenderStatus.AntivirusSignatureLastUpdated.ToString("yyyy-MM-dd HH:mm:ss")
                AntivirusSignatureVersion     = $defenderStatus.AntivirusSignatureVersion
            }
        } catch {
            $inventoryResults.Security.WindowsDefender = @{ Status = "Unable to retrieve" }
            Write-Log "Unable to retrieve Windows Defender status: $_" -Level "WARNING"
        }

        # Firewall Status
        try {
            $DomainProfile = "Disabled"
            $PrivateProfile = "Disabled"
            $PublicProfile = "Disabled"
            $firewallProfiles = Get-NetFirewallProfile
            if (($firewallProfiles | Where-Object { $_.Name -eq 'Domain' }).Enabled) {
                $DomainProfile = "Enabled"
            }
            if (($firewallProfiles | Where-Object { $_.Name -eq 'Private' }).Enabled) {
                $PrivateProfile = "Enabled"
            }
            if (($firewallProfiles | Where-Object { $_.Name -eq 'Public' }).Enabled) {
                $PublicProfile = "Enabled"
            }
            $inventoryResults.Security.Firewall = @{
                DomainProfile  = $DomainProfile
                PrivateProfile = $PrivateProfile
                PublicProfile  = $PublicProfile
            }
        } catch {
            $inventoryResults.Security.Firewall = @{ Status = "Unable to retrieve" }
            Write-Log "Unable to retrieve Firewall status: $_" -Level "WARNING"
            $DomainProfile = "N/A"
            $PrivateProfile = "N/A"
            $PublicProfile = "N/A"
        }

        # TPM Version
        try {
            $tpm = Get-Tpm -ErrorAction SilentlyContinue
            if ($tpm) {
                $tpmInfo = Get-CimInstance -Namespace "Root\CIMv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction SilentlyContinue
                $inventoryResults.Security.TPM = @{
                    Present   = $tpm.TpmPresent
                    Enabled   = $tpm.TpmEnabled
                    Activated = $tpm.TpmActivated
                    Version   = if ($tpmInfo) { "$($tpmInfo.SpecVersion)" } else { "Unknown" }
                }
            } else {
                $inventoryResults.Security.TPM = @{ Present = $false }
            }
        } catch {
            $inventoryResults.Security.TPM = @{ Status = "Unable to retrieve" }
            Write-Log "Unable to retrieve TPM status: $_" -Level "WARNING"
        }

        # ===== Save Inventory =====
        Write-Log "Saving SystemInventory..."

        $inventoryData = @{}
        $Item = "SystemInfo"
        Write-Log "Saving $Item..."
        $inventoryData[$Item] = $inventoryResults
        $inventoryData["$($Item)ReportOrder"] = 1
        $inventoryData["$($Item)LastChanged"] = $inventoryResults.CollectedAt
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
