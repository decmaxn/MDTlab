<# Notes:

Authors: Greg Shields
Modified by Victor Ma

Goal - Configure minimal initial settings for a server.
This script must be run after prepServer.ps1

Note:
Please modify the variables in $ConfigData section, copy it down to local folder, and run it from there. 

Error:
ConvertTo-MOFInstance : System.InvalidOperationException error processing property 'Password' OF TYPE 'User': Converting  and storing encrypted passwords as plain text is not recommended
Solution: https://blogs.technet.microsoft.com/ashleymcglone/2015/12/18/using-credentials-with-psdscallowplaintextpassword-and-psdscallowdomainuser-in-powershell-dsc-configuration-data/


Disclaimer
This example code is provided without copyright and AS IS.  It is free for you to use and modify.
Note: These demos should not be run as a script. These are the commands that I use in the 
demonstrations and would need to be modified for your environment.

#>

configuration configureServer
{
    Import-DscResource -ModuleName xComputerManagement, xNetworking
    Node localhost
    {

        LocalConfigurationManager {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
  
        xIPAddress NewIPAddress {
            IPAddress = $node.IPAddress
            InterfaceAlias = "ethernet"
            #PrefixLength = 24
            AddressFamily = "IPV4"
        }

        xDefaultGatewayAddress NewIPGateway {
            Address = $node.GatewayAddress
            InterfaceAlias = "ethernet"
            AddressFamily = "IPV4"
            DependsOn = '[xIPAddress]NewIPAddress'
        }

        xDnsServerAddress PrimaryDNSClient {
            Address        = $node.DNSIPAddress
            InterfaceAlias = "ethernet"
            AddressFamily = "IPV4"
            DependsOn = '[xDefaultGatewayAddress]NewIPGateway'
        }

        User Administrator {
            Ensure = "Present"
            UserName = "Administrator"
            Password = $Cred
            DependsOn = '[xDnsServerAddress]PrimaryDNSClient'
        }

        xComputer ChangeNameAndJoinDomain {
            Name = $node.ThisComputerName
            DomainName    = $node.DomainName
            Credential    = $domainCred
            DependsOn = '[User]Administrator'
        }
    }
}
            
$ConfigData = @{
    AllNodes = @(
        @{
            Nodename = "localhost"
            ThisComputerName = "S16x64-MDT"
            IPAddress = "192.168.0.56"
            GatewayAddress = "192.168.0.1"
            DNSIPAddress = "192.168.0.15"
            DomainName = "HLAB.local"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
}

$domainCred = Get-Credential -Message "Please enter a new password for Domain Administrator."
$Cred = Get-Credential -UserName Administrator -Message "Please enter a new password for Local Administrator and other accounts."

configureServer -ConfigurationData $ConfigData

Set-DSCLocalConfigurationManager -Path .\configureServer –Verbose
Start-DscConfiguration -Wait -Force -Path .\configureServer -Verbose