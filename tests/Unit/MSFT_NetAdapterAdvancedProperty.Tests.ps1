$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetAdapterAdvancedProperty'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
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
            RegistryKeyword = "*JumboPacket"
            RegistryValue = 9014
        }

        $TestJumboPacket1514 = @{
            NetworkAdapterName    = 'Ethernet'
            RegistryKeyword = '*JumboPacket'
            RegistryValue = 1514
        }

        $TestAdapterNotFound = @{
            NetworkAdapterName    = 'Ethe'
            RegistryKeyword = "*JumboPacket"
            RegistryValue = 1514
        }

        function Get-NetAdapterAdvancedProperty { }

        Describe 'MSFT_NetAdapterAdvancedProperty\Get-TargetResource' -Tag 'Get' {

            Context 'Adapter exist and JumboPacket is enabled 9014' {
                Mock Get-NetAdapterAdvancedProperty -Verbose -MockWith {
                    @{
                        RegistryValue = $TestJumboPacket9014.RegistryValue
                        RegistryKeyword = $TestJumboPacket9014.RegistryKeyword
                    }
                }

                It 'Should return the JumboPacket size' {
                    $result = Get-TargetResource @TestJumboPacket9014
                    $result.RegistryValue | Should -Be $TestJumboPacket9014.RegistryValue
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1
                }
            }

            Context 'Adapter exist and JumboPacket is 1514' {
                Mock Get-NetAdapterAdvancedProperty -Verbose -MockWith {
                    @{
                        RegistryValue = $TestJumboPacket1514.RegistryValue
                        RegistryKeyword = $TestJumboPacket1514.RegistryKeyword
                    }
                }

                It 'Should return the JumboPacket size' {
                    $result = Get-TargetResource @TestJumboPacket1514
                    $result.RegistryValue | Should -Be $TestJumboPacket1514.RegistryValue
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1
                }
            }

            Context 'Adapter does not exist' {

                Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith { throw 'Network adapter not found' }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                It 'Should throw an exception' {
                    { Get-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1
                }
            }

            Describe 'MSFT_NetAdapterAdvancedProperty\Set-TargetResource' -Tag 'Set' {

                Context 'Adapter exist, JumboPacket is 9014, no action required' {
                    Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith {
                        @{
                            RegistryValue = $TestJumboPacket9014.RegistryValue
                            RegistryKeyword = $TestJumboPacket9014.RegistryKeyword
                        }
                    }
                    Mock -CommandName Set-NetAdapterAdvancedProperty

                    It 'Should not throw an exception' {
                        { Set-TargetResource @TestJumboPacket9014 } | Should -Not -Throw
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1
                        Assert-MockCalled -CommandName Set-NetAdapterAdvancedProperty -Exactly -Time 0
                    }
                }

                Context 'Adapter exist, JumboPacket is 9014, should be 1514' {
                    Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith {
                        @{
                            RegistryValue = $TestJumboPacket9014.RegistryValue
                            RegistryKeyword = $TestJumboPacket9014.RegistryKeyword
                        }
                    }
                    Mock -CommandName Set-NetAdapterAdvancedProperty

                    It 'Should not throw an exception' {
                        { Set-TargetResource @TestJumboPacket1514 } | Should -Not -Throw
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1
                        Assert-MockCalled -CommandName Set-NetAdapterAdvancedProperty -Exactly -Time 1
                    }
                }

                Context 'Adapter exist, JumboPacket is 1514, should be 9014' {
                    Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith {
                        @{
                            RegistryValue = $TestJumboPacket1514.RegistryValue
                            RegistryKeyword = $TestJumboPacket1514.RegistryKeyword
                        }
                    }
                    Mock -CommandName Set-NetAdapterAdvancedProperty

                    It 'Should not throw an exception' {
                        { Set-TargetResource @TestJumboPacket9014 } | Should -Not -Throw
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1
                        Assert-MockCalled -CommandName Set-NetAdapterAdvancedProperty -Exactly -Time 1
                    }
                }

                # Adapter
                Context 'Adapter does not exist' {
                    Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith { throw 'Network adapter not found' }

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.NetAdapterNotFoundMessage)

                    It 'Should throw an exception' {
                        { Set-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterAdvancedProperty -Exactly -Time 1
                    }
                }
            }
        }

        Describe 'MSFT_NetAdapterAdvancedProperty\Test-TargetResource' -Tag 'Test' {

            # JumboPacket
            Context 'Adapter exist, JumboPacket is 9014, no action required' {
                Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith {
                    @{
                        RegistryValue = $TestJumboPacket9014.RegistryValue
                        RegistryKeyword = $TestJumboPacket9014.RegistryKeyword
                    }
                }

                It 'Should return true' {
                    Test-TargetResource @TestJumboPacket9014 | Should -Be $true
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterAdvancedProperty -Exactly 1
                }
            }

            Context 'Adapter exist, JumboPacket is 9014 should be 1514' {
                Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith {
                    @{
                        RegistryValue = $TestJumboPacket9014.RegistryValue
                        RegistryKeyword = $TestJumboPacket9014.RegistryKeyword
                    }
                }

                It 'Should return false' {
                    Test-TargetResource @TestJumboPacket1514 | Should -Be $false
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterAdvancedProperty -Exactly 1
                }
            }


            # Adapter
            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterAdvancedProperty -MockWith { throw 'Network adapter not found' }

                It 'Should throw an exception' {
                    { Test-TargetResource @TestAdapterNotFound } | Should -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterAdvancedProperty -Exactly 1
                }
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
