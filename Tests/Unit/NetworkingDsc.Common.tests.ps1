$script:ModuleName = 'NetworkingDsc.Common'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath $script:ModuleName)) -ChildPath "$script:ModuleName.psm1") -Force
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    $LocalizedData = InModuleScope $script:ModuleName {
        $LocalizedData
    }

    #region Function Convert-CIDRToSubhetMask
    Describe "NetworkingDsc.Common\Convert-CIDRToSubhetMask" {
        Context 'Subnet Mask Notation Used "192.168.0.0/255.255.0.0"' {
            It 'Should Return "192.168.0.0/255.255.0.0"' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.0/255.255.0.0') | Should Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'Subnet Mask Notation Used "192.168.0.10/255.255.0.0" resulting in source bits masked' {
            It 'Should Return "192.168.0.0/255.255.0.0" with source bits masked' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.10/255.255.0.0') | Should Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'CIDR Notation Used "192.168.0.0/16"' {
            It 'Should Return "192.168.0.0/255.255.0.0"' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.0/16') | Should Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'CIDR Notation Used "192.168.0.10/16" resulting in source bits masked' {
            It 'Should Return "192.168.0.0/255.255.0.0" with source bits masked' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.10/16') | Should Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'Multiple Notations Used "192.168.0.0/16,10.0.0.24/255.255.255.0"' {
            $Result = Convert-CIDRToSubhetMask -Address @('192.168.0.0/16','10.0.0.24/255.255.255.0')
            It 'Should Return "192.168.0.0/255.255.0.0,10.0.0.0/255.255.255.0"' {
                $Result[0] | Should Be '192.168.0.0/255.255.0.0'
                $Result[1] | Should Be '10.0.0.0/255.255.255.0'
            }
        }
        Context 'Range Used "192.168.1.0-192.168.1.128"' {
            It 'Should Return "192.168.1.0-192.168.1.128"' {
                Convert-CIDRToSubhetMask -Address @('192.168.1.0-192.168.1.128') | Should Be '192.168.1.0-192.168.1.128'
            }
        }
        Context 'IPv6 Used "fe80::/112"' {
            It 'Should Return "fe80::/112"' {
                Convert-CIDRToSubhetMask -Address @('fe80::/112') | Should Be 'fe80::/112'
            }
        }
    }
    #endregion

    #region Function Get-IPAddressPrefix
    Describe "NetworkingDsc.Common\Get-IPAddressPrefix" {
        Context 'IPv4 CIDR notation provided' {
            it 'Should return the provided IP and prefix as separate properties' {
                $IPaddress = Get-IPAddressPrefix -IPAddress '192.168.10.0/24'

                $IPaddress.IPaddress | Should be '192.168.10.0'
                $IPaddress.PrefixLength | Should be 24
            }
        }

        Context 'IPv4 Class A address with no CIDR notation' {
            it 'Should return correct prefix when Class A address provided' {
                $IPaddress = Get-IPAddressPrefix -IPAddress '10.1.2.3'

                $IPaddress.IPaddress | Should be '10.1.2.3'
                $IPaddress.PrefixLength | Should be 8
            }
        }

        Context 'IPv4 Class B address with no CIDR notation' {
            it 'Should return correct prefix when Class B address provided' {
                $IPaddress = Get-IPAddressPrefix -IPAddress '172.16.2.3'

                $IPaddress.IPaddress | Should be '172.16.2.3'
                $IPaddress.PrefixLength | Should be 16
            }
        }

        Context 'IPv4 Class C address with no CIDR notation' {
            it 'Should return correct prefix when Class C address provided' {
                $IPaddress = Get-IPAddressPrefix -IPAddress '192.168.20.3'

                $IPaddress.IPaddress | Should be '192.168.20.3'
                $IPaddress.PrefixLength | Should be 24
            }
        }

        Context 'IPv6 CIDR notation provided' {
            it 'Should return provided IP and prefix as separate properties' {
                $IPaddress = Get-IPAddressPrefix -IPAddress 'FF12::12::123/64' -AddressFamily IPv6

                $IPaddress.IPaddress | Should be 'FF12::12::123'
                $IPaddress.PrefixLength | Should be 64
            }
        }

        Context 'IPv6 with no CIDR notation provided' {
            it 'Should return provided IP and correct IPv6 prefix' {
                $IPaddress = Get-IPAddressPrefix -IPAddress 'FF12::12::123' -AddressFamily IPv6

                $IPaddress.IPaddress | Should be 'FF12::12::123'
                $IPaddress.PrefixLength | Should be 64
            }
        }
    }
}
finally
{
    #region FOOTER
    #endregion
}
