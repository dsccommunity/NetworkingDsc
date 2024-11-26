# Localized resources for NetworkingDsc

ConvertFrom-StringData @'
    # Find-NetworkAdapter
    AllNetAdaptersFoundMessage           = Found all network adapters because no filter parameters provided. (NET0002)
    FindingNetAdapterMessage             = Finding network adapters matching the parameters. (NET0001)
    NetAdapterNotFoundError              = A network adapter matching the parameters was not found. Please correct the properties and try again. (NET0004)
    NetAdapterFoundMessage               = {0} network adapters were found matching the parameters. (NET0003)
    InvalidNetAdapterNumberError         = network adapter interface number {0} was specified but only {1} was found. Please correct the interface number and try again. (NET0007)
    MultipleMatchingNetAdapterFound      = Please adjust the parameters or specify IgnoreMultipleMatchingAdapters to only use the first and try again. (NET0006)

    # Get-DnsClientServerStaticAddress
    GettingDNSServerStaticAddressMessage = Getting statically assigned DNS server {0} address for interface alias '{1}'. (NET0008)
    InterfaceAliasNotFoundError          = A network adapter with the alias '{0}' could not be found. (NET0005)
    DNSServerStaticAddressNotSetMessage  = Statically assigned DNS server {0} address for interface alias '{1}' is not set. (NET0011)
    DNSServerStaticAddressFoundMessage   = Statically assigned DNS server {0} address for interface alias '{1}' is '{2}'. (NET0013)

    # Get-WinsClientServerStaticAddress
    GettingWinsServerStaticAddressMessage = Getting statically assigned WINS server address for interface alias '{0}'. (NET0009)
    WinsServerStaticAddressNotSetMessage  = Statically assigned WINS server address for interface alias '{0}' is not set. (NET0012)
    WinsServerStaticAddressFoundMessage   = Statically assigned WINS server address for interface alias '{0}' is '{1}'. (NET0014)

    # Set-WinsClientServerStaticAddress
    SettingWinsServerStaticAddressMessage = Setting statically assigned WINS server address for interface alias '{0}' to '{1}'. (NET0010)
'@
