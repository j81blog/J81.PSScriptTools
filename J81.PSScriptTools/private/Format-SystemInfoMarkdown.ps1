function Format-SystemInfoMarkdown {
    param($SystemInfo)

    $md = ""

    if (-not $SystemInfo) {
        return "> System information not available`n`n"
    }

    # OS Information
    $md += "### Operating System`n`n"
    $md += "| Property | Value |`n"
    $md += "|----------|-------|`n"
    $md += "| **Edition** | $($SystemInfo.OS.Edition) |`n"
    $md += "| **Version** | $($SystemInfo.OS.Version) |`n"
    $md += "| **Build Number** | $($SystemInfo.OS.BuildNumber) |`n"
    $md += "| **Architecture** | $($SystemInfo.OS.Architecture) |`n"
    $md += "| **Domain** | $($SystemInfo.OS.Domain) |`n`n"

    # Hardware Information
    $md += "### Hardware`n`n"
    $md += "| Property | Value |`n"
    $md += "|----------|-------|`n"
    $md += "| **C: Drive Total** | $($SystemInfo.Hardware.CDrive.TotalSizeGB) GB |`n"
    $md += "| **C: Drive Used** | $($SystemInfo.Hardware.CDrive.UsedSpaceGB) GB |`n"
    $md += "| **C: Drive Free** | $($SystemInfo.Hardware.CDrive.FreeSpaceGB) GB ($($SystemInfo.Hardware.CDrive.PercentFree)%) |`n"

    if ($SystemInfo.Hardware.NvidiaGPU) {
        $md += "| **NVIDIA GPU** | $($SystemInfo.Hardware.NvidiaGPU.Name) |`n"
        $md += "| **GPU Memory** | $($SystemInfo.Hardware.NvidiaGPU.AdapterRAM_GB) GB |`n"
        if ($SystemInfo.Hardware.NvidiaGPU.DriverBranch) {
            $md += "| **GPU Software/Driver Version** | $($SystemInfo.Hardware.NvidiaGPU.SoftwareVersion) |`n"
            $md += "| **GPU Software Release Branch** | $($SystemInfo.Hardware.NvidiaGPU.SoftwareReleaseBranch) |`n"
            $md += "| **GPU Driver Branch** | $($SystemInfo.Hardware.NvidiaGPU.DriverBranch) |`n"
            $md += "| **Software Release** | $($SystemInfo.Hardware.NvidiaGPU.BranchType) |`n"
            $md += "| **Release Date** | $($SystemInfo.Hardware.NvidiaGPU.ReleaseDate) |`n"
            $md += "| **EOL Date** | $($SystemInfo.Hardware.NvidiaGPU.EOLDate) |`n"
        }
    }
    $md += "`n"

    # Network Information
    $md += "### Network Adapters`n`n"
    if ($SystemInfo.Network.Adapters -and $SystemInfo.Network.Adapters.Count -gt 0) {
        $md += "| Name | Description | MAC Address | IP Address | Link Speed |`n"
        $md += "|------|-------------|-------------|------------|------------|`n"
        foreach ($adapter in $SystemInfo.Network.Adapters) {
            $md += "| $($adapter.Name) | $($adapter.Description) | $($adapter.MACAddress) | $($adapter.IPAddress) | $($adapter.LinkSpeed) |`n"
        }
    } else {
        $md += "> No network adapter information available`n"
    }
    $md += "`n"

    # Security Information
    $md += "### Security`n`n"
    $md += "| Property | Value |`n"
    $md += "|----------|-------|`n"

    if ($SystemInfo.Security.WindowsDefender) {
        $md += "| **Windows Defender Enabled** | $($SystemInfo.Security.WindowsDefender.AntivirusEnabled) |`n"
        $md += "| **Real-Time Protection** | $($SystemInfo.Security.WindowsDefender.RealTimeProtectionEnabled) |`n"
        if ($SystemInfo.Security.WindowsDefender.AntivirusSignatureVersion) {
            $md += "| **Signature Version** | $($SystemInfo.Security.WindowsDefender.AntivirusSignatureVersion) |`n"
        }
    }

    if ($SystemInfo.Security.Firewall) {
        $md += "| **Firewall (Domain)** | $($SystemInfo.Security.Firewall.DomainProfile) |`n"
        $md += "| **Firewall (Private)** | $($SystemInfo.Security.Firewall.PrivateProfile) |`n"
        $md += "| **Firewall (Public)** | $($SystemInfo.Security.Firewall.PublicProfile) |`n"
    }

    if ($SystemInfo.Security.TPM) {
        $md += "| **TPM Present** | $($SystemInfo.Security.TPM.Present) |`n"
        if ($SystemInfo.Security.TPM.Version) {
            $md += "| **TPM Version** | $($SystemInfo.Security.TPM.Version) |`n"
        }
    }
    $md += "`n"

    return $md
}