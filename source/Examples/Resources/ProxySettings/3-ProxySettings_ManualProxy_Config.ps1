<#PSScriptInfo
.VERSION 2.0.0
.GUID b16d59df-5a59-4592-8033-46e1daee24c3
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
    Sets the computer to use a manually configured proxy server
    with the address 'proxy.contoso.com' on port 8888. Traffic to addresses
    starting with 'web1' or 'web2' or any local addresses will not be sent
    to the proxy.
#>
Configuration ProxySettings_ManualProxy_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        ProxySettings ManualProxy
        {
            Target                  = 'LocalMachine'
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
