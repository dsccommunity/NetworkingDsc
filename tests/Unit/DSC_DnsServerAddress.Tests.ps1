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
    $script:dscResourceName = 'DSC_DnsServerAddress'

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

Describe 'DSC_DnsServerAddress\Get-TargetResource' -Tag 'Get' {
    Context 'Test IPv4' {
        Context 'Invoking with an IPv4 address and one address is currently set' {
            BeforeAll {
                Mock -CommandName Get-DnsClientServerStaticAddress -MockWith { '192.168.0.1' }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceSplat = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $Result = Get-TargetResource @getTargetResourceSplat
                    $Result.Address | Should -Be '192.168.0.1'
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'Test IPv6' {
        Context 'Invoking with an IPv6 address and one address is currently set' {
            BeforeAll {
                Mock Get-DnsClientServerStaticAddress -MockWith { 'fe80:ab04:30F5:002b::1' }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceSplat = @{
                        Address        = 'fe80:ab04:30F5:002b::1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $Result = Get-TargetResource @getTargetResourceSplat
                    $Result.Address | Should -Be 'fe80:ab04:30F5:002b::1'
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'Test DHCP' {
        Context 'Invoking with an IPv4 address and DHCP is currently set' {
            BeforeAll {
                Mock Get-DnsClientServerStaticAddress -MockWith { @() }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceSplat = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $Result = Get-TargetResource @getTargetResourceSplat
                    $Result.Address | Should -BeNullOrEmpty
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }
    }
}

Describe 'DSC_DnsServerAddress\Set-TargetResource' -Tag 'Set' {
    Context 'Test IPv4' {
        BeforeAll {
            Mock Get-DnsClientServerStaticAddress -MockWith { '192.168.0.1' }
            Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $true }
            Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $false }
            Mock Set-DnsClientServerAddress -ParameterFilter { $ResetServerAddresses -eq $true }
        }

        Context 'Invoking with single IPv4 server address that is the same as current' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }

        Context 'Invoking with single IPv4 server address that is different to current' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        Address        = '192.168.0.99'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }

        Context 'Invoking with single IPv4 server address that is different to current and validate true' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        Address        = '192.168.0.99'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                        Validate       = $true
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }

        Context 'Invoking with multiple IPv4 server addresses that are different to current' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        Address        = @( '192.168.0.99', '192.168.0.100' )
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }

        Context 'Invoking with IPv4 server addresses set to DHCP but one address is currently assigned' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }

        Context 'Invoking with multiple IPv4 server addresses when there are different ones currently assigned' {
            BeforeAll {
                Mock -CommandName Get-DnsClientServerStaticAddress -MockWith { @( '192.168.0.1', '192.168.0.2' ) }
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        Address        = @( '192.168.0.3', '192.168.0.4' )
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }

        Context 'Invoking with multiple IPv4 server addresses when DHCP is currently set' {
            BeforeAll {
                Mock -CommandName Get-DnsClientServerStaticAddress -MockWith { @() }
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        Address        = @( '192.168.0.2', '192.168.0.3' )
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }
    }

    Context 'Test IPv6' {
        BeforeAll {
            Mock Get-DnsClientServerStaticAddress -MockWith { 'fe80:ab04:30F5:002b::1' }
            Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $true }
            Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $false }
            Mock Set-DnsClientServerAddress -ParameterFilter { $ResetServerAddresses -eq $true }
        }

        Context 'Invoking with single IPv6 server address that is the same as current' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        Address        = 'fe80:ab04:30F5:002b::1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }

        Context 'Invoking with single IPv6 server address that is different to current' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        Address        = 'fe80:ab04:30F5:002b::2'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }

        Context 'Invoking with single IPv6 server address that is different to current and validate true' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        Address        = 'fe80:ab04:30F5:002b::2'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                        Validate       = $true
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }

        Context 'Invoking with multiple IPv6 server addresses that are different to current' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        Address        = @( 'fe80:ab04:30F5:002b::1', 'fe80:ab04:30F5:002b::2' )
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }

        Context 'Invoking with IPv6 server addresses set to DHCP but one address is currently assigned' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }

        Context 'Invoking with multiple IPv6 server addresses when DHCP is currently set' {
            BeforeAll {
                Mock Get-DnsClientServerStaticAddress -MockWith { @() }
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceSplat = @{
                        Address        = @( 'fe80:ab04:30F5:002b::1', 'fe80:ab04:30F5:002b::1' )
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $Validate -eq $true }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 1 -Scope Context -ParameterFilter { $Validate -eq $false }
                Should -Invoke -CommandName Set-DnsClientServerAddress -Exactly -Times 0 -Scope Context -ParameterFilter { $ResetServerAddresses -eq $true }
            }
        }
    }
}

Describe 'DSC_DnsServerAddress\Test-TargetResource' -Tag 'Test' {
    Context 'Test IPv4' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { @{ Name = 'Ethernet' } }
            Mock -CommandName Get-DnsClientServerStaticAddress -MockWith { '192.168.0.1' }
        }

        Context 'Invoking with single IPv4 server address that is the same as current' {
            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeTrue
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoking with single IPv4 server address that is different to current' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = '192.168.0.2'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoking with multiple IPv4 server addresses that are different to current' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = @( '192.168.0.2', '192.168.0.3' )
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoking with IPv4 server addresses set to DHCP but one address is currently assigned' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoking with multiple IPv4 server addresses but DHCP is currently enabled' {
            BeforeAll {
                Mock -CommandName Get-NetAdapter -MockWith { @{ Name = 'Ethernet' } }
                Mock -CommandName Get-DnsClientServerStaticAddress
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = @( '192.168.0.2', '192.168.0.3' )
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'Test IPv6' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { @{ Name = 'Ethernet' } }
            Mock -CommandName Get-DnsClientServerStaticAddress -MockWith { 'fe80:ab04:30F5:002b::1' }
        }

        Context 'Invoking with single IPv6 server address that is the same as current' {
            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = 'fe80:ab04:30F5:002b::1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeTrue
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoking with single IPv6 server address that is different to current' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = 'fe80:ab04:30F5:002b::2'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoking with multiple IPv6 server addresses that are different to current' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = @( 'fe80:ab04:30F5:002b::1', 'fe80:ab04:30F5:002b::2' )
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoking with IPv6 server addresses set to DHCP but one address is currently assigned' {
            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoking with multiple IPv6 server addresses but DHCP is currently enabled' {
            BeforeAll {
                Mock -CommandName Get-NetAdapter -MockWith { @{ Name = 'Ethernet' } }
                Mock -CommandName Get-DnsClientServerStaticAddress
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceSplat = @{
                        Address        = @( 'fe80:ab04:30F5:002b::1', 'fe80:ab04:30F5:002b::2' )
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-DnsClientServerStaticAddress -Exactly -Times 1 -Scope Context
            }
        }
    }
}

Describe 'DSC_DnsServerAddress\Assert-ResourceProperty' {
    BeforeAll {
        Mock -CommandName Get-NetAdapter -MockWith { @{ Name = 'Ethernet' } }
    }

    Context 'Invoking with bad interface alias' {
        It 'Should throw the expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertySplat = @{
                    Address        = '192.168.0.1'
                    InterfaceAlias = 'NotReal'
                    AddressFamily  = 'IPv4'
                }

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.InterfaceNotAvailableError -f $assertResourcePropertySplat.InterfaceAlias) `
                    -ArgumentName 'InterfaceAlias'

                { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Throw $ErrorRecord
            }
        }
    }

    Context 'Invoking with invalid IP Address' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertySplat = @{
                    Address        = 'NotReal'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Throw
            }
        }
    }

    Context 'Invoking with IPv4 Address and family mismatch' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertySplat = @{
                    Address        = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv6'
                }

                { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Throw
            }
        }
    }

    Context 'Invoking with IPv6 Address and family mismatch' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertySplat = @{
                    Address        = 'fe80::'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Throw
            }
        }
    }

    Context 'Invoking with valid IPv4 Addresses' {
        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertySplat = @{
                    Address        = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Not -Throw
            }
        }
    }

    Context 'Invoking with valid IPv6 Addresses' {
        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertySplat = @{
                    Address        = 'fe80:ab04:30F5:002b::1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv6'
                }

                { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Not -Throw
            }
        }
    }
}
