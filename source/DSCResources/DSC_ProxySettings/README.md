# Description

The resource is used to configure internet proxy settings for a computer
(`LocalMachine`) or a user account (`CurrentUser`).

## Target

The `Target` parameter is used to specify whether to configure the proxy
settings for the machine or for a specific user account.

If the `Target` is set to `CurrentUser` then the proxy settings will be
configured for the user account that the resource runs under. This is
usually the account the DSC Local Configuration Manager runs under,
which is `LocalSystem`.

You can configure the proxy settings on a different user account by
specifying the `PsDscRunAsCredential` in the resource configuration.

See [this page](https://docs.microsoft.com/en-us/powershell/scripting/dsc/configurations/runasuser)
for more information.
