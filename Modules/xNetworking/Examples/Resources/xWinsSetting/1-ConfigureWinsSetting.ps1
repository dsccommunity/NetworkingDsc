<#
    .EXAMPLE
    Disable LMHOSTS lookup and disable using DNS for WINS name resolution.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -Module xNetworking

    Node $NodeName
    {
        xWinsSetting ConfigureWinsSettings
        {
            IsSingleInstance = 'Yes'
            EnableLMHOSTS    = $false
            EnableDNS        = $false
        }
    }
}
