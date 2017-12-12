$script:DSCModuleName = 'xNetworking'
$script:DSCResourceName = 'MSFT_xNetAdapterAdvancedProperty'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
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

        $TestJumboPacket9014 = @{
            NetworkAdapterName    = 'Ethernet'
            RegistryKeyword = *JumboPacket
            RegistryValue = 9014
        }

        $TestJumboPacket1514 = @{
            NetworkAdapterName    = 'Ethernet'
            RegistryKeyword = *JumboPacket
            RegistryValue = 1514
        }

        $TestAdapterNotFound = @{
            NetworkAdapterName    = 'Ethe'
            RegistryKeyword = *JumboPacket
            RegistryValue = 1514
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" -Tag 'Get' {
            Context 'Adapter exist and JumboPacket is enabled 9014' {
                Mock "Get-NetAdapterAdvancedProperty -RegistryKeyword *JumboPacket" -Verbose -MockWith { @{ RegistryValue = 9014 } }

                It 'Should return the JumboPacket size' {
                    $result = Get-TargetResource @TestJumboPacket9014
                    $result.RegistryValue | Should Be $TestJumboPacket9014.RegistryValue
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName "Get-NetAdapterAdvancedProperty -RegistryKeyword *JumboPacket" -Regis -Exactly -Time 1
                }
            }

            Context 'Adapter exist and JumboPacket is 1514' {
                Mock "Get-NetAdapterAdvancedProperty -RegistryKeyword *JumboPacket" -Verbose -MockWith {
                    @{ RegistryValue = $TestJumboPacket1514.RegistryValue}
                }

                It 'Should return the JumboPacket size' {
                    $result = Get-TargetResource @TestJumboPacket1514
                    $result.RegistryValue | Should Be $TestJumboPacket1514.RegistryValue
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName "Get-NetAdapterAdvancedProperty -RegistryKeyword *JumboPacket" -Exactly -Time 1
                }
            }
            Context 'Adapter does not exist' {

                Mock -CommandName "Get-NetAdapterAdvancedProperty -RegistryKeyword *JumboPacket" -MockWith { throw 'Network adapter not found' }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.NetAdapterNotFoundMessage)

                It 'Should throw an exception' {
                    { Get-TargetResource @TestAdapterNotFound } | Should throw $errorRecord
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName "Get-NetAdapterAdvancedProperty -RegistryKeyword *JumboPacket" -Exactly -Time 1
                }
            }

            Describe "$($script:DSCResourceName)\Set-TargetResource" {

                Context 'Adapter exist, RSS is enabled, no action required' {
                    Mock -CommandName "Get-NetAdapterAdvancedProperty -RegistryKeyword *JumboPacket" -MockWith {
                        @{ RegistryValue = $TestJumboPacket9014.RegistryValue}
                    }
                    Mock -CommandName Set-NetAdapterAdvancedProperty

                    It 'Should not throw an exception' {
                        { Set-TargetResource @TestJumboPacket9014 } | Should Not Throw
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName "Get-NetAdapterAdvancedProperty -RegistryKeyword *JumboPacket" -Exactly -Time 1
                        Assert-MockCalled -CommandName Set-NetAdapterAdvancedProperty -Exactly -Time 0
                    }
                }

                Context 'Adapter exist, RSS is enabled, should be disabled' {
                    Mock -CommandName "Get-NetAdapterAdvancedProperty -RegistryKeyword *JumboPacket" -MockWith {
                        @{ RegistryValue = $TestJumboPacket9014.RegistryValue }
                    }
                    Mock -CommandName Set-NetAdapterAdvancedProperty

                    It 'Should not throw an exception' {
                        { Set-TargetResource @TestJumboPacket1514 } | Should Not Throw
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName "Get-NetAdapterAdvancedProperty -RegistryKeyword *JumboPacket" -Exactly -Time 1
                        Assert-MockCalled -CommandName Set-NetAdapterAdvancedProperty -Exactly -Time 1
                    }
                }


                # Adapter
                Context 'Adapter does not exist' {
                    Mock -CommandName Get-NetAdapterRSS -MockWith { throw 'Network adapter not found' }

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.NetAdapterNotFoundMessage)

                    It 'Should throw an exception' {
                        { Set-TargetResource @TestAdapterNotFound } | Should throw $errorRecord
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                    }
                }

            }

        }}
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
