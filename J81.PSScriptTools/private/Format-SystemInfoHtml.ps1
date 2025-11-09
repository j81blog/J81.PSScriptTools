function Format-SystemInfoHtml {
    param($SystemInfo)

    $html = ""

    if (-not $SystemInfo) {
        return "<p><em>System information not available</em></p>"
    }

    # OS Information
    $html += @"
<div class="section">
    <h3>Operating System</h3>
    <table class="info-table">
        <tr><th>Edition</th><td>$($SystemInfo.OS.Edition)</td></tr>
        <tr><th>Version</th><td>$($SystemInfo.OS.Version)</td></tr>
        <tr><th>Build Number</th><td>$($SystemInfo.OS.BuildNumber)</td></tr>
        <tr><th>Architecture</th><td>$($SystemInfo.OS.Architecture)</td></tr>
        <tr><th>Domain</th><td>$($SystemInfo.OS.Domain)</td></tr>
    </table>
</div>

"@

    # Hardware Information
    $html += @"
<div class="section">
    <h3>Hardware</h3>
    <table class="info-table">
        <tr><th>C: Drive Total</th><td>$($SystemInfo.Hardware.CDrive.TotalSizeGB) GB</td></tr>
        <tr><th>C: Drive Used</th><td>$($SystemInfo.Hardware.CDrive.UsedSpaceGB) GB</td></tr>
        <tr><th>C: Drive Free</th><td>$($SystemInfo.Hardware.CDrive.FreeSpaceGB) GB ($($SystemInfo.Hardware.CDrive.PercentFree)%)</td></tr>

"@

    if ($SystemInfo.Hardware.NvidiaGPU) {
        $html += @"
        <tr><th>NVIDIA GPU</th><td>$($SystemInfo.Hardware.NvidiaGPU.Name)</td></tr>
        <tr><th>GPU Memory</th><td>$($SystemInfo.Hardware.NvidiaGPU.AdapterRAM_GB) GB</td></tr>
"@
        if ($SystemInfo.Hardware.NvidiaGPU.DriverBranch) {
            $html += @"
        <tr><th>GPU Software/Driver Version</th><td>$($SystemInfo.Hardware.NvidiaGPU.SoftwareVersion)</td></tr>
        <tr><th>GPU Software Release Branch</th><td>$($SystemInfo.Hardware.NvidiaGPU.SoftwareReleaseBranch)</td></tr>
        <tr><th>GPU Driver Branch</th><td>$($SystemInfo.Hardware.NvidiaGPU.DriverBranch)</td></tr>
        <tr><th>Software Release</th><td>$($SystemInfo.Hardware.NvidiaGPU.BranchType)</td></tr>
        <tr><th>Release Date</th><td>$($SystemInfo.Hardware.NvidiaGPU.ReleaseDate)</td></tr>
        <tr><th>EOL Date</th><td>$($SystemInfo.Hardware.NvidiaGPU.EOLDate)</td></tr>
"@
        }
    }

    $html += "    </table>`n</div>`n`n"

    # Network Information
    $html += "<div class=`"section`">`n    <h3>Network Adapters</h3>`n"

    if ($SystemInfo.Network.Adapters -and $SystemInfo.Network.Adapters.Count -gt 0) {
        $html += @"
    <table class="data-table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Description</th>
                <th>MAC Address</th>
                <th>IP Address</th>
                <th>Link Speed</th>
            </tr>
        </thead>
        <tbody>

"@

        foreach ($adapter in $SystemInfo.Network.Adapters) {
            $html += @"
            <tr>
                <td>$($adapter.Name)</td>
                <td>$($adapter.Description)</td>
                <td>$($adapter.MACAddress)</td>
                <td>$($adapter.IPAddress)</td>
                <td>$($adapter.LinkSpeed)</td>
            </tr>

"@
        }

        $html += "        </tbody>`n    </table>`n"
    } else {
        $html += "    <p><em>No network adapter information available</em></p>`n"
    }

    $html += "</div>`n`n"

    # Security Information
    $html += @"
<div class="section">
    <h3>Security</h3>
    <table class="info-table">

"@

    if ($SystemInfo.Security.WindowsDefender) {
        $html += "        <tr><th>Windows Defender Enabled</th><td>$($SystemInfo.Security.WindowsDefender.AntivirusEnabled)</td></tr>`n"
        $html += "        <tr><th>Real-Time Protection</th><td>$($SystemInfo.Security.WindowsDefender.RealTimeProtectionEnabled)</td></tr>`n"
        if ($SystemInfo.Security.WindowsDefender.AntivirusSignatureVersion) {
            $html += "        <tr><th>Signature Version</th><td>$($SystemInfo.Security.WindowsDefender.AntivirusSignatureVersion)</td></tr>`n"
        }
    }

    if ($SystemInfo.Security.Firewall) {
        $html += "        <tr><th>Firewall (Domain)</th><td>$($SystemInfo.Security.Firewall.DomainProfile)</td></tr>`n"
        $html += "        <tr><th>Firewall (Private)</th><td>$($SystemInfo.Security.Firewall.PrivateProfile)</td></tr>`n"
        $html += "        <tr><th>Firewall (Public)</th><td>$($SystemInfo.Security.Firewall.PublicProfile)</td></tr>`n"
    }

    if ($SystemInfo.Security.TPM) {
        $html += "        <tr><th>TPM Present</th><td>$($SystemInfo.Security.TPM.Present)</td></tr>`n"
        if ($SystemInfo.Security.TPM.Version) {
            $html += "        <tr><th>TPM Version</th><td>$($SystemInfo.Security.TPM.Version)</td></tr>`n"
        }
    }

    $html += "    </table>`n</div>`n`n"

    return $html
}