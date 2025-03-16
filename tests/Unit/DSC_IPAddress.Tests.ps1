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
    $script:dscResourceName = 'DSC_IPAddress'

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

Describe 'DSC_IPAddress\Get-TargetResource' -Tag 'Get' {
    Context 'Invoked with a single IP address' {
        BeforeAll {
            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 24
                    AddressFamily  = 'IPv4'
                }
            }
        }

        It 'Should return existing IP details' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceParameters = @{
                    IPAddress      = '192.168.0.1/24'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $result = Get-TargetResource @getTargetResourceParameters
                $result.IPAddress | Should -Be $getTargetResourceParameters.IPAddress
            }
        }
    }

    Context 'Invoked with multiple IP addresses' {
        BeforeAll {
            Mock -CommandName Get-NetIPAddress -MockWith {
                @(
                    @{
                        IPAddress      = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        PrefixLength   = [System.Byte] 24
                        AddressFamily  = 'IPv4'
                    },
                    @{
                        IPAddress      = '192.168.0.2'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        PrefixLength   = [System.Byte] 24
                        AddressFamily  = 'IPv4'
                    }
                )
            }
        }

        It 'Should return existing IP details' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceParameters = @{
                    IPAddress      = @('192.168.0.1/24', '192.168.0.2/24')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $result = Get-TargetResource @getTargetResourceParameters
                $result.IPAddress | Should -Be $getTargetResourceParameters.IPAddress
            }
        }
    }
}

Describe 'DSC_IPAddress\Set-TargetResource' -Tag 'Set' {
    Context 'A single IPv4 address is currently set on the adapter' {
        BeforeAll {
            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 16
                    AddressFamily  = 'IPv4'
                }
            }

            Mock -CommandName New-NetIPAddress

            Mock -CommandName Get-NetRoute {
                @{
                    InterfaceAlias    = 'Ethernet'
                    InterfaceIndex    = 1
                    AddressFamily     = 'IPv4'
                    NextHop           = '192.168.0.254'
                    DestinationPrefix = '0.0.0.0/0'
                }
            }

            Mock -CommandName Remove-NetIPAddress

            Mock -CommandName Remove-NetRoute
        }

        Context 'Invoked with valid IP address' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = '10.0.0.2/24'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with multiple valid IP Address' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = @('10.0.0.2/24', '10.0.0.3/24')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 2 -Scope Context
            }
        }

        Context 'Invoked with multiple valid IP Addresses with one currently set' {
            BeforeAll {
                Mock -CommandName New-NetIPAddress -MockWith {
                    throw [Microsoft.Management.Infrastructure.CimException] 'InvalidOperation'
                } -ParameterFilter { $IPaddress -eq '192.168.0.1' }

                Mock -CommandName Get-NetIPAddress -MockWith {
                    @{
                        IPAddress      = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        PrefixLength   = [System.Byte] 16
                        AddressFamily  = 'IPv4'
                    }
                } -ParameterFilter { $IPaddress -eq '192.168.0.1' }

                Mock -CommandName Write-Error
            }

            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = @('192.168.0.1/16', '10.0.0.3/24')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Write-Error -Exactly -Times 0 -Scope Context
            }
        }

        Context 'Invoked with multiple valid IP Addresses with one currently set on another adapter' {
            BeforeAll {
                Mock -CommandName New-NetIPAddress -MockWith {
                    throw [Microsoft.Management.Infrastructure.CimException] 'InvalidOperation'
                } -ParameterFilter { $IPaddress -eq '192.168.0.1' }

                Mock -CommandName Get-NetIPAddress -MockWith {
                    @{
                        IPAddress      = '192.168.0.1'
                        InterfaceAlias = 'Ethernet2'
                        PrefixLength   = [System.Byte] 16
                        AddressFamily  = 'IPv4'
                    }
                } -ParameterFilter { $IPaddress -eq '192.168.0.1' }

                Mock -CommandName Write-Error
            }

            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = @('192.168.0.1/16', '10.0.0.3/24')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Write-Error -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked IPv4 Class A with no prefix' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = '10.11.12.13'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 1 -Scope Context -ParameterFilter {
                    $PrefixLength -eq 8
                }

            }
        }

        Context 'Invoked IPv4 Class B with no prefix' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = '172.16.4.19'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 1 -Scope Context -ParameterFilter {
                    $PrefixLength -eq 16
                }
            }
        }

        Context 'Invoked IPv4 Class C with no prefix' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = '192.168.10.19'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 1 -Scope Context -ParameterFilter {
                    $PrefixLength -eq 24
                }
            }
        }

        Context 'Invoked with parameter "KeepExistingAddress"' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress           = '10.0.0.2/24'
                        InterfaceAlias      = 'Ethernet'
                        AddressFamily       = 'IPv4'
                        KeepExistingAddress = $true
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'A single IPv6 address is currently set on the adapter' {
        BeforeAll {
            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = 'fe80::15'
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 64
                    AddressFamily  = 'IPv6'
                }
            }

            Mock -CommandName New-NetIPAddress

            Mock -CommandName Get-NetRoute {
                @{
                    InterfaceAlias    = 'Ethernet'
                    InterfaceIndex    = 1
                    AddressFamily     = 'IPv6'
                    NextHop           = 'fe80::16'
                    DestinationPrefix = '::/0'
                }
            }

            Mock -CommandName Remove-NetIPAddress

            Mock -CommandName Remove-NetRoute
        }

        Context 'Invoked with valid IPv6 Address' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = 'fe80::17/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with multiple valid IPv6 Addresses' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = @('fe80::17/64', 'fe80::18/64')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 2 -Scope Context
            }
        }

        Context 'Invoked IPv6 with no prefix' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = 'fe80::17'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with parameter "KeepExistingAddress"' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress           = 'fe80::17/64'
                        InterfaceAlias      = 'Ethernet'
                        AddressFamily       = 'IPv6'
                        KeepExistingAddress = $true
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call all the mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'Multiple IPv4 addresses are currently set on the adapter' {
        BeforeEach {
            Mock -CommandName Get-NetIPAddress -MockWith {
                @(
                    @{
                        IPAddress      = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        PrefixLength   = [System.Byte] 24
                        AddressFamily  = 'IPv4'
                    },
                    @{
                        IPAddress      = '172.16.4.19'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        PrefixLength   = [System.Byte] 16
                        AddressFamily  = 'IPv4'
                    }
                )
            }

            Mock -CommandName New-NetIPAddress

            Mock -CommandName Get-NetRoute {
                @{
                    InterfaceAlias    = 'Ethernet'
                    InterfaceIndex    = 1
                    AddressFamily     = 'IPv4'
                    NextHop           = '192.168.0.254'
                    DestinationPrefix = '0.0.0.0/0'
                }
            }

            Mock -CommandName Remove-NetIPAddress

            Mock -CommandName Remove-NetRoute
        }

        Context 'Invoked with different prefixes' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = '10.0.0.2/24', '172.16.4.19/16'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 2 -Scope Context
            }
        }

        Context 'Invoked with existing IP with different prefix' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress      = '172.16.4.19/24'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with parameter "KeepExistingAddress" and different prefixes' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress           = '10.0.0.2/24', '172.16.4.19/16'
                        InterfaceAlias      = 'Ethernet'
                        AddressFamily       = 'IPv4'
                        KeepExistingAddress = $true
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 0 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 2 -Scope Context
            }
        }

        Context 'Invoked with parameter "KeepExistingAddress" and existing IP with different prefix' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress           = '172.16.4.19/24'
                        InterfaceAlias      = 'Ethernet'
                        AddressFamily       = 'IPv4'
                        KeepExistingAddress = $true
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Remove-NetIPAddress -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName New-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }
    }
}

Describe 'DSC_IPAddress\Test-TargetResource' -Tag 'Test' {
    Context 'A single IPv4 address is currently set on the adapter' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name = 'Ethernet'
                }
            }

            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = '192.168.0.15'
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 16
                    AddressFamily  = 'IPv4'
                }
            }
        }

        Context 'Invoked with invalid IPv4 Address' {
            It 'Should throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = 'BadAddress'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    { $result = Test-TargetResource @testGetResourceParameters } | Should -Throw
                }
            }
        }

        Context 'Invoked with different IPv4 Address' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = '192.168.0.1/16'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with the same IPv4 Address' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = '192.168.0.15/16'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeTrue
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with the same IPv4 Address but different prefix length' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = '192.168.0.15/24'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'Multiple IPv4 addresses are currently set on the adapter' {
        BeforeEach {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name = 'Ethernet'
                }
            }

            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = @('192.168.0.15', '192.168.0.16')
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 16
                    AddressFamily  = 'IPv4'
                }
            }
        }

        Context 'Invoked with multiple different IPv4 Addresses' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = @('192.168.0.1/16', '192.168.0.2/16')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with a single different IPv4 Address' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = '192.168.0.1/16'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with the same IPv4 Addresses' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = @('192.168.0.15/16', '192.168.0.16/16')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeTrue
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with the combination of same and different IPv4 Addresses' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = @('192.168.0.1/16', '192.168.0.16/16')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with a single different Class A IPv4 Address with no prefix' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = '10.1.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with a single different Class B IPv4 Address with no prefix' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = '172.16.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with a single different Class C IPv4 Address with no prefix' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'A single IPv4 address with 8 bit prefix is currently set on the adapter' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name = 'Ethernet'
                }
            }

            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = @('10.1.0.1')
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 8
                    AddressFamily  = 'IPv4'
                }
            }
        }

        Context 'Invoked with the same Class A IPv4 Address with no prefix' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = '10.1.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeTrue
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'A single IPv4 address with 16 bit prefix is currently set on the adapter' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name = 'Ethernet'
                }
            }

            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = @('172.16.0.1')
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 16
                    AddressFamily  = 'IPv4'
                }
            }
        }

        Context 'Invoked with the same Class B IPv4 Address with no prefix' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = '172.16.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeTrue
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'A single IPv4 address with 24 bit prefix is currently set on the adapter' {
        BeforeEach {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name = 'Ethernet'
                }
            }

            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = @('192.168.0.1')
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 24
                    AddressFamily  = 'IPv4'
                }
            }
        }

        Context 'Invoked with the same Class C IPv4 Address with no prefix' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeTrue
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'A single IPv6 address with 64 bit prefix is currently set on the adapter' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name = 'Ethernet'
                }
            }

            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = 'fe80::15'
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 64
                    AddressFamily  = 'IPv6'
                }
            }
        }

        Context 'Invoked with invalid IPv6 Address' {
            It 'Should throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = 'BadAddress'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    { $result = Test-TargetResource @testGetResourceParameters } | Should -Throw
                }
            }
        }

        Context 'Invoked with different IPv6 Address' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = 'fe80::1/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with the same IPv6 Address' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = 'fe80::15/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }
                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeTrue
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with the same IPv6 Address with no prefix' {
            It 'testGetResourceParameters return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = 'fe80::15'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeTrue
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'Multiple IPv6 addresses with 64 bit prefix are currently set on the adapter' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith {
                @{
                    Name = 'Ethernet'
                }
            }

            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = @('fe80::15', 'fe80::16')
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 64
                    AddressFamily  = 'IPv6'
                }
            }
        }

        Context 'Invoked with multiple different IPv6 Addresses' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = @('fe80::1/64', 'fe80::2/64')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with a single different IPv6 Address' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = 'fe80::1/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with the same IPv6 Addresses' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = @('fe80::15/64', 'fe80::16/64')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeTrue
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with a mix of the same and different IPv6 Addresses' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = @('fe80::1/64', 'fe80::16/64')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }

        Context 'Invoked with a single different IPv6 Address with no prefix' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress      = 'fe80::1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeFalse
                }
            }

            It 'Should call appropriate mocks' {
                Should -Invoke -CommandName Get-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }
    }
}

Describe 'DSC_IPAddress\Assert-ResourceProperty' {
    BeforeAll {
        Mock -CommandName Get-NetAdapter -MockWith {
            @{
                Name = 'Ethernet'
            }
        }
    }

    Context 'Invoked with bad interface alias' {
        It 'Should throw an InterfaceNotAvailable error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = '192.168.0.1/16'
                    InterfaceAlias = 'NotReal'
                    AddressFamily  = 'IPv4'
                }

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.InterfaceNotAvailableError -f $assertResourcePropertyParameters.InterfaceAlias) `
                    -ArgumentName 'InterfaceAlias'

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $errorRecord
            }
        }
    }

    Context 'Invoked with invalid IP Address' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = 'NotReal'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw
            }
        }
    }

    Context 'Invoked with IPv4 Address and IPv6 family mismatch' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = '192.168.0.1/16'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv6'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw
            }
        }
    }

    Context 'Invoked with IPv6 Address and IPv4 family mismatch' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = 'fe80::15'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw
            }
        }
    }

    Context 'Invoked with valid IPv4 Address' {
        It 'Should Not Throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = '192.168.0.1/16'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
            }
        }
    }

    Context 'Invoked with multiple valid IPv4 Addresses' {
        It 'Should Not Throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = @('192.168.0.1/24', '192.168.0.2/24')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
            }
        }
    }

    Context 'Invoked with valid IPv6 Address' {
        It 'Should Not Throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = 'fe80:ab04:30F5:002b::1/64'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv6'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
            }
        }
    }

    Context 'Invoked with invalid IPv4 prefix length' {
        It 'Should throw a PrefixLengthError when greater than 32' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = '192.168.0.1/33'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $prefixLength = ($assertResourcePropertyParameters.IPAddress -split '/')[-1]

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.PrefixLengthError -f $prefixLength, $assertResourcePropertyParameters.AddressFamily) `
                    -ArgumentName 'IPAddress'

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $errorRecord
            }
        }

        It 'Should throw an Argument error when less than 0' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = '192.168.0.1/-1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw ('*' + 'Value was either too large or too small for a UInt32.' + '*')
            }
        }
    }

    Context 'Invoked with invalid IPv6 prefix length' {
        It 'Should throw a PrefixLengthError error when greater than 128' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = 'fe80::1/129'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv6'
                }

                $prefixLength = ($assertResourcePropertyParameters.IPAddress -split '/')[-1]

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.PrefixLengthError -f $prefixLength, $assertResourcePropertyParameters.AddressFamily) `
                    -ArgumentName 'IPAddress'

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $errorRecord
            }
        }

        It 'Should throw an Argument error when less than 0' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = 'fe80::1/-1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv6'
                }

                # Needs an OverflowException helper
                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw ('*' + 'Value was either too large or too small for a UInt32.' + '*')
            }
        }
    }

    Context 'Invoked with valid string IPv6 prefix length' {
        It 'Should Not Throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertResourcePropertyParameters = @{
                    IPAddress      = 'fe80::1/64'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv6'
                }

                { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
            }
        }
    }
}
