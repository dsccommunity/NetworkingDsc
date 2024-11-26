<#
    .SYNOPSIS
        Converts any IP Addresses containing CIDR notation filters in an array to use Subnet Mask
        notation.

    .PARAMETER Address
        The array of addresses to that need to be converted.
#>
function Convert-CIDRToSubnetMask
{
    [CmdletBinding()]
    [OutputType([ Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Address
    )

    $results = @()

    foreach ($entry in $Address)
    {
        if (-not $entry.Contains(':') -and -not $entry.Contains('-'))
        {
            $entrySplit = $entry -split '/'

            if (-not [String]::IsNullOrEmpty($entrySplit[1]))
            {
                # There was a / so this contains a Subnet Mask or CIDR
                $prefix = $entrySplit[0]
                $postfix = $entrySplit[1]

                if ($postfix -match '^[0-9]*$')
                {
                    # The postfix contains CIDR notation so convert this to Subnet Mask
                    $cidr = [System.Int32] $postfix
                    $subnetMaskInt64 = ([convert]::ToInt64(('1' * $cidr + '0' * (32 - $cidr)), 2))
                    $subnetMask = @(
                        ([math]::Truncate($subnetMaskInt64 / 16777216))
                        ([math]::Truncate(($subnetMaskInt64 % 16777216) / 65536))
                        ([math]::Truncate(($subnetMaskInt64 % 65536) / 256))
                        ([math]::Truncate($subnetMaskInt64 % 256))
                    )
                }
                else
                {
                    $subnetMask = $postfix -split '\.'
                }

                <#
                        Apply the Subnet Mast to the IP Address so that we end up with a correctly
                        masked IP Address that will match what the Firewall rule returns.
                #>
                $maskedIp = $prefix -split '\.'

                for ([System.Int32] $Octet = 0; $octet -lt 4; $octet++)
                {
                    $maskedIp[$Octet] = $maskedIp[$octet] -band $SubnetMask[$octet]
                }

                $entry = '{0}/{1}' -f ($maskedIp -join '.'), ($subnetMask -join '.')
            }
        }

        $results += $entry
    }

    return $results
}
