<#
    .EXAMPLE
    Sets the computer to use an automatic WPAD configuration script that will
    be downloaded from the URL 'http://wpad.contoso.com/wpad.dat'.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xProxySettings AutoConfigurationProxy
        {
            IsSingleInstance        = 'Yes'
            Ensure                  = 'Present'
            EnableAutoDetection     = $false
            EnableAutoConfiguration = $true
            EnableManualProxy       = $false
            AutoConfigURL           = 'http://wpad.contoso.com/wpad.dat'
        }
    }
}
