<#
    .SYNOPSIS
        Gets the IP Address prefix from a provided IP Address in CIDR notation.

    .PARAMETER IPAddress
        IP Address to get prefix for, can be in CIDR notation.

    .PARAMETER AddressFamily
        Address family for provided IP Address, defaults to IPv4.

#>
function Get-IPAddressPrefix
{
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline)]
        [System.String[]]
        $IPAddress,

        [Parameter()]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily = 'IPv4'
    )

    process
    {
        foreach ($singleIP in $IPAddress)
        {
            $prefixLength = ($singleIP -split '/')[1]

            if (-not ($prefixLength) -and $AddressFamily -eq 'IPv4')
            {
                if ($singleIP.split('.')[0] -in (0..127))
                {
                    $prefixLength = 8
                }
                elseif ($singleIP.split('.')[0] -in (128..191))
                {
                    $prefixLength = 16
                }
                elseif ($singleIP.split('.')[0] -in (192..223))
                {
                    $prefixLength = 24
                }
            }
            elseif (-not ($prefixLength) -and $AddressFamily -eq 'IPv6')
            {
                $prefixLength = 64
            }

            [PSCustomObject]@{
                IPAddress    = $singleIP.split('/')[0]
                prefixLength = $prefixLength
            }
        }
    }
}
