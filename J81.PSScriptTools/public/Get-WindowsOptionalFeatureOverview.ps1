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

# SIG # Begin signature block
# MIImdwYJKoZIhvcNAQcCoIImaDCCJmQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAVY/OgfGWgEpr2
# e3lPHzbtnQ2Rm//sRTGVH3l+XcVhu6CCIAowggYUMIID/KADAgECAhB6I67aU2mW
# D5HIPlz0x+M/MA0GCSqGSIb3DQEBDAUAMFcxCzAJBgNVBAYTAkdCMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxLjAsBgNVBAMTJVNlY3RpZ28gUHVibGljIFRpbWUg
# U3RhbXBpbmcgUm9vdCBSNDYwHhcNMjEwMzIyMDAwMDAwWhcNMzYwMzIxMjM1OTU5
# WjBVMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSwwKgYD
# VQQDEyNTZWN0aWdvIFB1YmxpYyBUaW1lIFN0YW1waW5nIENBIFIzNjCCAaIwDQYJ
# KoZIhvcNAQEBBQADggGPADCCAYoCggGBAM2Y2ENBq26CK+z2M34mNOSJjNPvIhKA
# VD7vJq+MDoGD46IiM+b83+3ecLvBhStSVjeYXIjfa3ajoW3cS3ElcJzkyZlBnwDE
# JuHlzpbN4kMH2qRBVrjrGJgSlzzUqcGQBaCxpectRGhhnOSwcjPMI3G0hedv2eNm
# GiUbD12OeORN0ADzdpsQ4dDi6M4YhoGE9cbY11XxM2AVZn0GiOUC9+XE0wI7CQKf
# OUfigLDn7i/WeyxZ43XLj5GVo7LDBExSLnh+va8WxTlA+uBvq1KO8RSHUQLgzb1g
# bL9Ihgzxmkdp2ZWNuLc+XyEmJNbD2OIIq/fWlwBp6KNL19zpHsODLIsgZ+WZ1AzC
# s1HEK6VWrxmnKyJJg2Lv23DlEdZlQSGdF+z+Gyn9/CRezKe7WNyxRf4e4bwUtrYE
# 2F5Q+05yDD68clwnweckKtxRaF0VzN/w76kOLIaFVhf5sMM/caEZLtOYqYadtn03
# 4ykSFaZuIBU9uCSrKRKTPJhWvXk4CllgrwIDAQABo4IBXDCCAVgwHwYDVR0jBBgw
# FoAU9ndq3T/9ARP/FqFsggIv0Ao9FCUwHQYDVR0OBBYEFF9Y7UwxeqJhQo1SgLqz
# YZcZojKbMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEAMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMIMBEGA1UdIAQKMAgwBgYEVR0gADBMBgNVHR8ERTBDMEGg
# P6A9hjtodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNUaW1lU3Rh
# bXBpbmdSb290UjQ2LmNybDB8BggrBgEFBQcBAQRwMG4wRwYIKwYBBQUHMAKGO2h0
# dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1B1YmxpY1RpbWVTdGFtcGluZ1Jv
# b3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTAN
# BgkqhkiG9w0BAQwFAAOCAgEAEtd7IK0ONVgMnoEdJVj9TC1ndK/HYiYh9lVUacah
# RoZ2W2hfiEOyQExnHk1jkvpIJzAMxmEc6ZvIyHI5UkPCbXKspioYMdbOnBWQUn73
# 3qMooBfIghpR/klUqNxx6/fDXqY0hSU1OSkkSivt51UlmJElUICZYBodzD3M/SFj
# eCP59anwxs6hwj1mfvzG+b1coYGnqsSz2wSKr+nDO+Db8qNcTbJZRAiSazr7KyUJ
# Go1c+MScGfG5QHV+bps8BX5Oyv9Ct36Y4Il6ajTqV2ifikkVtB3RNBUgwu/mSiSU
# ice/Jp/q8BMk/gN8+0rNIE+QqU63JoVMCMPY2752LmESsRVVoypJVt8/N3qQ1c6F
# ibbcRabo3azZkcIdWGVSAdoLgAIxEKBeNh9AQO1gQrnh1TA8ldXuJzPSuALOz1Uj
# b0PCyNVkWk7hkhVHfcvBfI8NtgWQupiaAeNHe0pWSGH2opXZYKYG4Lbukg7HpNi/
# KqJhue2Keak6qH9A8CeEOB7Eob0Zf+fU+CCQaL0cJqlmnx9HCDxF+3BLbUufrV64
# EbTI40zqegPZdA+sXCmbcZy6okx/SjwsusWRItFA3DE8MORZeFb6BmzBtqKJ7l93
# 9bbKBy2jvxcJI98Va95Q5JnlKor3m0E7xpMeYRriWklUPsetMSf2NvUQa/E5vVye
# fQIwggZFMIIELaADAgECAhAIMk+dt9qRb2Pk8qM8Xl1RMA0GCSqGSIb3DQEBCwUA
# MFYxCzAJBgNVBAYTAlBMMSEwHwYDVQQKExhBc3NlY28gRGF0YSBTeXN0ZW1zIFMu
# QS4xJDAiBgNVBAMTG0NlcnR1bSBDb2RlIFNpZ25pbmcgMjAyMSBDQTAeFw0yNDA0
# MDQxNDA0MjRaFw0yNzA0MDQxNDA0MjNaMGsxCzAJBgNVBAYTAk5MMRIwEAYDVQQH
# DAlTY2hpam5kZWwxIzAhBgNVBAoMGkpvaG4gQmlsbGVrZW5zIENvbnN1bHRhbmN5
# MSMwIQYDVQQDDBpKb2huIEJpbGxla2VucyBDb25zdWx0YW5jeTCCAaIwDQYJKoZI
# hvcNAQEBBQADggGPADCCAYoCggGBAMslntDbSQwHZXwFhmibivbnd0Qfn6sqe/6f
# os3pKzKxEsR907RkDMet2x6RRg3eJkiIr3TFPwqBooyXXgK3zxxpyhGOcuIqyM9J
# 28DVf4kUyZHsjGO/8HFjrr3K1hABNUszP0o7H3o6J31eqV1UmCXYhQlNoW9FOmRC
# 1amlquBmh7w4EKYEytqdmdOBavAD5Xq4vLPxNP6kyA+B2YTtk/xM27TghtbwFGKn
# u9Vwnm7dFcpLxans4ONt2OxDQOMA5NwgcUv/YTpjhq9qoz6ivG55NRJGNvUXsM3w
# 2o7dR6Xh4MuEGrTSrOWGg2A5EcLH1XqQtkF5cZnAPM8W/9HUp8ggornWnFVQ9/6M
# ga+ermy5wy5XrmQpN+x3u6tit7xlHk1Hc+4XY4a4ie3BPXG2PhJhmZAn4ebNSBwN
# Hh8z7WTT9X9OFERepGSytZVeEP7hgyptSLcuhpwWeR4QdBb7dV++4p3PsAUQVHFp
# wkSbrRTv4EiJ0Lcz9P1HPGFoHiFAQQIDAQABo4IBeDCCAXQwDAYDVR0TAQH/BAIw
# ADA9BgNVHR8ENjA0MDKgMKAuhixodHRwOi8vY2NzY2EyMDIxLmNybC5jZXJ0dW0u
# cGwvY2NzY2EyMDIxLmNybDBzBggrBgEFBQcBAQRnMGUwLAYIKwYBBQUHMAGGIGh0
# dHA6Ly9jY3NjYTIwMjEub2NzcC1jZXJ0dW0uY29tMDUGCCsGAQUFBzAChilodHRw
# Oi8vcmVwb3NpdG9yeS5jZXJ0dW0ucGwvY2NzY2EyMDIxLmNlcjAfBgNVHSMEGDAW
# gBTddF1MANt7n6B0yrFu9zzAMsBwzTAdBgNVHQ4EFgQUO6KtBpOBgmrlANVAnyiQ
# C6W6lJwwSwYDVR0gBEQwQjAIBgZngQwBBAEwNgYLKoRoAYb2dwIFAQQwJzAlBggr
# BgEFBQcCARYZaHR0cHM6Ly93d3cuY2VydHVtLnBsL0NQUzATBgNVHSUEDDAKBggr
# BgEFBQcDAzAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAEQsN8wg
# PMdWVkwHPPTN+jKpdns5AKVFjcn00psf2NGVVgWWNQBIQc9lEuTBWb54IK6Ga3hx
# QRZfnPNo5HGl73YLmFgdFQrFzZ1lnaMdIcyh8LTWv6+XNWfoyCM9wCp4zMIDPOs8
# LKSMQqA/wRgqiACWnOS4a6fyd5GUIAm4CuaptpFYr90l4Dn/wAdXOdY32UhgzmSu
# xpUbhD8gVJUaBNVmQaRqeU8y49MxiVrUKJXde1BCrtR9awXbqembc7Nqvmi60tYK
# lD27hlpKtj6eGPjkht0hHEsgzU0Fxw7ZJghYG2wXfpF2ziN893ak9Mi/1dmCNmor
# GOnybKYfT6ff6YTCDDNkod4egcMZdOSv+/Qv+HAeIgEvrxE9QsGlzTwbRtbm6gwY
# YcVBs/SsVUdBn/TSB35MMxRhHE5iC3aUTkDbceo/XP3uFhVL4g2JZHpFfCSu2TQr
# rzRn2sn07jfMvzeHArCOJgBW1gPqR3WrJ4hUxL06Rbg1gs9tU5HGGz9KNQMfQFQ7
# 0Wz7UIhezGcFcRfkIfSkMmQYYpsc7rfzj+z0ThfDVzzJr2dMOFsMlfj1T6l22GBq
# 9XQx0A4lcc5Fl9pRxbOuHHWFqIBD/BCEhwniOCySzqENd2N+oz8znKooSISStnkN
# aYXt6xblJF2dx9Dn89FK7d1IquNxOwt0tI5dMIIGYjCCBMqgAwIBAgIRAKQpO24e
# 3denNAiHrXpOtyQwDQYJKoZIhvcNAQEMBQAwVTELMAkGA1UEBhMCR0IxGDAWBgNV
# BAoTD1NlY3RpZ28gTGltaXRlZDEsMCoGA1UEAxMjU2VjdGlnbyBQdWJsaWMgVGlt
# ZSBTdGFtcGluZyBDQSBSMzYwHhcNMjUwMzI3MDAwMDAwWhcNMzYwMzIxMjM1OTU5
# WjByMQswCQYDVQQGEwJHQjEXMBUGA1UECBMOV2VzdCBZb3Jrc2hpcmUxGDAWBgNV
# BAoTD1NlY3RpZ28gTGltaXRlZDEwMC4GA1UEAxMnU2VjdGlnbyBQdWJsaWMgVGlt
# ZSBTdGFtcGluZyBTaWduZXIgUjM2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEA04SV9G6kU3jyPRBLeBIHPNyUgVNnYayfsGOyYEXrn3+SkDYTLs1crcw/
# ol2swE1TzB2aR/5JIjKNf75QBha2Ddj+4NEPKDxHEd4dEn7RTWMcTIfm492TW22I
# 8LfH+A7Ehz0/safc6BbsNBzjHTt7FngNfhfJoYOrkugSaT8F0IzUh6VUwoHdYDpi
# ln9dh0n0m545d5A5tJD92iFAIbKHQWGbCQNYplqpAFasHBn77OqW37P9BhOASdmj
# p3IijYiFdcA0WQIe60vzvrk0HG+iVcwVZjz+t5OcXGTcxqOAzk1frDNZ1aw8nFhG
# EvG0ktJQknnJZE3D40GofV7O8WzgaAnZmoUn4PCpvH36vD4XaAF2CjiPsJWiY/j2
# xLsJuqx3JtuI4akH0MmGzlBUylhXvdNVXcjAuIEcEQKtOBR9lU4wXQpISrbOT8ux
# +96GzBq8TdbhoFcmYaOBZKlwPP7pOp5Mzx/UMhyBA93PQhiCdPfIVOCINsUY4U23
# p4KJ3F1HqP3H6Slw3lHACnLilGETXRg5X/Fp8G8qlG5Y+M49ZEGUp2bneRLZoyHT
# yynHvFISpefhBCV0KdRZHPcuSL5OAGWnBjAlRtHvsMBrI3AAA0Tu1oGvPa/4yeei
# Ayu+9y3SLC98gDVbySnXnkujjhIh+oaatsk/oyf5R2vcxHahajMCAwEAAaOCAY4w
# ggGKMB8GA1UdIwQYMBaAFF9Y7UwxeqJhQo1SgLqzYZcZojKbMB0GA1UdDgQWBBSI
# YYyhKjdkgShgoZsx0Iz9LALOTzAOBgNVHQ8BAf8EBAMCBsAwDAYDVR0TAQH/BAIw
# ADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDBKBgNVHSAEQzBBMDUGDCsGAQQBsjEB
# AgEDCDAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzAIBgZn
# gQwBBAIwSgYDVR0fBEMwQTA/oD2gO4Y5aHR0cDovL2NybC5zZWN0aWdvLmNvbS9T
# ZWN0aWdvUHVibGljVGltZVN0YW1waW5nQ0FSMzYuY3JsMHoGCCsGAQUFBwEBBG4w
# bDBFBggrBgEFBQcwAoY5aHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVi
# bGljVGltZVN0YW1waW5nQ0FSMzYuY3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2Nz
# cC5zZWN0aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAYEAAoE+pIZyUSH5ZakuPVKK
# 4eWbzEsTRJOEjbIu6r7vmzXXLpJx4FyGmcqnFZoa1dzx3JrUCrdG5b//LfAxOGy9
# Ph9JtrYChJaVHrusDh9NgYwiGDOhyyJ2zRy3+kdqhwtUlLCdNjFjakTSE+hkC9F5
# ty1uxOoQ2ZkfI5WM4WXA3ZHcNHB4V42zi7Jk3ktEnkSdViVxM6rduXW0jmmiu71Z
# pBFZDh7Kdens+PQXPgMqvzodgQJEkxaION5XRCoBxAwWwiMm2thPDuZTzWp/gUFz
# i7izCmEt4pE3Kf0MOt3ccgwn4Kl2FIcQaV55nkjv1gODcHcD9+ZVjYZoyKTVWb4V
# qMQy/j8Q3aaYd/jOQ66Fhk3NWbg2tYl5jhQCuIsE55Vg4N0DUbEWvXJxtxQQaVR5
# xzhEI+BjJKzh3TQ026JxHhr2fuJ0mV68AluFr9qshgwS5SpN5FFtaSEnAwqZv3IS
# +mlG50rK7W3qXbWwi4hmpylUfygtYLEdLQukNEX1jiOKMIIGgjCCBGqgAwIBAgIQ
# NsKwvXwbOuejs902y8l1aDANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYD
# VQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBS
# U0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMjEwMzIyMDAwMDAwWhcNMzgw
# MTE4MjM1OTU5WjBXMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1p
# dGVkMS4wLAYDVQQDEyVTZWN0aWdvIFB1YmxpYyBUaW1lIFN0YW1waW5nIFJvb3Qg
# UjQ2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAiJ3YuUVnnR3d6Lkm
# gZpUVMB8SQWbzFoVD9mUEES0QUCBdxSZqdTkdizICFNeINCSJS+lV1ipnW5ihkQy
# C0cRLWXUJzodqpnMRs46npiJPHrfLBOifjfhpdXJ2aHHsPHggGsCi7uE0awqKggE
# /LkYw3sqaBia67h/3awoqNvGqiFRJ+OTWYmUCO2GAXsePHi+/JUNAax3kpqstbl3
# vcTdOGhtKShvZIvjwulRH87rbukNyHGWX5tNK/WABKf+Gnoi4cmisS7oSimgHUI0
# Wn/4elNd40BFdSZ1EwpuddZ+Wr7+Dfo0lcHflm/FDDrOJ3rWqauUP8hsokDoI7D/
# yUVI9DAE/WK3Jl3C4LKwIpn1mNzMyptRwsXKrop06m7NUNHdlTDEMovXAIDGAvYy
# nPt5lutv8lZeI5w3MOlCybAZDpK3Dy1MKo+6aEtE9vtiTMzz/o2dYfdP0KWZwZIX
# bYsTIlg1YIetCpi5s14qiXOpRsKqFKqav9R1R5vj3NgevsAsvxsAnI8Oa5s2oy25
# qhsoBIGo/zi6GpxFj+mOdh35Xn91y72J4RGOJEoqzEIbW3q0b2iPuWLA911cRxgY
# 5SJYubvjay3nSMbBPPFsyl6mY4/WYucmyS9lo3l7jk27MAe145GWxK4O3m3gEFEI
# kv7kRmefDR7Oe2T1HxAnICQvr9sCAwEAAaOCARYwggESMB8GA1UdIwQYMBaAFFN5
# v1qqK0rPVIDh2JvAnfKyA2bLMB0GA1UdDgQWBBT2d2rdP/0BE/8WoWyCAi/QCj0U
# JTAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zATBgNVHSUEDDAKBggr
# BgEFBQcDCDARBgNVHSAECjAIMAYGBFUdIAAwUAYDVR0fBEkwRzBFoEOgQYY/aHR0
# cDovL2NybC51c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJTQUNlcnRpZmljYXRpb25B
# dXRob3JpdHkuY3JsMDUGCCsGAQUFBwEBBCkwJzAlBggrBgEFBQcwAYYZaHR0cDov
# L29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEADr5lQe1oRLjl
# ocXUEYfktzsljOt+2sgXke3Y8UPEooU5y39rAARaAdAxUeiX1ktLJ3+lgxtoLQhn
# 5cFb3GF2SSZRX8ptQ6IvuD3wz/LNHKpQ5nX8hjsDLRhsyeIiJsms9yAWnvdYOdEM
# q1W61KE9JlBkB20XBee6JaXx4UBErc+YuoSb1SxVf7nkNtUjPfcxuFtrQdRMRi/f
# InV/AobE8Gw/8yBMQKKaHt5eia8ybT8Y/Ffa6HAJyz9gvEOcF1VWXG8OMeM7Vy7B
# s6mSIkYeYtddU1ux1dQLbEGur18ut97wgGwDiGinCwKPyFO7ApcmVJOtlw9FVJxw
# /mL1TbyBns4zOgkaXFnnfzg4qbSvnrwyj1NiurMp4pmAWjR+Pb/SIduPnmFzbSN/
# G8reZCL4fvGlvPFk4Uab/JVCSmj59+/mB2Gn6G/UYOy8k60mKcmaAZsEVkhOFuoj
# 4we8CYyaR9vd9PGZKSinaZIkvVjbH/3nlLb0a7SBIkiRzfPfS9T+JesylbHa1LtR
# V9U/7m0q7Ma2CQ/t392ioOssXW7oKLdOmMBl14suVFBmbzrt5V5cQPnwtd3UOTpS
# 9oCG+ZZheiIvPgkDmA8FzPsnfXW5qHELB43ET7HHFHeRPRYrMBKjkb8/IN7Po0d0
# hQoF4TeMM+zYAJzoKQnVKOLg8pZVPT8wgga5MIIEoaADAgECAhEAmaOACiZVO2Wr
# 3G6EprPqOTANBgkqhkiG9w0BAQwFADCBgDELMAkGA1UEBhMCUEwxIjAgBgNVBAoT
# GVVuaXpldG8gVGVjaG5vbG9naWVzIFMuQS4xJzAlBgNVBAsTHkNlcnR1bSBDZXJ0
# aWZpY2F0aW9uIEF1dGhvcml0eTEkMCIGA1UEAxMbQ2VydHVtIFRydXN0ZWQgTmV0
# d29yayBDQSAyMB4XDTIxMDUxOTA1MzIxOFoXDTM2MDUxODA1MzIxOFowVjELMAkG
# A1UEBhMCUEwxITAfBgNVBAoTGEFzc2VjbyBEYXRhIFN5c3RlbXMgUy5BLjEkMCIG
# A1UEAxMbQ2VydHVtIENvZGUgU2lnbmluZyAyMDIxIENBMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEAnSPPBDAjO8FGLOczcz5jXXp1ur5cTbq96y34vuTm
# flN4mSAfgLKTvggv24/rWiVGzGxT9YEASVMw1Aj8ewTS4IndU8s7VS5+djSoMcbv
# IKck6+hI1shsylP4JyLvmxwLHtSworV9wmjhNd627h27a8RdrT1PH9ud0IF+njvM
# k2xqbNTIPsnWtw3E7DmDoUmDQiYi/ucJ42fcHqBkbbxYDB7SYOouu9Tj1yHIohzu
# C8KNqfcYf7Z4/iZgkBJ+UFNDcc6zokZ2uJIxWgPWXMEmhu1gMXgv8aGUsRdaCtVD
# 2bSlbfsq7BiqljjaCun+RJgTgFRCtsuAEw0pG9+FA+yQN9n/kZtMLK+Wo837Q4QO
# ZgYqVWQ4x6cM7/G0yswg1ElLlJj6NYKLw9EcBXE7TF3HybZtYvj9lDV2nT8mFSkc
# SkAExzd4prHwYjUXTeZIlVXqj+eaYqoMTpMrfh5MCAOIG5knN4Q/JHuurfTI5XDY
# O962WZayx7ACFf5ydJpoEowSP07YaBiQ8nXpDkNrUA9g7qf/rCkKbWpQ5boufUnq
# 1UiYPIAHlezf4muJqxqIns/kqld6JVX8cixbd6PzkDpwZo4SlADaCi2JSplKShBS
# ND36E/ENVv8urPS0yOnpG4tIoBGxVCARPCg1BnyMJ4rBJAcOSnAWd18Jx5n858JS
# qPECAwEAAaOCAVUwggFRMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFN10XUwA
# 23ufoHTKsW73PMAywHDNMB8GA1UdIwQYMBaAFLahVDkCw6A/joq8+tT4HKbROg79
# MA4GA1UdDwEB/wQEAwIBBjATBgNVHSUEDDAKBggrBgEFBQcDAzAwBgNVHR8EKTAn
# MCWgI6Ahhh9odHRwOi8vY3JsLmNlcnR1bS5wbC9jdG5jYTIuY3JsMGwGCCsGAQUF
# BwEBBGAwXjAoBggrBgEFBQcwAYYcaHR0cDovL3N1YmNhLm9jc3AtY2VydHVtLmNv
# bTAyBggrBgEFBQcwAoYmaHR0cDovL3JlcG9zaXRvcnkuY2VydHVtLnBsL2N0bmNh
# Mi5jZXIwOQYDVR0gBDIwMDAuBgRVHSAAMCYwJAYIKwYBBQUHAgEWGGh0dHA6Ly93
# d3cuY2VydHVtLnBsL0NQUzANBgkqhkiG9w0BAQwFAAOCAgEAdYhYD+WPUCiaU58Q
# 7EP89DttyZqGYn2XRDhJkL6P+/T0IPZyxfxiXumYlARMgwRzLRUStJl490L94C9L
# GF3vjzzH8Jq3iR74BRlkO18J3zIdmCKQa5LyZ48IfICJTZVJeChDUyuQy6rGDxLU
# UAsO0eqeLNhLVsgw6/zOfImNlARKn1FP7o0fTbj8ipNGxHBIutiRsWrhWM2f8pXd
# d3x2mbJCKKtl2s42g9KUJHEIiLni9ByoqIUul4GblLQigO0ugh7bWRLDm0CdY9rN
# LqyA3ahe8WlxVWkxyrQLjH8ItI17RdySaYayX3PhRSC4Am1/7mATwZWwSD+B7eMc
# ZNhpn8zJ+6MTyE6YoEBSRVrs0zFFIHUR08Wk0ikSf+lIe5Iv6RY3/bFAEloMU+vU
# BfSouCReZwSLo8WdrDlPXtR0gicDnytO7eZ5827NS2x7gCBibESYkOh1/w1tVxTp
# V2Na3PR7nxYVlPu1JPoRZCbH86gc96UTvuWiOruWmyOEMLOGGniR+x+zPF/2DaGg
# K2W1eEJfo2qyrBNPvF7wuAyQfiFXLwvWHamoYtPZo0LHuH8X3n9C+xN4YaNjt2yw
# zOr+tKyEVAotnyU9vyEVOaIYMk3IeBrmFnn0gbKeTTyYeEEUz/Qwt4HOUBCrW602
# NCmvO1nm+/80nLy5r0AZvCQxaQ4xggXDMIIFvwIBATBqMFYxCzAJBgNVBAYTAlBM
# MSEwHwYDVQQKExhBc3NlY28gRGF0YSBTeXN0ZW1zIFMuQS4xJDAiBgNVBAMTG0Nl
# cnR1bSBDb2RlIFNpZ25pbmcgMjAyMSBDQQIQCDJPnbfakW9j5PKjPF5dUTANBglg
# hkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3
# DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEV
# MC8GCSqGSIb3DQEJBDEiBCAnv6rAa4QS3Vg2XY1oUicULv2eYzkk023uCTg92jht
# xTANBgkqhkiG9w0BAQEFAASCAYC44ZoAYxiSnmWFhZcIGyzD66BKHc40VbrOTtyd
# i56u7qyUdQm6ccDhW0ZqCCpA002S6imwVJ+Hb/d1Ar46hTHq2BM72RfMIYLIuSM6
# jAC5DMp1ejgHHdQvTQy11H5rNB9JUyFNC7PNHNFqH5+WSYRb6FEX1ItBwGBA7P7z
# JbiE8U4c8hN5lBQ9WTOdQwuDlLLamXSINTshiXf3y51WoCLWSoe7PYYSt9Hh4iMp
# 6XbeYPtU1uBVO1e6uOEava9/C9uR1X6XPiw5h6+31me8Z5XQKWYaM1c7aP+dWN/5
# 89Np3MhSkVUbHd7TMpkxQ7hK9h1gXrupaEWGWQWwSUyDtDLYf8NLKYzl2MYSc3/9
# hX3FIi3iy0N32NGUjBLFjhErAvK9DvqTdlmXF7NxaLMiNSFxdMfIiyOl9FBWON49
# Qs8ueJg+CLJgsHEdlYEuH/vmWGnu0YMhLC6YUIweavt1mqKLoVUf6IAl9cb1ToKX
# lYHInjFfXWdLS1ze87YdoRiQcFKhggMjMIIDHwYJKoZIhvcNAQkGMYIDEDCCAwwC
# AQEwajBVMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSww
# KgYDVQQDEyNTZWN0aWdvIFB1YmxpYyBUaW1lIFN0YW1waW5nIENBIFIzNgIRAKQp
# O24e3denNAiHrXpOtyQwDQYJYIZIAWUDBAICBQCgeTAYBgkqhkiG9w0BCQMxCwYJ
# KoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAzMDQxMTA3NTBaMD8GCSqGSIb3
# DQEJBDEyBDAg83f5s2K2p1eUTlXHp4dxiIIwuVzwUsS9l4A0YgFZsoCPCW0Ur41U
# 7gxAieSYP6AwDQYJKoZIhvcNAQEBBQAEggIAFLV+eceOP1fEvWCiejJ7QQ9Yui78
# J2s6yy9JH3jYzQzyAXO795KhoHJmsWN4Y7iQ9lIsU2QYuNql6rmSZekUIRHefZHw
# EtU+o5n7khkqXpNrC/tzcW7OTjI6RfLoTStQ83DjdeYXAkhav4WLLf8aXw9v1N4g
# /5UUFz0kn0yfiklyNgeIyP4JTvLZsEczP9nk4ExdTKtqGDFBnN1UuvzT6kPR7vu1
# blziw/vfBsXnM+y5c9ot8kQRwBoF8zSgNTID0/GrYdwE/OOU3MfG97IMhDPcHsZb
# 4uyk+E38Z9oq4yBP4YQc21C0h9qb7ptPwu0zOmPDW5DshUUO14ZtvKMZaqeY6DD9
# bCbCdXhFJLD42Xw1oURH+ATkIE9wOXXLXdvf08KaNJTaXVFI02dpi/QHzRyci+3H
# DXi1cTvOMUU+hFKJh35bJAAGnnx1g7BCie/0jxN8DQ1QmeH2PWZRQLtbTPD1eC58
# VxAmMxiLazs5oi1zS7n6AewKvMUrQZcDAqdB3qsaxAex/kXVyd4Q15eF9wvjfbgY
# DE8bZ6zQoBWjoNrmiBl4WPUHTxRKu/NWwysVPfKIXm24nbe8G50/2pDEEiUw0AQg
# wypygDpcwXC0B3piwq88kKYhSSAEGnbISnsSwuDjjg5rK9XDjTk08FGVZ0hmCGi+
# BRVujQT77/t4/zo=
# SIG # End signature block
