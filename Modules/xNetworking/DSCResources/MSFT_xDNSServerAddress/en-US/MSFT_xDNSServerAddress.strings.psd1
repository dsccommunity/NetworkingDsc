# Localized resources for MSFT_xDNSServerAddress

ConvertFrom-StringData @'
    GettingDNSServerAddressesMessage      = Getting the DNS server addresses.
    ApplyingDNSServerAddressesMessage     = Applying the DNS server addresses.
    DNSServersSetCorrectlyMessage         = DNS server addresses are set correctly.
    DNSServersAlreadySetMessage           = DNS server addresses are already set correctly.
    CheckingDNSServerAddressesMessage     = Checking the DNS server addresses.
    DNSServersNotCorrectMessage           = DNS server addresses are not correct. Expected "{0}", actual "{1}".
    DNSServersHaveBeenSetCorrectlyMessage = DNS server addresses were set to the desired state.
    DNSServersHaveBeenSetToDHCPMessage    = DNS server addresses were set to the desired state of DHCP.
    InterfaceNotAvailableError            = Interface "{0}" is not available. Please select a valid interface and try again.
    AddressFormatError                    = Address "{0}" is not in the correct format. Please correct the Address parameter in the configuration and try again.
    AddressIPv4MismatchError              = Address "{0}" is in IPv4 format, which does not match server address family {1}. Please correct either of them in the configuration and try again.
    AddressIPv6MismatchError              = Address "{0}" is in IPv6 format, which does not match server address family {1}. Please correct either of them in the configuration and try again.
'@
