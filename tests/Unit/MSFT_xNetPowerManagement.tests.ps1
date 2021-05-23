$script:DSCModuleName      = 'xNetworking'
$script:DSCResourceName    = 'MSFT_xNetPowerManagement'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
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
    InModuleScope $script:DSCResourceName {

        Describe "MSFT_xNetPowerManagement\Get-TargetResource" {
            Mock Get-NetPowerManagement {
                return @{
                    AdapterType = 'Ethernet 802.3'
					State = $true
                }
            }
            $expected = @()
			$expected.AdpaterType = 'Ethernet 802.3'
			$expected.State = $true

            $result = Get-TargetResource -InterfaceAlias $expected.InterfaceAlias

            It 'Should return the correct values' {
                $expected.AdpaterType   | Should Be $result.AdapterType
                $expected.State  | Should Be $result.State
            }
        }

        Describe "MSFT_xNetPowerManagement\Test-TargetResource" {
            $Splat = @{
                AdapterType = 'Ethernet 802.3'
				State = $true
            }

            Context 'AdapterType is incorrect' {
                $incorrect = $Splat.Clone()
                $incorrect.AdapterType = 'Ethernet 802.3'
                Mock Get-TargetResource {
                    return $incorrect
                }

                It 'should return Ethernet 802.3' {
                    Test-TargetResource @Splat | should be 'Ethernet 802.3'
                }
            }

           Context 'State is incorrect' {
                $incorrect = $Splat.Clone()
                $incorrect.State = $false
                Mock Get-TargetResource {
                    return $incorrect
                }

                It 'should return true' {
                    Test-TargetResource @Splat | should be $true
                }
            }

        Describe "MSFT_xNetPowerManagement\Set-TargetResource" {
            It 'Should do call all the mocks' {
                $Splat = @{
					$incorrect = $Splat.Clone()
					$incorrect.AdapterType = 'Ethernet 802.3'
                }

??????                Mock Set-NetConnectionProfile {}

                Set-TargetResource @Splat

                Assert-MockCalled Set-NetConnectionProfile
            }
        }
    } #end InModuleScope $DSCResourceName
    #endregion
	}
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
