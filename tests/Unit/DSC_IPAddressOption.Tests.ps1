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
    $script:dscResourceName = 'DSC_IPAddressOption'

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

Describe 'DSC_IPAddressOption\Get-TargetResource' -Tag 'Get' {
    Context 'Invoked with an existing IP address' {
        BeforeAll {
            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 24
                    AddressFamily  = 'IPv4'
                    SkipAsSource   = $true
                }
            }
        }

        It 'Should return existing IP options' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceParameters = @{
                    IPAddress = '192.168.0.1'
                }

                $result = Get-TargetResource @getTargetResourceParameters
                $result.IPAddress | Should -Be $getTargetResourceParameters.IPAddress
                $result.SkipAsSource | Should -BeTrue
            }
        }
    }
}

Describe 'DSC_IPAddressOption\Set-TargetResource' -Tag 'Set' {
    Context 'Invoked with an existing IP address, SkipAsSource = $false' {
        BeforeAll {
            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 24
                    AddressFamily  = 'IPv4'
                    SkipAsSource   = $false
                }
            }

            Mock -CommandName Set-NetIPAddress
        }

        Context 'Invoked with valid IP address' {
            It 'Should return $null' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IPAddress    = '192.168.0.1'
                        SkipAsSource = $true
                    }

                    $result = Set-TargetResource @setTargetResourceParameters

                    { $result } | Should -Not -Throw
                    $result | Should -BeNullOrEmpty
                }
            }

            It 'Should call all the mock' {
                Should -Invoke -CommandName Set-NetIPAddress -Exactly -Times 1 -Scope Context
            }
        }
    }
}

Describe 'DSC_IPAddressOption\Test-TargetResource' -Tag 'Test' {
    Context 'Invoked with an existing IP address, SkipAsSource = $true' {
        BeforeAll {
            Mock -CommandName Get-NetIPAddress -MockWith {
                @{
                    IPAddress      = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength   = [System.Byte] 24
                    AddressFamily  = 'IPv4'
                    SkipAsSource   = $true
                }
            }
        }

        Context 'Invoked with valid IP address' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testGetResourceParameters = @{
                        IPAddress    = '192.168.0.1'
                        SkipAsSource = $true
                    }

                    $result = Test-TargetResource @testGetResourceParameters
                    $result | Should -BeTrue
                }
            }
        }
    }
}
