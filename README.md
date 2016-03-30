[![Build status](https://ci.appveyor.com/api/projects/status/obmudad7gy8usbx2/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xnetworking/branch/master)

# xNetworking

The **xNetworking** module contains the following resources:
* **xFirewall**
* **xIPAddress**
* **xDnsServerAddress**
* **xDnsConnectionSuffix**
* **xDefaultGatewayAddress**
* **xNetConnectionProfile**
* **xDhcpClient**
* **xRoute**
* **xNetBIOS**
* **xNetworkTeam**
* **xHostsFile**

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

* **xFirewall** sets a node's firewall rules.
* **xIPAddress** sets a node's IP address.
* **xDnsServerAddress** sets a node's DNS server.
* **xDnsConnectionSuffix** sets a node's network interface connection-specific DNS suffix.
* **xDefaultGatewayAddress** sets a node's default gateway address.
* **xNetConnectionProfile** sets a node's connection profile.

### xIPAddress

* **IPAddress**: The desired IP address.
* **InterfaceAlias**: Alias of the network interface for which the IP address should be set.
* **SubnetMask**: Local subnet size.
* **AddressFamily**: IP address family: { IPv4 | IPv6 }

### xDnsServerAddress

* **Address**: The desired DNS Server address(es)
* **InterfaceAlias**: Alias of the network interface for which the DNS server address is set.
* **AddressFamily**: IP address family: { IPv4 | IPv6 }
* **Validate**: Requires that the DNS Server addresses be validated if they are updated. It will cause the resouce to throw a 'A general error occurred that is not covered by a more specific error code.' error if set to True and specified DNS Servers are not accessible. Defaults to False.

### xDnsConnectionSuffix

* **InterfaceAlias**: Alias of the network interface for which the DNS server address is set.
* **ConnectionSpecificSuffix**: DNS connection-specific suffix to assign to the network interface.
* **RegisterThisConnectionsAddress**: Specifies that the IP address for this connection is to be registered. The default value is True.
* **UseSuffixWhenRegistering**: Specifies that this host name and the connection specific suffix for this connection are to be registered. The default value is False.
* **Ensure**: Ensure that the network interface connection-specific suffix is present or not. { Present | Absent }

### xDefaultGatewayAddress

* **Address**: The desired default gateway address - if not provided default gateway will be removed.
* **InterfaceAlias**: Alias of the network interface for which the default gateway address is set.
* **AddressFamily**: IP address family: { IPv4 | IPv6 }

### xFirewall

* **Name**: Name of the firewall rule.
* **DisplayName**: Localized, user-facing name of the firewall rule being created.
* **Group**: Name of the firewall group where we want to put the firewall rule.
* **Ensure**: Ensure that the firewall rule is Present or Absent.
* **Enabled**: Enable or Disable the supplied configuration.
* **Action**: Allow or Block the supplied configuration: { NotConfigured | Allow | Block }
* **Profile**: Specifies one or more profiles to which the rule is assigned.
* **Direction**: Direction of the connection.
* **RemotePort**: Specific port used for filter. Specified by port number, range, or keyword.
* **LocalPort**: Local port used for the filter.
* **Protocol**: Specific protocol for filter. Specified by name, number, or range.
* **Description**: Documentation for the rule.
* **Program**: Path and filename of the program for which the rule is applied.
* **Service**: Specifies the short name of a Windows service to which the firewall rule applies.
* **Authentication**: Specifies that authentication is required on firewall rules: { NotRequired | Required | NoEncap }
* **Encryption**: Specifies that encryption in authentication is required on firewall rules: { NotRequired | Required | Dynamic }
* **InterfaceAlias**: Specifies the alias of the interface that applies to the traffic.
* **InterfaceType**: Specifies that only network connections made through the indicated interface types are subject to the requirements of this rule: { Any | Wired | Wireless | RemoteAccess }
* **LocalAddress**: Specifies that network packets with matching IP addresses match this rule. This parameter value is the first end point of an IPsec rule and specifies the computers that are subject to the requirements of this rule. This parameter value is an IPv4 or IPv6 address, hostname, subnet, range, or the following keyword: Any.
* **LocalUser**: Specifies the principals to which network traffic this firewall rule applies. The principals, represented by security identifiers (SIDs) in the security descriptor definition language (SDDL) string, are services, users, application containers, or any SID to which network traffic is associated.
* **Package**: Specifies the Windows Store application to which the firewall rule applies. This parameter is specified as a security identifier (SID).
* **Platform**: Specifies which version of Windows the associated rule applies.
* **RemoteAddress**: Specifies that network packets with matching IP addresses match this rule. This parameter value is the second end point of an IPsec rule and specifies the computers that are subject to the requirements of this rule. This parameter value is an IPv4 or IPv6 address, hostname, subnet, range, or the following keyword: Any
* **RemoteMachine**: Specifies that matching IPsec rules of the indicated computer accounts are created. This parameter specifies that only network packets that are authenticated as incoming from or outgoing to a computer identified in the list of computer accounts (SID) match this rule. This parameter value is specified as an SDDL string.
* **RemoteUser**: Specifies that matching IPsec rules of the indicated user accounts are created. This parameter specifies that only network packets that are authenticated as incoming from or outgoing to a user identified in the list of user accounts match this rule. This parameter value is specified as an SDDL string.
* **DynamicTransport**: Specifies a dynamic transport: { Any | ProximityApps | ProximitySharing | WifiDirectPrinting | WifiDirectDisplay | WifiDirectDevices }
* **EdgeTraversalPolicy**: Specifies that matching firewall rules of the indicated edge traversal policy are created: { Block | Allow | DeferToUser | DeferToApp }
* **IcmpType**: Specifies the ICMP type codes.
* **LocalOnlyMapping**: Indicates that matching firewall rules of the indicated value are created.
* **LooseSourceMapping**: Indicates that matching firewall rules of the indicated value are created.
* **OverrideBlockRules**: Indicates that matching network traffic that would otherwise be blocked are allowed.
* **Owner**: Specifies that matching firewall rules of the indicated owner are created.

### xNetConnectionProfile

* **InterfaceAlias**: Specifies the alias for the Interface that is being changed.
* **NetworkCategory**: Sets the NetworkCategory for the interface - per [the documentation ](https://technet.microsoft.com/en-us/%5Clibrary/jj899565(v=wps.630).aspx) this can only be set to { Public | Private }
* **IPv4Connectivity**: Specifies the IPv4 Connection Value { Disconnected | NoTraffic | Subnet | LocalNetwork | Internet }
* **IPv6Connectivity**: Specifies the IPv6 Connection Value { Disconnected | NoTraffic | Subnet | LocalNetwork | Internet }

### xDhcpClient

* **State**: The desired state of the DHCP Client: { Enabled | Disabled }. Mandatory.
* **InterfaceAlias**: Alias of the network interface for which the DNS server address is set. Mandatory.
* **AddressFamily**: IP address family: { IPv4 | IPv6 }. Mandatory.

### xRoute

* **InterfaceAlias**: Specifies the alias of a network interface. Mandatory.
* **AddressFamily**: Specifies the IP address family. { IPv4 | IPv6 }. Mandatory.
* **DestinationPrefix**: Specifies a destination prefix of an IP route. A destination prefix consists of an IP address prefix and a prefix length, separated by a slash (/). Mandatory.
* **NextHop**: Specifies the next hop for the IP route. Mandatory.
* **Ensure**: Specifies whether the route should exist. { Present | Absent }. Defaults: Present.
* **RouteMetric**: Specifies an integer route metric for an IP route. Default: 256.
* **Publish**: Specifies the publish setting of an IP route. { No | Yes | Age }. Default: No.
* **PreferredLifetime**: Specifies a preferred lifetime in seconds of an IP route.

### xNetBIOS

* **InterfaceAlias**: Specifies the alias of a network interface. Mandatory.
* **Setting**: xNetBIOS setting { Default | Enable | Disable }. Mandatory.

### xNetworkTeam
* **Name**: Specifies the name of the network team to create.
* **TeamMembers**: Specifies the network interfaces that should be a part of the network team. This is a comma-separated list.
* **TeamingMode**: Specifies the teaming mode configuration. { SwitchIndependent | LACP | Static}.
* **LoadBalancingAlgorithm**: Specifies the load balancing algorithm for the network team. { Dynamic | HyperVPort | IPAddresses | MacAddresses | TransportPorts }.
* **Ensure**: Specifies if the network team should be created or deleted. { Present | Absent }.

### xHostsFile
* **HostName**: Specifies the name of the computer that will be mapped to an IP address.
* **IPAddress**: Specifies the IP Address that should be mapped to the host name.
* **Ensure**: Specifies if the hosts file entry should be created or deleted. { Present | Absent }.

## Known Invalid Configurations

### xFirewall
* The exception 'One of the port keywords is invalid' will be thrown if a rule is created with the LocalPort set to PlayToDiscovery and the Protocol is not set to UDP. This is not an unexpected error, but because the New-NetFirewallRule documentation is incorrect.
This issue has been reported on [Microsoft Connect](https://connect.microsoft.com/PowerShell/feedbackdetail/view/1974268/new-set-netfirewallrule-cmdlet-localport-parameter-documentation-is-incorrect-for-playtodiscovery)

## Known Issues

### xFirewall
The following error may occur when applying xFirewall configurations on Windows Server 2012 R2 if [KB3000850](https://support.microsoft.com/en-us/kb/3000850) is not installed. Please ensure this update is installed if this error occurs.
```
The cmdlet does not fully support the Inquire action for debug messages. Cmdlet operation will continue during the prompt. Select a different action preference via -Debug switch or $DebugPreference variable, and try again.
```

## Versions

### Unreleased

### 2.8.0.0

* Templates folder removed. Use the test templates in the [Tests.Template folder in the DSCResources repository](https://github.com/PowerShell/DscResources/tree/master/Tests.Template) instead.
* Added the following resources:
    * MSFT_xHostsFile resource to manage hosts file entries.
* MSFT_xFirewall: Fix test of Profile parameter status.
* MSFT_xIPAddress: Fix false negative when desired IP is a substring of current IP.

### 2.7.0.0

* Added the following resources:
    * MSFT_xNetworkTeam resource to manage native network adapter teaming.

### 2.6.0.0

* Added the following resources:
    * MSFT_xDhcpClient resource to enable/disable DHCP on individual interfaces.
    * MSFT_xRoute resource to manage network routes.
    * MSFT_xNetBIOS resource to configure NetBIOS over TCP/IP settings on individual interfaces.
* MSFT_*: Unit and Integration tests updated to use DSCResource.Tests\TestHelper.psm1 functions.
* MSFT_*: Resource Name added to all unit test Desribes.
* Templates update to use DSCResource.Tests\TestHelper.psm1 functions.
* MSFT_xNetConnectionProfile: Integration tests fixed when more than one connection profile present.
* Changed AppVeyor.yml to use WMF 5 build environment.
* MSFT_xIPAddress: Removed test for DHCP Status.
* MSFT_xFirewall: New parameters added:
    * DynamicTransport
    * EdgeTraversalPolicy
    * LocalOnlyMapping
    * LooseSourceMapping
    * OverrideBlockRules
    * Owner
* All unit & integration tests updated to be able to be run from any folder under tests directory.
* Unit & Integration test template headers updated to match DSCResource templates.

### 2.5.0.0
* Added the following resources:
    * MSFT_xDNSConnectionSuffix resource to manage connection-specific DNS suffixes.
    * MSFT_xNetConnectionProfile resource to manage Connection Profiles for interfaces.
* MSFT_xDNSServerAddress: Corrected Verbose logging messages when multiple DNS adddressed specified.
* MSFT_xDNSServerAddress: Change to ensure resource terminates if DNS Server validation fails.
* MSFT_xDNSServerAddress: Added Validate parameter to enable DNS server validation when changing server addresses.
* MSFT_xFirewall: ApplicationPath Parameter renamed to Program for consistency with Cmdlets.
* MSFT_xFirewall: Fix to prevent error when DisplayName parameter is set on an existing rule.
* MSFT_xFirewall: Setting a different DisplayName parameter on an existing rule now correctly reports as needs change.
* MSFT_xFirewall: Changed DisplayGroup parameter to Group for consistency with Cmdlets and reduce confusion.
* MSFT_xFirewall: Changing the Group of an existing Firewall rule will recreate the Firewall rule rather than change it.
* MSFT_xFirewall: New parameters added:
    * Authentication
    * Encryption
    * InterfaceAlias
    * InterfaceType
    * LocalAddress
    * LocalUser
    * Package
    * Platform
    * RemoteAddress
    * RemoteMachine
    * RemoteUser
* MSFT_xFirewall: Profile parameter now handled as an Array.

### 2.4.0.0
* Added following resources:
    * MSFT_xDefaultGatewayAddress
* MSFT_xFirewall: Removed code using DisplayGroup to lookup Firewall Rule because it was redundant.
* MSFT_xFirewall: Set-TargetResource now updates firewall rules instead of recreating them.
* MSFT_xFirewall: Added message localization support.
* MSFT_xFirewall: Removed unessesary code for handling multiple rules with same name.
* MSFT_xDefaultGatewayAddress: Removed unessesary try/catch logic from around networking cmdlets.
* MSFT_xIPAddress: Removed unessesary try/catch logic from around networking cmdlets.
* MSFT_xDNSServerAddress: Removed unessesary try/catch logic from around networking cmdlets.
* MSFT_xDefaultGatewayAddress: Refactored to add more unit tests and cleanup logic.
* MSFT_xIPAddress: Network Connection Profile no longer forced to Private when IP address changed.
* MSFT_xIPAddress: Refactored to add more unit tests and cleanup logic.
* MSFT_xDNSServerAddress: Refactored to add more unit tests and cleanup logic.
* MSFT_xFirewall: Refactored to add more unit tests and cleanup logic.
* MSFT_xIPAddress: Removed default gateway parameter - use xDefaultGatewayAddress resource.
* MSFT_xIPAddress: Added check for IP address format not matching address family.
* MSFT_xDNSServerAddress: Corrected error message when address format doesn't match address family.

### 2.3.0.0

* MSFT_xDNSServerAddress: Added support for setting DNS for both IPv4 and IPv6 on the same Interface
* MSFT_xDNSServerAddress: AddressFamily parameter has been changed to mandatory.
* Removed xDscResourceDesigner tests (moved to common tests)
* Fixed Test-TargetResource to test against all provided parameters
* Modified tests to not copy file to Program Files

* Changes to xFirewall causes Get-DSCConfiguration to no longer crash
    * Modified Schema to reduce needed functions.
    * General re-factoring and clean up of xFirewall.
    * Added Unit and Integration tests to resource.

### 2.2.0.0

* Changes in xFirewall resources to meet Test-xDscResource criteria

### 2.1.1.1

* Updated to fix issue with Get-DscConfiguration and xFirewall

### 2.1.0

* Added validity check that IPAddress and IPAddressFamily conforms with each other

### 2.0.0.0

* Adding the xFirewall resource

### 1.0.0.0

* Initial release with the following resources:
    - xIPAddress
    - xDnsServerAddress


## Examples

### Set IP Address on an ethernet NIC

This configuration will set the IP Address with some typical values for a network interface with the alias 'Ethernet'.

```powershell
Configuration Sample_xIPAddress_FixedValue
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )
    Import-DscResource -Module xNetworking
    Node $NodeName
    {
        xIPAddress NewIPAddress
        {
            IPAddress      = "2001:4898:200:7:6c71:a102:ebd8:f482"
            InterfaceAlias = "Ethernet"
            SubnetMask     = 24
            AddressFamily  = "IPV6"
        }
    }
}
```

### Set IP Address with parameterized values

This configuration will set the IP Address on a network interface that is identified by its alias.

``` powershell
Configuration Sample_xIPAddress_Parameterized
{
    param
    (
        [string[]]$NodeName = 'localhost',
        [Parameter(Mandatory)]
        [string]$IPAddress,
        [Parameter(Mandatory)]
        [string]$InterfaceAlias,
        [int]$SubnetMask = 16,
        [ValidateSet("IPv4","IPv6")]
        [string]$AddressFamily = 'IPv4'
    )
    Import-DscResource -Module xNetworking
    Node $NodeName
    {
        xIPAddress NewIPAddress
        {
            IPAddress      = $IPAddress
            InterfaceAlias = $InterfaceAlias
            SubnetMask     = $SubnetMask
            AddressFamily  = $AddressFamily
        }
    }
}
```

### Set DNS server address

This configuration will set the DNS server address on a network interface that is identified by its alias.

```powershell
Configuration Sample_xDnsServerAddress
{
    param
    (
        [string[]]$NodeName = 'localhost',
        [Parameter(Mandatory)]
        [string]$DnsServerAddress,
        [Parameter(Mandatory)]
        [string]$InterfaceAlias,
        [ValidateSet("IPv4","IPv6")]
        [string]$AddressFamily = 'IPv4',
        [Boolean]$Validate
    )
    Import-DscResource -Module xNetworking
    Node $NodeName
    {
        xDnsServerAddress DnsServerAddress
        {
            Address        = $DnsServerAddress
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = $AddressFamily
            Validate       = $Validate
        }
    }
}
```

### Set a DNS connection suffix

This configuration will set a DNS connection-specific suffix on a network interface that is identified by its alias.

```powershell
Configuration Sample_xDnsConnectionSuffix
{
    param
    (
        [string[]]$NodeName = 'localhost',
        [Parameter(Mandatory)]
        [string]$InterfaceAlias,
        [Parameter(Mandatory)]
        [string]$DnsSuffix
    )
    Import-DscResource -Module xNetworking
    Node $NodeName
    {
        xDnsConnectionSuffix DnsConnectionSuffix
        {
            InterfaceAlias           = $InterfaceAlias
            ConnectionSpecificSuffix = $DnsSuffix
        }
    }
}
```

### Set Default Gateway server address

This configuration will set the default gateway address on a network interface that is identified by its alias.

```powershell
Configuration Sample_xDefaultGatewayAddress_Set
{
    param
    (
        [string[]]$NodeName = 'localhost',
        [Parameter(Mandatory)]
        [string]$DefaultGateway,
        [Parameter(Mandatory)]
        [string]$InterfaceAlias,
        [ValidateSet("IPv4","IPv6")]
        [string]$AddressFamily = 'IPv4'
    )
    Import-DscResource -Module xNetworking
    Node $NodeName
    {
        xDefaultGatewayAddress SetDefaultGateway
        {
			Address        = $DefaultGateway
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = $AddressFamily
        }
    }
}
```

### Remove Default Gateway server address

This configuration will remove the default gateway address on a network interface that is identified by its alias.

```powershell
Configuration Sample_xDefaultGatewayAddress_Remove
{
    param
    (
        [string[]]$NodeName = 'localhost',
        [Parameter(Mandatory)]
        [string]$InterfaceAlias,
        [ValidateSet("IPv4","IPv6")]
        [string]$AddressFamily = 'IPv4'
    )
    Import-DscResource -Module xNetworking
    Node $NodeName
    {
        xDefaultGatewayAddress RemoveDefaultGateway
        {
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = $AddressFamily
        }
    }
}
```

### Adding a firewall rule

This configuration will ensure that a firewall rule is present.

```powershell
# DSC configuration for Firewall
Configuration Add_FirewallRule
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xFirewall Firewall
        {
            Name                  = "MyAppFirewallRule"
            Program               = "c:\windows\system32\MyApp.exe"
        }
    }
}
```

### Add a firewall rule to an existing group

This configuration ensures that two firewall rules are present on the target node, both within the same group.

```powershell
Configuration Add_FirewallRuleToExistingGroup
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xFirewall Firewall
        {
            Name                  = "MyFirewallRule"
            DisplayName           = "My Firewall Rule"
            Group                 = "My Firewall Rule Group"
        }

        xFirewall Firewall1
        {
            Name                  = "MyFirewallRule1"
            DisplayName           = "My Firewall Rule"
            Group                 = "My Firewall Rule Group"
            Ensure                = "Present"
            Enabled               = "True"
            Profile               = ("Domain", "Private")
        }
    }
}
```

### Disable access to an application

This example ensures that notepad.exe is blocked by the firewall.
```powershell
Configuration Disable_AccessToApplication
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xFirewall Firewall
        {
            Name                  = "NotePadFirewallRule"
            DisplayName           = "Firewall Rule for Notepad.exe"
            Group                 = "NotePad Firewall Rule Group"
            Ensure                = "Present"
            Action                = 'Blocked'
            Description           = "Firewall Rule for Notepad.exe"
            Program               = "c:\windows\system32\notepad.exe"
        }
    }
}
```

### Disable access with additional parameters

This example will disable notepad.exe's outbound access.

```powershell
# DSC configuration for Firewall

configuration Sample_xFirewall_AddFirewallRule
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xFirewall Firewall
        {
            Name                  = "NotePadFirewallRule"
            DisplayName           = "Firewall Rule for Notepad.exe"
            Group                 = "NotePad Firewall Rule Group"
            Ensure                = "Present"
            Enabled               = "True"
            Profile               = ("Domain", "Private")
            Direction             = "OutBound"
            RemotePort            = ("8080", "8081")
            LocalPort             = ("9080", "9081")
            Protocol              = "TCP"
            Description           = "Firewall Rule for Notepad.exe"
            Program               = "c:\windows\system32\notepad.exe"
            Service               = "WinRM"
        }
    }
 }

Sample_xFirewall_AddFirewallRule
Start-DscConfiguration -Path Sample_xFirewall_AddFirewallRule -Wait -Verbose -Force
```

### Enable a built-in Firewall Rule

This example enables the built-in Firewall Rule 'World Wide Web Services (HTTP Traffic-In)'.
```powershell
configuration Sample_xFirewall_EnableBuiltInFirewallRule
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xFirewall Firewall
        {
            Name                  = "IIS-WebServerRole-HTTP-In-TCP"
            Ensure                = "Present"
            Enabled               = "True"
        }
    }
 }
```

### Create a Firewall Rule using all available Parameters

This example will create a firewall rule using all available xFirewall resource parameters. This rule is not meaningful and would not be used like this in reality. It is used to show the expected formats of the different parameters.
```powershell
configuration Sample_xFirewall_AddFirewallRule_AllParameters
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xFirewall Firewall
        {
            Name                  = "NotePadFirewallRule"
            DisplayName           = "Firewall Rule for Notepad.exe"
            Group                 = "NotePad Firewall Rule Group"
            Ensure                = "Present"
            Enabled               = "True"
            Profile               = ("Domain", "Private")
            Direction             = "OutBound"
            RemotePort            = ("8080", "8081")
            LocalPort             = ("9080", "9081")
            Protocol              = "TCP"
            Description           = "Firewall Rule for Notepad.exe"
            Program               = "c:\windows\system32\notepad.exe"
            Service               = "WinRM"
            Authentication        = "Required"
            Encryption            = "Required"
            InterfaceAlias        = "Ethernet"
            InterfaceType         = "Wired"
            LocalAddress          = @("192.168.2.0-192.168.2.128","192.168.1.0/255.255.255.0")
            LocalUser             = "O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)"
            Package               = "S-1-15-2-3676279713-3632409675-756843784-3388909659-2454753834-4233625902-1413163418"
            Platform              = "6.1"
            RemoteAddress         = @("192.168.2.0-192.168.2.128","192.168.1.0/255.255.255.0")
            RemoteMachine         = "O:LSD:(D;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1621)(A;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1620)"
            RemoteUser            = "O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)"
            DynamicTransport      = "ProximitySharing"
            EdgeTraversalPolicy   = "Block"
            IcmpType              = ("51","52")
            LocalOnlyMapping      = $true
            LooseSourceMapping    = $true
            OverrideBlockRules    = $true
            Owner                 = "S-1-5-21-3337988176-3917481366-464002247-500"
        }
    }
 }

Sample_xFirewall_AddFirewallRule_AllParameters
Start-DscConfiguration -Path Sample_xFirewall_AddFirewallRule_AllParameters -Wait -Verbose -Force
```

### Set the NetConnectionProfile to Public

```powershell
configuration MSFT_xNetConnectionProfile_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xNetConnectionProfile Integration_Test {
            InterfaceAlias   = 'Wi-Fi'
            NetworkCategory  = 'Public'
            IPv4Connectivity = 'Internet'
            IPv6Connectivity = 'Disconncted'
        }
    }
}
```

### Set the DHCP Client state
This example would set the DHCP Client State to enabled.

```powershell
configuration Sample_xDhcpClient_Enabled
{
    param
    (
        [string[]]$NodeName = 'localhost',

        [Parameter(Mandatory)]
        [string]$InterfaceAlias,

        [Parameter(Mandatory)]
        [ValidateSet("IPv4","IPv6")]
        [string]$AddressFamily
    )

    Import-DscResource -Module xDhcpClient

    Node $NodeName
    {
        xDhcpClient EnableDhcpClient
        {
            State          = 'Enabled'
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = $AddressFamily
        }
    }
}
```

### Add a Route
This example will add an IPv4 route on interface Ethernet.

```powershell
configuration Sample_xRoute_AddRoute
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xRoute NetRoute1
        {
            Ensure = 'Present'
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPv4'
            DestinationPrefix = '192.168.0.0/16'
            NextHop = '192.168.120.0'
            RouteMetric = 200
        }
    }
 }

Sample_xRoute_AddRoute
Start-DscConfiguration -Path Sample_xRoute_AddRoute -Wait -Verbose -Force
```

### Create a network team
This example shows creating a native network team.

```powershell
configuration Sample_xNetworkTeam_AddTeam
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xNetworkTeam HostTeam
        {
          Name = 'HostTeam'
          TeamingMode = 'SwitchIndependent'
          LoadBalancingAlgorithm = 'HyperVPort'
          TeamMembers = 'NIC1','NIC2'
          Ensure = 'Present'
        }
    }
 }

Sample_xNetworkTeam_AddTeam
Start-DscConfiguration -Path Sample_xNetworkTeam_AddTeam -Wait -Verbose -Force
```

### Add a hosts file entry
This example will add an hosts file entry.

```powershell
configuration Sample_xHostsFile_AddEntry
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xHostsFile HostEntry
        {
          HostName  = 'Host01'
          IPAddress = '192.168.0.1'
          Ensure    = 'Present'
        }
    }
 }

Sample_xHostsFile_AddEntry
Start-DscConfiguration -Path Sample_xHostsFile_AddEntry -Wait -Verbose -Force
```
