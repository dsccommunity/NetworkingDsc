# Localized resources for DSC_ProxySettings

ConvertFrom-StringData @'
    GettingProxySettingsMessage = Getting the {0} proxy settings.
    ApplyingProxySettingsMessage = Applying the {0} proxy settings to ensure '{1}'.
    CheckingProxySettingsMessage = Checking the {0} proxy settings to ensure '{1}'.
    ProxyBinarySettingsRequiresRemovalMessage = The {0} proxy settings '{1}' need to be removed.
    CheckingProxyBinarySettingsMessage = Checking that the {0} proxy settings '{1}' are in the desired state.
    ProxyBinarySettingsNoMatchMessage = {0} proxy settings '{1}' are not in the desired state.
    DisablingProxyMessage = Disabling {0} proxy settings.
    EnablingProxyMessage = Enabling {0} proxy settings.
    ProxySettingMismatchMessage = The proxy setting '{0}' value '{1}' does not match the desired value '{2}'.
    WritingProxyBinarySettingsMessage = Writing {0} proxy settings '{0}' binary '{1}'.
    ProxySettingsBinaryInvalidError = The first byte of the proxy settings binary was '{0}' but should have been 0x46.
'@
