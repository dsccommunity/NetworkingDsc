<#
    .EXAMPLE
    Sets the computer to automatically detect the proxy settings.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName NetworkingDsc

    Node $NodeName
    {
        ProxySettings AutoConfigurationProxy
        {
            IsSingleInstance        = 'Yes'
            Ensure                  = 'Present'
            EnableAutoDetection     = $true
            EnableAutoConfiguration = $false
            EnableManualProxy       = $false
        }
    }
}
