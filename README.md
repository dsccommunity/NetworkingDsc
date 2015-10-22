[![Build status](https://ci.appveyor.com/api/projects/status/obmudad7gy8usbx2/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xnetworking/branch/master)

# xNetworking

The **xNetworking** module contains the **xFirewall, xIPAddress** and **xDnsServerAddress** DSC resources for configuring a node’s IP address, DNS server address, and firewall rules.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).


## Resources

* **xFirewall** sets a node's firewall rules.
* **xIPAddress** sets a node's IP address.
* **xDnsServerAddress** sets a node's DNS server.
* **xDefaultGatewayAddress** sets a node's default gateway address.

### xIPAddress

* **IPAddress**: The desired IP address.
* **InterfaceAlias**: Alias of the network interface for which the IP address should be set.
* **SubnetMask**: Local subnet size.
* **AddressFamily**: IP address family: { IPv4 | IPv6 }

### xDnsServerAddress

* **Address**: The desired DNS Server address(es)
* **InterfaceAlias**: Alias of the network interface for which the DNS server address is set.
* **AddressFamily**: IP address family: { IPv4 | IPv6 }

### xDefaultGatewayAddress

* **Address**: The desired default gateway address - if not provided default gateway will be removed.
* **InterfaceAlias**: Alias of the network interface for which the default gateway address is set.
* **AddressFamily**: IP address family: { IPv4 | IPv6 }

### xFirewall

* **Name**: Name of the firewall rule
* **DisplayName**: Localized, user-facing name of the firewall rule being created .
* **DisplayGroup**: Name of the firewall group where we want to put the firewall rules.
* **Ensure**: Ensure that the firewall rule is Present or Absent.
* **Enabled**: Enable or Disable the supplied configuration.
* **Action**: Permit or Block the supplied configuration
* **Profile**: Specifies one or more profiles to which the rule is assigned.
* **Direction**: Direction of the connection.
* **RemotePort**: Specific port used for filter. Specified by port number, range, or keyword.
* **LocalPort**: Local port used for the filter.
* **Protocol**: Specific protocol for filter. Specified by name, number, or range.
* **Description**: Documentation for the rule.
* **ApplicationPath**: Path and filename of the program for which the rule is applied.
* **Service**: Specifies the short name of a Windows service to which the firewall rule applies.

## Versions

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
        [string]$AddressFamily = 'IPv4'
    )
    Import-DscResource -Module xNetworking
    Node $NodeName
    {
        xDnsServerAddress DnsServerAddress
        {
            Address        = $DnsServerAddress
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = $AddressFamily
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
            ApplicationPath       = "c:\windows\system32\MyApp.exe"
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
            DisplayGroup          = "My Firewall Rule Group"
        }

        xFirewall Firewall1
        {
            Name                  = "MyFirewallRule1"
            DisplayName           = "My Firewall Rule"
            DisplayGroup          = "My Firewall Rule Group"
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
            DisplayGroup          = "NotePad Firewall Rule Group"
            Ensure                = "Present"
            Action                = 'Blocked'
            Description           = "Firewall Rule for Notepad.exe"
            ApplicationPath       = "c:\windows\system32\notepad.exe"
        }
    }
}
```

### Disable access with additional parameters

This example will disable notepad.exe's outbound access.

```powershell
Configuration Sample_xFirewall
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
            DisplayGroup          = "NotePad Firewall Rule Group"
            Ensure                = "Present"
            Enabled               = "True"
            Action                = 'Allow'
            Profile               = ("Domain", "Private")
            Direction             = "OutBound"
            RemotePort            = ("8080", "8081")
            LocalPort             = ("9080", "9081")
            Protocol              = "TCP"
            Description           = "Firewall Rule for Notepad.exe"
            ApplicationPath       = "c:\windows\system32\notepad.exe"
            Service               =  "WinRM"
        }
    }
 }

Sample_xFirewall
Start-DscConfiguration -Path Sample_xFirewall -Wait -Verbose -Force
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
