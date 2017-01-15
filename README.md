# xNetworking

[![Build status](https://ci.appveyor.com/api/projects/status/obmudad7gy8usbx2/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xnetworking/branch/master)

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

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.

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

### Known Invalid Configuraiton

- The exception 'One of the port keywords is invalid' will be thrown if a rule
    is created with the LocalPort set to PlayToDiscovery and the Protocol is not
    set to UDP. This is not an unexpected error, but because the
    New-NetFirewallRule documentation is incorrect.

This issue has been reported on [Microsoft Connect](https://connect.microsoft.com/PowerShell/feedbackdetail/view/1974268/new-set-netfirewallrule-cmdlet-localport-parameter-documentation-is-incorrect-for-playtodiscovery)
