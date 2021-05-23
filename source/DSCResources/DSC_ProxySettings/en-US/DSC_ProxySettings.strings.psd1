# Localized resources for DSC_ProxySettings

ConvertFrom-StringData @'
    GettingProxySettingsMessage = Getting the computer proxy settings.
    ApplyingProxySettingsMessage = Applying the computer proxy settings to ensure '{0}'.
    CheckingProxySettingsMessage = Checking the computer proxy settings to ensure '{0}'.
    ProxyBinarySettingsRequiresRemovalMessage = The computer proxy settings '{0}' need to be removed.
    CheckingProxyBinarySettingsMessage = Checking that the computer proxy settings '{0}' are in the desired state.
    ProxyBinarySettingsNoMatchMessage = Computer proxy settings '{0}' are not in the desired state.
    DisablingProxyMessage = Disabling computer proxy settings.
    EnablingProxyMessage = Enabling computer proxy settings.
    ProxySettingMismatchMessage = The proxy setting '{0}' value '{1}' does not match the desired value '{2}'.
    WritingProxyBinarySettingsMessage = Writing computer proxy settings '{0}' binary '{1}'.
    ProxySettingsBinaryInvalidError = The first byte of the proxy settings binary was '{0}' but should have been 0x46.
'@
