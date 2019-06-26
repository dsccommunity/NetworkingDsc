$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_WinsServerAddress'

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
        Describe 'MSFT_WinsServerAddress\Get-TargetResource' {
            Context 'When invoking with an address and one address is currently set' {
                Mock Get-WinsClientServerStaticAddress -MockWith { '192.168.0.1' }
                Mock Assert-ResourceProperty -MockWith { }

                It 'Should return current WINS address' {
                    $getTargetResourceSplat = @{
                        InterfaceAlias = 'Ethernet'
                        Verbose        = $true
                    }

                    $result = Get-TargetResource @getTargetResourceSplat
                    $result.Address | Should -Be '192.168.0.1'
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-WinsClientServerStaticAddress -Exactly 1 #-ParameterFilter { Write-Host "--$($InterfaceName)--"; $InterfaceName -eq 'Ethernet' }
                    Assert-MockCalled -CommandName Assert-ResourceProperty -Exactly 1 #-ParameterFilter { $InterfaceName -eq 'Ethernet' }
                }
            }
        }

        Describe 'MSFT_WinsServerAddress\Set-TargetResource' {
            BeforeEach {
                Mock Get-WinsClientServerStaticAddress -MockWith { '192.168.0.1' }
                Mock Set-WinsClientServerStaticAddress -MockWith { }
                Mock Assert-ResourceProperty -MockWith { }
            }

            Context 'When invoking with single server address' {
                It 'Should not throw an exception' {
                    $setTargetResourceSplat = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        Verbose        = $true
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Set-WinsClientServerStaticAddress -Exactly 1
                    Assert-MockCalled -CommandName Assert-ResourceProperty -Exactly 1
                }
            }

            Context 'When invoking with multiple server addresses' {
                It 'Should not throw an exception' {
                    $setTargetResourceSplat = @{
                        Address        = @( '192.168.0.99', '192.168.0.100' )
                        InterfaceAlias = 'Ethernet'
                        Verbose        = $true
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -commandName Set-WinsClientServerStaticAddress -Exactly 1
                    Assert-MockCalled -CommandName Assert-ResourceProperty -Exactly 1
                }
            }
        }

        Describe 'MSFT_WinsServerAddress\Test-TargetResource' {
            Context 'When a single WINS server is currently configured' {
                BeforeEach {
                    Mock Get-WinsClientServerStaticAddress -MockWith { '192.168.0.1' }
                    Mock Assert-ResourceProperty -MockWith { }
                }

                Context 'When invoking with single server address that is the same as current' {
                    It 'Should return true' {
                        $testTargetResourceSplat = @{
                            Address        = '192.168.0.1'
                            InterfaceAlias = 'Ethernet'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $true
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-WinsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -CommandName Assert-ResourceProperty -Exactly 2
                    }
                }

                Context 'When invoking with single server address that is different to current' {
                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            Address        = '192.168.0.2'
                            InterfaceAlias = 'Ethernet'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $False
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-WinsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -CommandName Assert-ResourceProperty -Exactly 2
                    }
                }

                Context 'Invoking with multiple server addresses that are different to current' {
                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            Address        = '192.168.0.2', '192.168.0.3'
                            InterfaceAlias = 'Ethernet'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $False
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-WinsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -CommandName Assert-ResourceProperty -Exactly 2
                    }
                }
            }

            Context 'When two WINS servers are currently configured' {
                BeforeEach {
                    Mock Get-WinsClientServerStaticAddress -MockWith { '192.168.0.1', '192.168.0.2' }
                    Mock Assert-ResourceProperty -MockWith { }
                }

                Context 'When invoking with multiple server addresses that are the same as current' {
                    It 'Should return true' {
                        $testTargetResourceSplat = @{
                            Address        = '192.168.0.1', '192.168.0.2'
                            InterfaceAlias = 'Ethernet'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $true
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-WinsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -CommandName Assert-ResourceProperty -Exactly 2
                    }
                }

                Context 'When invoking with multiple server addresses that are different to current 1' {
                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            Address        = '192.168.0.2', '192.168.0.99'
                            InterfaceAlias = 'Ethernet'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $false
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-WinsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -CommandName Assert-ResourceProperty -Exactly 2
                    }
                }

                Context 'When invoking with multiple server addresses that are different to current 2' {
                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            Address        = '192.168.0.1', '192.168.0.2', '192.168.0.3'
                            InterfaceAlias = 'Ethernet'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $false
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-WinsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -CommandName Assert-ResourceProperty -Exactly 2
                    }
                }

                Context 'When invoking with multiple server addresses that are in a different order to current' {
                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            Address        = '192.168.0.2', '192.168.0.1'
                            InterfaceAlias = 'Ethernet'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $false
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-WinsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -CommandName Assert-ResourceProperty -Exactly 2
                    }
                }
            }
        }
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
