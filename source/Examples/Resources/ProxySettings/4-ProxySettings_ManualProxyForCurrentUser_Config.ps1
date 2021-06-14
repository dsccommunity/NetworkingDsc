<#PSScriptInfo
.VERSION 1.0.0
.GUID f066cc99-4b79-4e43-8244-ca0396cd9e01
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/NetworkingDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/NetworkingDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module NetworkingDsc

<#
    .DESCRIPTION
    Sets a user account to use a manually configured proxy server
    with the address 'proxy.contoso.com' on port 8888. Traffic to addresses
    starting with 'web1' or 'web2' or any local addresses will not be sent
    to the proxy.

    The user account that the proxy settings are configured for will be the account
    that applies the resource.
#>
Configuration ProxySettings_ManualProxyForCurrentUser_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        ProxySettings ManualProxy
        {
            Target                  = 'CurrentUser'
            Ensure                  = 'Present'
            EnableAutoDetection     = $false
            EnableAutoConfiguration = $false
            EnableManualProxy       = $true
            ProxyServer             = 'proxy.contoso.com:8888'
            ProxyServerExceptions   = 'web1', 'web2'
            ProxyServerBypassLocal  = $true
        }
    }
}
