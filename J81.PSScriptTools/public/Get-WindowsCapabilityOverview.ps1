function Get-WindowsCapabilityOverview {
    <#
    .SYNOPSIS
        Get a list of all capabilities on the system.

    .DESCRIPTION
        This function will return a list of all capabilities on the system.

    .PARAMETER AsJSON
        If this switch is present, the output will be in JSON format.

    .EXAMPLE
        Get-WindowsCapabilityOverview
        This will return a list of all capabilities on the system.

    .EXAMPLE
        Get-WindowsCapabilityOverview -AsJSON
        This will return a list of all capabilities on the system in JSON format.

    .NOTES
        Function Name : Get-WindowsCapabilityOverview
        Version       : v1.0.0
        Author        : John Billekens
        Requires      : PowerShell
    #>
    [CmdletBinding()]
    param(
        [Switch]$AsJSON
    )
    $FriendlyNames = @{
        "AzureArcSetup"                                 = "Azure Arc"
        "Rsat.ActiveDirectory.DS-LDS.Tools"             = "RSAT: Active Directory Domain Services and Lightweight Directory Tools"
        "Rsat.BitLocker.Recovery.Tools"                 = "RSAT: BitLocker Drive Encryption Tools"
        "Rsat.AzureStack.HCI.Management.Tools"          = "RSAT: Azure Stack HCI Management Tools"
        "Rsat.Dns.Tools"                                = "RSAT: DNS Server Tools"
        "Rsat.Dhcp.Tools"                               = "RSAT: DHCP Server Tools"
        "Rsat.FileServices.Tools"                       = "RSAT: File Services Tools"
        "Rsat.FailoverCluster.Management.Tools"         = "RSAT: Failover Cluster Management Tools"
        "Rsat.CertificateServices.Tools"                = "RSAT: Certification Authority Tools"
        "Rsat.GroupPolicy.Management.Tools"             = "RSAT: Group Policy Management Tools"
        "Rsat.IPAM.Client.Tools"                        = "RSAT: IP Address Management Client Tools"
        "Rsat.NetworkController.Tools"                  = "RSAT: Network Controller Management Tools"
        "Rsat.NetworkLoadBalancing.Tools"               = "RSAT: Network Load Balancing Tools"
        "Rsat.Print.Management.Console"                 = "RSAT: Print Management Console"
        "Rsat.RemoteAccess.Management.Tools"            = "RSAT: Remote Access Management Tools"
        "Rsat.RemoteDesktop.Services.Tools"             = "RSAT: Remote Desktop Services Tools"
        "Rsat.ServerManager.Tools"                      = "RSAT: Server Manager"
        "Rsat.Shielded.VM.Tools"                        = "RSAT: Shielded VM Tools"
        "Rsat.StorageMigrationService.Management.Tools" = "RSAT: Storage Migration Service Management Tools"
        "Rsat.StorageReplica.Tools"                     = "RSAT: Storage Replica Tools"
        "Rsat.SystemInsights.Management.Tools"          = "RSAT: System Insights Management Tools"
        "Rsat.VolumeActivation.Tools"                   = "RSAT: Volume Activation Tools"
        "Rsat.WSUS.Tools"                               = "RSAT: Windows Server Update Services Tools"
    }

    $capabilities = Get-WindowsCapability -Online | ForEach-Object {
        $cleanName = ($_.Name -split "~{4}")[0]

        if ($FriendlyNames.ContainsKey($cleanName)) {
            $friendlyName = $FriendlyNames[$cleanName]
        } elseif ($_.Name -match "Language\.(.+)") {
            $friendlyName = '{0} {1}' -f (($_.Name -split "~{3}")[0] -replace "\.", " "), (($_.Name -split "~{3}")[1] -split "~{1}")[0]

        } else {
            $friendlyName = $cleanName -replace "\.", " "
        }

        [PSCustomObject]@{
            FriendlyName = $friendlyName
            State        = $_.State.ToString()
            StateValue   = [int]$_.State
            Name         = $_.Name
        }
    }

    if ($AsJSON) {
        $capabilities | ConvertTo-Json -Depth 2
    } else {
        $capabilities
    }
}
