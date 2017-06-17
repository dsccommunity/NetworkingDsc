ConvertFrom-StringData @'
    FindingNetAdapterMessage = Finding network adapters matching the parameters.
    AllNetAdaptersFoundMessage = Found all network adapters because no filter parameters provided.
    NetAdapterFoundMessage = {0} network adapters were found matching the parameters.
    NetAdapterNotFoundError = A network adapter matching the parameters was not found. Please correct the properties and try again.
    InterfaceAliasNotFoundError = A network adapter with the alias '{0}' could not be found.
    MultipleMatchingNetAdapterFound = Please adjust the parameters or specify IgnoreMultipleMatchingAdapters to only use the first and try again.
    InvalidNetAdapterNumberError = network adapter interface number {0} was specified but only {1} was found. Please correct the interface number and try again.
    TestDscParameterState_DesiredValueWrongType = Property 'DesiredValues' in Test-DscParameterState must be either a Hashtable or CimInstance. Type detected was '{0}'.
    TestDscParameterState_DesiredValueIsCimInstanceAndNotValueToCheck = If 'DesiredValues' is a CimInstance then property 'ValuesToCheck' must contain a value.
    TestDscParameterState_Match = MATCH: Value (type {0}) for property '{1}' does match. Current state is '{2}' and desired state is '{3}'"
    TestDscParameterState_MatchArrayElement = "`tMATCH: Value [{0}] (type {1}) for property '{2}' does match. Current state is '{3}' and desired state is '{4}'
    TestDscParameterState_NotMatchTypeMismatch = NOTMATCH: Type mismatch for property '{0}' Current state type is '{1}' and desired type is '{2}'
    TestDscParameterState_NotMatchArrayElementTypeMismatch = "`tNOTMATCH: Type mismatch for property '{0}' Current state type of element [{1}] is '{2}' and desired type is '{3}'
    TestDscParameterState_NotMatch = NOTMATCH: Value (type {0}) for property '{1}' does not match. Current state is '{2}' and desired state is '{3}'
    TestDscParameterState_NotMatchArrayElement = `tNOTMATCH: Value [{0}] (type {1}) for property '{2}' does match. Current state is '{3}' and desired state is '{4}'
    TestDscParameterState_NotMatchDifferentCount = "NOTMATCH: Value (type {0}) for property '{1}' does have a different count. Current state count is '{2}' and desired state count is '{3}'
    GettingDNSServerStaticAddressMessage = Getting staticly assigned DNS server {0} address for interface alias '{1}'.
    DNSServerStaticAddressNotSetMessage = Statically assigned DNS server {0} address for interface alias '{1}' is not set.
    DNSServerStaticAddressFoundMessage = Statically assigned DNS server {0} address for interface alias '{1}' is '{2}'.
'@
