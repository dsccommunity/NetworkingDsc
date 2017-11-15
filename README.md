# xNetworking

The **xNetworking** module contains the following resources:

- **xFirewall**: Sets a node's firewall rules.
- **xIPAddress**: Sets a node's IP address(s).
- **xDnsServerAddress**: Sets a node's DNS server address(s).
- **xDnsConnectionSuffix**: Sets a node's network interface
    connection-specific DNS suffix.
- **xDefaultGatewayAddress**: Sets a node's default gateway address.
- **xNetConnectionProfile**: Sets a node's connection profile.
- **xDhcpClient**: Enable or Disable DHCP on an network interface.
- **xRoute**: Sets static routes on a node.
- **xNetBIOS**: Enable or Disable NetBios on a network interface.
- **xNetworkTeam**: Set up network teams on a node.
- **xNetworkTeamInterface**: Add network interfaces to a network team.
- **xHostsFile**: Adds, edits or removes entries from the hosts file on a node.
- **xNetAdapterBinding**: Bind or unbind transport or filters to a network interface.
- **xDnsClientGlobalSetting**: Configure DNS client global settings.
- **xNetAdapterRDMA**: Enable or disable RDMA on a network adapter.
- **xNetAdapterLso**: Enable or disable Lso for different protocols
    on a network adapter.
- **xNetAdapterRsc**: Enable or disable Rsc for different protocols
    on a network adapter.
- **xNetAdapterRss**: Enable or disable Rss on a network adapter.
- **xNetAdapterName**: Rename a network interface that matches specified search parameters.
- **xFirewallProfile**: Configures a node's private, public or domain firewall profile.
- **xProxySettings**: Configures the proxy settings for the computer.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.

## Documentation and Examples

For a full list of resources in xNetworking and examples on their use, check out
the [xNetworking wiki](https://github.com/PowerShell/xNetworking/wiki).

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/obmudad7gy8usbx2/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xNetworking/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/xNetworking/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/xNetworking/branch/master)

This is the branch containing the latest release - no contributions should be made
directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/obmudad7gy8usbx2/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/xNetworking/branch/dev)[![codecov](https://codecov.io/gh/PowerShell/xNetworking/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/xNetworking/branch/dev)

This is the development branch to which contributions should be proposed by contributors
as pull requests. This development branch will periodically be merged to the master
branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Known Issues

### xFirewall Known Issues

The following error may occur when applying xFirewall configurations on Windows
Server 2012 R2 if [KB3000850](https://support.microsoft.com/en-us/kb/3000850) is
not installed. Please ensure this update is installed if this error occurs.

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
