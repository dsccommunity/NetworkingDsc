# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceName = 'DSC_WinsServerAddress'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_WinsServerAddress\Get-TargetResource' {
    Context 'When invoking with an address and one address is currently set' {
        BeforeAll {
            Mock -CommandName Get-WinsClientServerStaticAddress -MockWith { '192.168.0.1' }
            Mock -CommandName Assert-ResourceProperty
        }

        It 'Should return current WINS address' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceSplat = @{
                    InterfaceAlias = 'Ethernet'
                }

                $result = Get-TargetResource @getTargetResourceSplat
                $result.Address | Should -Be '192.168.0.1'
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-WinsClientServerStaticAddress -Exactly -Times 1 -Scope Context #-ParameterFilter { Write-Host "--$($InterfaceName)--"; $InterfaceName -eq 'Ethernet' }
            Should -Invoke -CommandName Assert-ResourceProperty -Exactly -Times 1 -Scope Context #-ParameterFilter { $InterfaceName -eq 'Ethernet' }
        }
    }
}

Describe 'DSC_WinsServerAddress\Set-TargetResource' {
    BeforeAll {
        Mock -CommandName Get-WinsClientServerStaticAddress -MockWith { '192.168.0.1' }
        Mock -CommandName Set-WinsClientServerStaticAddress
        Mock -CommandName Assert-ResourceProperty
    }

    Context 'When invoking with single server address' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceSplat = @{
                    Address        = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                }

                { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Set-WinsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Assert-ResourceProperty -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When invoking with multiple server addresses' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceSplat = @{
                    Address        = @( '192.168.0.99', '192.168.0.100' )
                    InterfaceAlias = 'Ethernet'
                }

                { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -commandName Set-WinsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Assert-ResourceProperty -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_WinsServerAddress\Test-TargetResource' {
    Context 'When a single WINS server is currently configured' {
        BeforeAll {
            Mock -CommandName Get-WinsClientServerStaticAddress -MockWith { '192.168.0.1' }
            Mock -CommandName Assert-ResourceProperty
        }

        Context 'When invoking with single server address that is the same as current' {
            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeTrue
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-WinsClientServerStaticAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Assert-ResourceProperty -Exactly -Times 2 -Scope Context
            }
        }

        Context 'When invoking with single server address that is different to current' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = '192.168.0.2'
                        InterfaceAlias = 'Ethernet'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-WinsClientServerStaticAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Assert-ResourceProperty -Exactly -Times 2 -Scope Context
            }
        }

        Context 'Invoking with multiple server addresses that are different to current' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = '192.168.0.2', '192.168.0.3'
                        InterfaceAlias = 'Ethernet'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-WinsClientServerStaticAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Assert-ResourceProperty -Exactly -Times 2 -Scope Context
            }
        }
    }

    Context 'When two WINS servers are currently configured' {
        BeforeAll {
            Mock -CommandName Get-WinsClientServerStaticAddress -MockWith { '192.168.0.1', '192.168.0.2' }
            Mock -CommandName Assert-ResourceProperty
        }

        Context 'When invoking with multiple server addresses that are the same as current' {
            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = '192.168.0.1', '192.168.0.2'
                        InterfaceAlias = 'Ethernet'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeTrue
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-WinsClientServerStaticAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Assert-ResourceProperty -Exactly -Times 2 -Scope Context
            }
        }

        Context 'When invoking with multiple server addresses that are different to current 1' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = '192.168.0.2', '192.168.0.99'
                        InterfaceAlias = 'Ethernet'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-WinsClientServerStaticAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Assert-ResourceProperty -Exactly -Times 2 -Scope Context
            }
        }

        Context 'When invoking with multiple server addresses that are different to current 2' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = '192.168.0.1', '192.168.0.2', '192.168.0.3'
                        InterfaceAlias = 'Ethernet'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-WinsClientServerStaticAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Assert-ResourceProperty -Exactly -Times 2 -Scope Context
            }
        }

        Context 'When invoking with multiple server addresses that are in a different order to current' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = '192.168.0.2', '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-WinsClientServerStaticAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Assert-ResourceProperty -Exactly -Times 2 -Scope Context
            }
        }
    }
}
