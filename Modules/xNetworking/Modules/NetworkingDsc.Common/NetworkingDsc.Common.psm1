# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.ResourceHelper' `
                                                     -ChildPath 'NetworkingDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'NetworkingDsc.Common' `
    -ResourcePath $PSScriptRoot

<#
    .SYNOPSIS
    Converts any IP Addresses containing CIDR notation filters in an array to use Subnet Mask
    notation.

    .PARAMETER Address
    The array of addresses to that need to be converted.
#>
function Convert-CIDRToSubhetMask
{
    [CmdletBinding()]
    [OutputType([ Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Address
    )

    $Results = @()
    foreach ($Entry in $Address)
    {
        if (-not $Entry.Contains(':') -and -not $Entry.Contains('-'))
        {
            $EntrySplit = $Entry -split '/'
            if (-not [String]::IsNullOrEmpty($EntrySplit[1]))
            {
                # There was a / so this contains a Subnet Mask or CIDR
                $Prefix = $EntrySplit[0]
                $Postfix = $EntrySplit[1]
                if ($Postfix -match '^[0-9]*$')
                {
                    # The postfix contains CIDR notation so convert this to Subnet Mask
                    $Cidr = [Int] $Postfix
                    $SubnetMaskInt64 = ([convert]::ToInt64(('1' * $Cidr + '0' * (32 - $Cidr)), 2))
                    $SubnetMask = @(
                            ([math]::Truncate($SubnetMaskInt64 / 16777216))
                            ([math]::Truncate(($SubnetMaskInt64 % 16777216) / 65536))
                            ([math]::Truncate(($SubnetMaskInt64 % 65536)/256))
                            ([math]::Truncate($SubnetMaskInt64 % 256))
                        )
                }
                else
                {
                    $SubnetMask = $Postfix -split '\.'
                }
                # Apply the Subnet Mast to the IP Address so that we end up with a correctly
                # masked IP Address that will match what the Firewall rule returns.
                $MaskedIp = $Prefix -split '\.'
                for ([int] $Octet = 0; $Octet -lt 4; $Octet++)
                {
                    $MaskedIp[$Octet] = $MaskedIp[$Octet] -band $SubnetMask[$Octet]
                }
                $Entry = '{0}/{1}' -f ($MaskedIp -join '.'),($SubnetMask -join '.')
            }
        }
        $Results += $Entry
    }
    return $Results
}

Export-ModuleMember -Function `
    Convert-CIDRToSubhetMask
