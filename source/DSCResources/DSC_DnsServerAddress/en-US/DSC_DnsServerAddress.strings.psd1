# Localized resources for DSC_DnsServerAddress

ConvertFrom-StringData @'
    GettingDnsServerAddressesMessage      = Getting the DNS server addresses.
    ApplyingDnsServerAddressesMessage     = Applying the {0} DNS server addresses "{1}" to "{2}".
    DNSServersSetCorrectlyMessage         = DNS server addresses are set correctly.
    CheckingDnsServerAddressesMessage     = Checking the DNS server addresses.
    DNSServersNotCorrectMessage           = DNS server addresses are not correct. Expected "{0}", actual "{1}".
    DNSServersHaveBeenSetCorrectlyMessage = DNS server addresses were set to the desired state.
    InterfaceNotAvailableError            = Interface "{0}" is not available. Please select a valid interface and try again.
    DNSServerValidationError              = DNS server addresses "{0}" failed validation.
    SetDNSServerAddressesError            = Failed to set DNS server addresses "{0}". Exception: {1}
'@
