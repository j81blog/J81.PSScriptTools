function Get-WindowsOptionalFeatureOverview {
    <#
    .SYNOPSIS
        Get a list of all optional features on the system.

    .DESCRIPTION
        This function will return a list of all optional features on the system.

    .PARAMETER AsJSON
        If this switch is present, the output will be in JSON format.

    .EXAMPLE
        Get-WindowsOptionalFeatureOverview
        This will return a list of all optional features on the system.

    .EXAMPLE
        Get-WindowsOptionalFeatureOverview -AsJSON
        This will return a list of all optional features on the system in JSON format.

    .NOTES
        Function Name : Get-WindowsOptionalFeatureOverview
        Version       : v1.0.0
        Author        : John Billekens
        Requires      : PowerShell
    #>

    [CmdletBinding()]
    param(
        [Switch]$AsJSON
    )
    $FriendlyNames = @{
        "AppServerClient"                             = "App Server Client"
        "ASP.NET"                                     = "ASP.NET"
        "Client-DeviceLockdown"                       = "Client Device Lockdown"
        "Client-EmbeddedBootExp"                      = "Client Embedded Boot Experience"
        "Client-EmbeddedLogon"                        = "Client Embedded Logon"
        "Client-EmbeddedShellLauncher"                = "Client Embedded Shell Launcher"
        "Client-KeyboardFilter"                       = "Client Keyboard Filter"
        "Client-ProjFS"                               = "Client Projected File System"
        "Client-UnifiedWriteFilter"                   = "Client Unified Write Filter"
        "ClientForNFS-Infrastructure"                 = "Client for NFS Infrastructure"
        "Containers"                                  = "Containers Feature"
        "Containers-DisposableClientVM"               = "Windows Sandbox"
        "Containers-HNS"                              = "Containers Host Network Service"
        "Containers-SDN"                              = "Containers Software Defined Networking"
        "Containers-Server-For-Application-Guard"     = "Containers Server for Application Guard"
        "DataCenterBridging"                          = "Data Center Bridging"
        "DirectoryServices-ADAM-Client"               = "Directory Services ADAM Client"
        "DirectPlay"                                  = "DirectPlay"
        "HostGuardian"                                = "Host Guardian"
        "HyperV-Guest-KernelInt"                      = "Hyper-V Guest Kernel Integration"
        "HyperV-KernelInt-VirtualDevice"              = "Hyper-V Kernel Integration Virtual Device"
        "HypervisorPlatform"                          = "Windows Hypervisor Platform"
        "IIS-ApplicationDevelopment"                  = "IIS Application Development"
        "IIS-ApplicationInit"                         = "IIS Application Initialization"
        "IIS-ASP"                                     = "ASP"
        "IIS-ASPNET"                                  = "ASP.NET"
        "IIS-ASPNET45"                                = "ASP.NET 4.5"
        "IIS-BasicAuthentication"                     = "IIS Basic Authentication"
        "IIS-CertProvider"                            = "IIS Certificate Provider"
        "IIS-CGI"                                     = "IIS CGI"
        "IIS-ClientCertificateMappingAuthentication"  = "IIS Client Certificate Mapping Authentication"
        "IIS-CommonHttpFeatures"                      = "IIS Common HTTP Features"
        "IIS-CustomLogging"                           = "IIS Custom Logging"
        "IIS-DefaultDocument"                         = "IIS Default Document"
        "IIS-DigestAuthentication"                    = "IIS Digest Authentication"
        "IIS-DirectoryBrowsing"                       = "IIS Directory Browsing"
        "IIS-FTPServer"                               = "IIS FTP Server"
        "IIS-FTPExtensibility"                        = "IIS FTP Extensibility"
        "IIS-FTPSvc"                                  = "IIS FTP Service"
        "IIS-HealthAndDiagnostics"                    = "IIS Health and Diagnostics"
        "IIS-HostableWebCore"                         = "IIS Hostable Web Core"
        "IIS-HttpCompressionDynamic"                  = "IIS HTTP Compression Dynamic"
        "IIS-HttpCompressionStatic"                   = "IIS HTTP Compression Static"
        "IIS-HttpErrors"                              = "IIS HTTP Errors"
        "IIS-HttpLogging"                             = "IIS HTTP Logging"
        "IIS-HttpRedirect"                            = "IIS HTTP Redirect"
        "IIS-HttpTracing"                             = "IIS HTTP Tracing"
        "IIS-IIS6ManagementCompatibility"             = "IIS 6 Management Compatibility"
        "IIS-IISCertificateMappingAuthentication"     = "IIS IIS Certificate Mapping Authentication"
        "IIS-IPSecurity"                              = "IIS IP Security"
        "IIS-ISAPIExtensions"                         = "IIS ISAPI Extensions"
        "IIS-ISAPIFilter"                             = "IIS ISAPI Filters"
        "IIS-LegacyScripts"                           = "IIS Legacy Scripts"
        "IIS-LoggingLibraries"                        = "IIS Logging Libraries"
        "IIS-ManagementConsole"                       = "IIS Management Console"
        "IIS-ManagementScriptingTools"                = "IIS Management Scripting Tools"
        "IIS-ManagementService"                       = "IIS Management Service"
        "IIS-Metabase"                                = "IIS 6 Metabase Compatibility"
        "IIS-NetFxExtensibility"                      = ".NET Extensibility"
        "IIS-NetFxExtensibility45"                    = ".NET Extensibility 4.5"
        "IIS-ODBCLogging"                             = "IIS ODBC Logging"
        "IIS-Performance"                             = "IIS Performance Features"
        "IIS-RequestFiltering"                        = "IIS Request Filtering"
        "IIS-RequestMonitor"                          = "IIS Request Monitor"
        "IIS-Security"                                = "IIS Security Features"
        "IIS-ServerSideIncludes"                      = "IIS Server-Side Includes"
        "IIS-StaticContent"                           = "IIS Static Content"
        "IIS-URLAuthorization"                        = "IIS URL Authorization"
        "IIS-WebDAV"                                  = "IIS WebDAV Publishing"
        "IIS-WebServer"                               = "IIS Web Server"
        "IIS-WebServerManagementTools"                = "IIS Web Server Management Tools"
        "IIS-WebServerRole"                           = "IIS Web Server Role"
        "IIS-WebSockets"                              = "IIS WebSockets"
        "IIS-WMICompatibility"                        = "IIS 6 WMI Compatibility"
        "IIS-WindowsAuthentication"                   = "IIS Windows Authentication"
        "LegacyComponents"                            = "Legacy Components"
        "MediaPlayback"                               = "Media Playback"
        "Microsoft-Hyper-V"                           = "Hyper-V"
        "Microsoft-Hyper-V-All"                       = "Hyper-V"
        "Microsoft-Hyper-V-Hypervisor"                = "Hyper-V Hypervisor"
        "Microsoft-Hyper-V-Management-Clients"        = "Hyper-V Management Tools"
        "Microsoft-Hyper-V-Management-PowerShell"     = "Hyper-V Management PowerShell"
        "Microsoft-Hyper-V-Services"                  = "Hyper-V Services"
        "Microsoft-Hyper-V-Tools-All"                 = "Hyper-V GUI Management Tools"
        "Microsoft-RemoteDesktopConnection"           = "Microsoft Remote Desktop Connection"
        "Microsoft-Windows-Subsystem-Linux"           = "Windows Subsystem for Linux"
        "MicrosoftWindowsPowerShellV2"                = "PowerShell 2.0"
        "MicrosoftWindowsPowerShellV2Root"            = "PowerShell 2.0"
        "MSMQ-ADIntegration"                          = "MSMQ Active Directory Integration"
        "MSMQ-Container"                              = "MSMQ Container"
        "MSMQ-DCOMProxy"                              = "MSMQ DCOM Proxy"
        "MSMQ-HTTP"                                   = "MSMQ HTTP Support"
        "MSMQ-Multicast"                              = "MSMQ Multicasting Support"
        "MSMQ-Server"                                 = "Microsoft Message Queue (MSMQ) Server"
        "MSMQ-Triggers"                               = "MSMQ Triggers"
        "MSRDC-Infrastructure"                        = "MSRDC Infrastructure"
        "MultiPoint-Connector"                        = "MultiPoint Connector"
        "MultiPoint-Connector-Services"               = "MultiPoint Connector Services"
        "MultiPoint-Tools"                            = "MultiPoint Tools"
        "NetFx3"                                      = ".NET Framework 3.5"
        "NetFx4-AdvSrvs"                              = ".NET Framework 4.x Advanced Services"
        "NetFx4Extended-ASPNET45"                     = ".NET Framework 4.x Extended ASP.NET 4.5"
        "NFS-Administration"                          = "NFS Administration"
        "Printing-Foundation-Features"                = "Printing Foundation Features"
        "Printing-Foundation-InternetPrinting-Client" = "Internet Printing Client"
        "Printing-Foundation-LPDPrintService"         = "LPD Print Service"
        "Printing-Foundation-LPRPortMonitor"          = "LPR Port Monitor"
        "Printing-PrintToPDFServices-Features"        = "Microsoft Print to PDF"
        "Printing-XPSServices-Features"               = "XPS Services"
        "Recall"                                      = "Recall"
        "SearchEngine-Client-Package"                 = "Search Engine Client Package"
        "ServicesForNFS-ClientOnly"                   = "Services for NFS Client Only"
        "SimpleTCP"                                   = "Simple TCP/IP Services"
        "SMB1Protocol"                                = "SMB 1.0 Protocol"
        "SMB1Protocol-Client"                         = "SMB 1.0 Protocol Client"
        "SMB1Protocol-Deprecation"                    = "SMB 1.0 Protocol Deprecation"
        "SMB1Protocol-Server"                         = "SMB 1.0 Protocol Server"
        "SmbDirect"                                   = "SMB Direct"
        "TelnetClient"                                = "Telnet Client"
        "TFTP"                                        = "TFTP Client"
        "TFTPClient"                                  = "TFTP Client"
        "TIFFIFilter"                                 = "TIFF IFilter"
        "VirtualMachinePlatform"                      = "Virtual Machine Platform"
        "WAS-ConfigurationAPI"                        = "WAS Configuration API"
        "WAS-NetFxEnvironment"                        = "WAS .NET Framework Environment"
        "WAS-ProcessModel"                            = "WAS Process Model"
        "WAS-WindowsActivationService"                = "WAS Windows Activation Service"
        "WCF-HTTP-Activation"                         = "WCF HTTP Activation"
        "WCF-HTTP-Activation45"                       = "WCF HTTP Activation 4.5"
        "WCF-MSMQ-Activation45"                       = "WCF MSMQ Activation 4.5"
        "WCF-NonHTTP-Activation"                      = "WCF Non-HTTP Activation"
        "WCF-Pipe-Activation45"                       = "WCF Named Pipe Activation 4.5"
        "WCF-Services45"                              = "WCF Services 4.5"
        "WCF-TCP-Activation45"                        = "WCF TCP Activation 4.5"
        "WCF-TCP-PortSharing45"                       = "WCF TCP Port Sharing 4.5"
        "Windows-Defender-Default-Definitions"        = "Windows Defender Default Definitions"
        "Windows-Identity-Foundation"                 = "Windows Identity Foundation"
        "WindowsIdentityFoundation"                   = "Windows Identity Foundation 3.5"
        "WindowsMediaPlayer"                          = "Windows Media Player"
        "WorkFolders-Client"                          = "Work Folders Client"
    }

    $optionalFeatures = Get-WindowsOptionalFeature -Online | ForEach-Object {
        $found = $false
        $friendlyName = if ($FriendlyNames.ContainsKey($_.FeatureName) -and -not [string]::IsNullOrEmpty($FriendlyNames[$_.FeatureName])) {
            $FriendlyNames[$_.FeatureName]
            $found = $true
        } else {
            $_.FeatureName
        }

        [PSCustomObject]@{
            FriendlyName = $friendlyName
            State        = $_.State.ToString()
            StateValue   = [int]$_.State
            Found        = $found
            Name         = $_.FeatureName
        }
    }

    if ($AsJSON) {
        $optionalFeatures | ConvertTo-Json -Depth 2
    } else {
        $optionalFeatures
    }
}
