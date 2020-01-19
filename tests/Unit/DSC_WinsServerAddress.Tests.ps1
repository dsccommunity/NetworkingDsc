$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_WinsServerAddress'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        Describe 'DSC_WinsServerAddress\Get-TargetResource' {
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

        Describe 'DSC_WinsServerAddress\Set-TargetResource' {
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

        Describe 'DSC_WinsServerAddress\Test-TargetResource' {
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
}
finally
{
    Invoke-TestCleanup
}
