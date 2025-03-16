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
    $script:dscResourceName = 'DSC_DefaultGatewayAddress'

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

Describe 'DSC_DefaultGatewayAddress\Get-TargetResource' -Tag 'Get' {
    Context 'When interface has a default gateway set' {
        BeforeAll {
            Mock -CommandName Get-NetDefaultRoute -MockWith {
                @{
                    NextHop           = '192.168.0.1'
                    DestinationPrefix = '0.0.0.0/0'
                    InterfaceAlias    = 'Ethernet'
                    InterfaceIndex    = 1
                    AddressFamily     = 'IPv4'
                }
            }
        }

        It 'Should return current default gateway' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceParameters = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $result = Get-TargetResource @getTargetResourceParameters

                $result.Address | Should -Be '192.168.0.1'
            }

            Should -Invoke -CommandName Get-NetDefaultRoute -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When interface has no default gateway set' {
        BeforeAll {
            Mock -CommandName Get-NetDefaultRoute
        }

        It 'Should return no default gateway' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceParameters = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $result = Get-TargetResource @getTargetResourceParameters

                $result.Address | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-NetDefaultRoute -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_DefaultGatewayAddress\Set-TargetResource' -Tag 'Set' {
    BeforeEach {
        Mock -CommandName Get-NetDefaultRoute -MockWith {
            @{
                NextHop           = '192.168.0.1'
                DestinationPrefix = '0.0.0.0/0'
                InterfaceAlias    = 'Ethernet'
                InterfaceIndex    = 1
                AddressFamily     = 'IPv4'
            }
        }

        Mock -CommandName Get-NetDefaultGatewayDestinationPrefix -MockWith {
            '0.0.0.0/0'
        }

        Mock -CommandName Remove-NetRoute
        Mock -CommandName New-NetRoute
    }

    Context 'When invoking with no Default Gateway Address' {
        It 'Should return $null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $result = Set-TargetResource @setTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeNullOrEmpty
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-NetDefaultRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetRoute -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When invoking with valid Default Gateway Address' {
        It 'Should return $null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Address        = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $result = Set-TargetResource @setTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeNullOrEmpty
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Get-NetDefaultRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-NetDefaultGatewayDestinationPrefix -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetRoute -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_DefaultGatewayAddress\Test-TargetResource' -Tag 'Test' {
    Context 'When checking return with default gateway that matches currently set one' {
        BeforeAll {
            Mock -CommandName Assert-ResourceProperty
            Mock -CommandName Get-NetDefaultRoute -MockWith {
                @{
                    NextHop           = '192.168.0.1'
                    DestinationPrefix = '0.0.0.0/0'
                    InterfaceAlias    = 'Ethernet'
                    InterfaceIndex    = 1
                    AddressFamily     = 'IPv4'
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    Address        = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                Test-TargetResource @testTargetResourceParameters | Should -BeTrue
            }

            Should -Invoke Assert-ResourceProperty -Exactly -Times 1 -Scope It
            Should -Invoke Get-NetDefaultRoute -Exactly -Times 1 -Scope It
        }
    }

    Context 'Checking return with no gateway but one is currently set' {
        BeforeAll {
            Mock -CommandName Assert-ResourceProperty
            Mock -CommandName Get-NetDefaultRoute -MockWith {
                @{
                    NextHop           = '192.168.0.1'
                    DestinationPrefix = '0.0.0.0/0'
                    InterfaceAlias    = 'Ethernet'
                    InterfaceIndex    = 1
                    AddressFamily     = 'IPv4'
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                Test-TargetResource @testTargetResourceParameters | Should -BeFalse
            }

            Should -Invoke Assert-ResourceProperty -Exactly -Times 1 -Scope It
            Should -Invoke Get-NetDefaultRoute -Exactly -Times 1 -Scope It
        }
    }

    Context 'Checking return with default gateway but none are currently set' {
        BeforeAll {
            Mock -CommandName Assert-ResourceProperty
            Mock -CommandName Get-NetDefaultRoute
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    Address        = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                Test-TargetResource @testTargetResourceParameters | Should -BeFalse
            }

            Should -Invoke Assert-ResourceProperty -Exactly -Times 1 -Scope It
            Should -Invoke Get-NetDefaultRoute -Exactly -Times 1 -Scope It
        }
    }

    Context 'Checking return with no gateway and none are currently set' {
        BeforeAll {
            Mock -CommandName Assert-ResourceProperty
            Mock -CommandName Get-NetDefaultRoute
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                Test-TargetResource @testTargetResourceParameters | Should -BeTrue
            }

            Should -Invoke Assert-ResourceProperty -Exactly -Times 1 -Scope It
            Should -Invoke Get-NetDefaultRoute -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_DefaultGatewayAddress\Assert-ResourceProperty' -Tag 'Private' {
    BeforeAll {
        Mock -CommandName Get-NetAdapter -MockWith {
            @{
                Name = 'Ethernet'
            }
        }
    }

    Context 'When invoking with bad interface alias' {
        It 'Should throw an InterfaceNotAvailable error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    Address        = '192.168.0.1'
                    InterfaceAlias = 'NotReal'
                    AddressFamily  = 'IPv4'
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.InterfaceNotAvailableError -f $assertResourcePropertyParameters.InterfaceAlias)

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw -ExpectedMessage $ErrorRecord
            }
        }
    }

    Context 'When invoking with invalid IP Address' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    Address        = 'NotReal'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw
            }
        }
    }

    Context 'When invoking with IPv4 Address and family mismatch' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    Address        = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv6'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw
            }
        }
    }

    Context 'When invoking with IPv6 Address and family mismatch' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    Address        = 'fe80::'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw
            }
        }
    }

    Context 'When invoking with valid IPv4 Address' {
        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    Address        = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
            }
        }
    }

    Context 'When invoking with valid IPv6 Address' {
        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    Address        = 'fe80:ab04:30F5:002b::1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv6'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
            }
        }
    }
}

Describe 'DSC_DefaultGatewayAddress\Get-NetDefaultGatewayDestinationPrefix' -Tag 'Private' {
    Context 'When the AddressFamily is IPv4' {
        It 'Should return current default gateway' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-NetDefaultGatewayDestinationPrefix -AddressFamily 'IPv4' | Should -Be '0.0.0.0/0'
            }
        }
    }

    Context 'When the AddressFamily is IPv6' {
        It 'Should return current default gateway' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-NetDefaultGatewayDestinationPrefix -AddressFamily 'IPv6' | Should -Be '::/0'
            }
        }
    }
}

Describe 'DSC_DefaultGatewayAddress\Get-NetDefaultRoute' -Tag 'Private' {
    Context 'When interface has a default gateway set' {
        BeforeAll {
            Mock -CommandName Get-NetRoute -MockWith {
                @{
                    NextHop           = '192.168.0.1'
                    DestinationPrefix = '0.0.0.0/0'
                    InterfaceAlias    = 'Ethernet'
                    InterfaceIndex    = 1
                    AddressFamily     = 'IPv4'
                }
            }
        }

        It 'Should return current default gateway' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $GetNetDefaultRouteParameters = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $result = Get-NetDefaultRoute @GetNetDefaultRouteParameters

                $result.NextHop | Should -Be '192.168.0.1'
            }
        }
    }

    Context 'When interface has no default gateway set' {
        BeforeAll {
            Mock -CommandName Get-NetRoute
        }

        It 'Should return no default gateway' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $GetNetDefaultRouteParameters = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $result = Get-NetDefaultRoute @GetNetDefaultRouteParameters

                $result | Should -BeNullOrEmpty
            }
        }
    }
}
