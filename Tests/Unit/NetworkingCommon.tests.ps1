$script:DSCModuleName      = 'xNetworking'
$script:DSCResourceName    = 'NetworkingCommon'

#region HEADER
# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    $LocalizedData = InModuleScope $script:DSCResourceName {
        $LocalizedData
    }

    #region Function Convert-CIDRToSubhetMask
    Describe "MSFT_xFirewall\Convert-CIDRToSubhetMask" {
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
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion

}
