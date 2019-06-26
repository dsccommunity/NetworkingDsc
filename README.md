# NetworkingDsc

The **NetworkingDsc** module contains the following resources:

- **DefaultGatewayAddress**: Sets a node's default gateway address.
- **DnsClientGlobalSetting**: Configure DNS client global settings.
- **DnsConnectionSuffix**: Sets a node's network interface
    connection-specific DNS suffix.
- **DnsServerAddress**: Sets a node's DNS server address(s).
- **Firewall**: Sets a node's firewall rules.
- **FirewallProfile**: Configures a node's private, public or domain firewall profile.
- **HostsFile**: Adds, edits or removes entries from the hosts file on a node.
- **IPAddress**: Sets a node's IP address(s).
- **IPAddressOption**: Sets an IP address option.
- **NetAdapterAdvancedProperty**: Sets advanced properties on a network adapter.
- **NetAdapterBinding**: Bind or unbind transport or filters to a network interface.
- **NetAdapterLso**: Enable or disable Lso for different protocols
    on a network adapter.
- **NetAdapterName**: Rename a network interface that matches specified search parameters.
- **NetAdapterRdma**: Enable or disable RDMA on a network adapter.
- **NetAdapterRsc**: Enable or disable Rsc for different protocols
    on a network adapter.
- **NetAdapterRss**: Enable or disable Rss on a network adapter.
- **NetBios**: Enable or Disable NetBios on a network interface.
- **NetConnectionProfile**: Sets a node's connection profile.
- **NetIPInterface**: Configure the IP interface settings for a network interface.
- **NetworkTeam**: Set up network teams on a node.
- **NetworkTeamInterface**: Add network interfaces to a network team.
- **ProxySettings**: Configures the proxy settings for the computer.
- **Route**: Sets static routes on a node.
- **WaitForNetworkTeam**: Wait for a network team to achieve the 'Up' status.
- **WinsSetting**: Configure the WINS settings that enable or disable LMHOSTS lookups
  and enable or disable DNS for name resolution over WINS.
- **WinsServerAddress**: Sets a node's WINS server address(s).

This project has adopted [this code of conduct](CODE_OF_CONDUCT.md).

## Documentation and Examples

For a full list of resources in NetworkingDsc and examples on their use, check out
the [NetworkingDsc wiki](https://github.com/PowerShell/NetworkingDsc/wiki).

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/obmudad7gy8usbx2/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/NetworkingDsc/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/NetworkingDsc/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/NetworkingDsc/branch/master)

This is the branch containing the latest release - no contributions should be made
directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/obmudad7gy8usbx2/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/NetworkingDsc/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/NetworkingDsc/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/NetworkingDsc/branch/dev)

This is the development branch to which contributions should be proposed by contributors
as pull requests. This development branch will periodically be merged to the master
branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Known Issues

### Firewall Known Issues

The following error may occur when using the resource Firewall in configurations
on Windows Server 2012 R2 if [KB3000850](https://support.microsoft.com/en-us/kb/3000850)
is not installed. Please ensure this update is installed if this error occurs.

````markdown
    The cmdlet does not fully support the Inquire action for debug messages.
    Cmdlet operation will continue during the prompt. Select a different action
    preference via -Debug switch or $DebugPreference variable, and try again.
````

### Known Invalid Configuration

- The exception 'One of the port keywords is invalid' will be thrown if a rule
    is created with the LocalPort set to PlayToDiscovery and the Protocol is not
    set to UDP. This is not an unexpected error, but because the
    New-NetFirewallRule documentation is incorrect.

This issue has been reported on [Microsoft Connect](https://connect.microsoft.com/PowerShell/feedbackdetail/view/1974268/new-set-netfirewallrule-cmdlet-localport-parameter-documentation-is-incorrect-for-playtodiscovery)
