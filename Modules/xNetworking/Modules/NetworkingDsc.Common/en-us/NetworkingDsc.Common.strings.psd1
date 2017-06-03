ConvertFrom-StringData @'
    FindingNetAdapterMessage = Finding Network Adapters matching the parameters.
    NetAdapterFoundMessage = {0} Network Adapters were found matching the parameters.
    NetAdapterParameterError = At least one Network Adapter parameter must be passed.
    NetAdapterNotFoundError = A Network Adapter matching the parameters was not found. Please correct the properties and try again.
    InterfaceAliasNotFoundError = A network adapter with the alias '{0}' could not be found.
    MultipleMatchingNetAdapterFound = Please adjust the parameters or specify IgnoreMultipleMatchingAdapters to only use the first and try again.
    InvalidNetAdapterNumberError = Network Adapter interface number {0} was specified but only {1} was found. Please correct the interface number and try again.
    GettingDNSServerStaticAddressMessage = Getting staticly assigned DNS server {0} address for interface alias '{1}'.
    DNSServerStaticAddressNotSetMessage = Statically assigned DNS server {0} address for interface alias '{1}' is not set.
    DNSServerStaticAddressFoundMessage = Statically assigned DNS server {0} address for interface alias '{1}' is '{2}'.
'@
