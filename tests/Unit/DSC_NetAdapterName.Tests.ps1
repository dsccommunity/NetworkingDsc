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
    $script:dscResourceName = 'DSC_NetAdapterName'

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

Describe 'DSC_NetAdapterName\Get-TargetResource' -Tag 'Get' {
    Context 'Renamed adapter can be found' {
        BeforeAll {
            Mock -CommandName Find-NetworkAdapter -MockWith {
                @{
                    Name                 = 'NewAdapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }
            } -ParameterFilter { $Name -eq 'NewAdapter' }
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $adapterParameters = @{
                    Name                 = 'Adapter'
                    NewName              = 'NewAdapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }

                { $script:result = Get-TargetResource @adapterParameters } | Should -Not -Throw
            }
        }

        It 'Should return existing adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockRenamedAdapter = @{
                    Name                 = 'NewAdapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }

                $script:result.Name | Should -Be $mockRenamedAdapter.Name
                $script:result.PhysicalMediaType | Should -Be $mockRenamedAdapter.PhysicalMediaType
                $script:result.Status | Should -Be $mockRenamedAdapter.Status
                $script:result.MacAddress | Should -Be $mockRenamedAdapter.MacAddress
                $script:result.InterfaceDescription | Should -Be $mockRenamedAdapter.InterfaceDescription
                $script:result.InterfaceIndex | Should -Be $mockRenamedAdapter.InterfaceIndex
                $script:result.InterfaceGuid | Should -Be $mockRenamedAdapter.InterfaceGuid
                $script:result.DriverDescription | Should -Be $mockRenamedAdapter.DriverDescription
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Find-NetworkAdapter -ParameterFilter { $Name -eq 'NewAdapter' } -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Renamed adapter not found but matching adapter can be found' {
        BeforeAll {
            Mock -CommandName Find-NetworkAdapter -ParameterFilter { $Name -eq 'NewAdapter' }
            Mock -CommandName Find-NetworkAdapter -MockWith {
                @{
                    Name                 = 'Adapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }
            } -ParameterFilter { $Name -eq 'Adapter' }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-TargetResource -Name 'Adapter' -NewName 'NewAdapter' } | Should -Not -Throw }
        }

        It 'Should return existing adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockAdapter = @{
                    Name                 = 'Adapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }

                $script:result.Name | Should -Be $mockAdapter.Name
                $script:result.PhysicalMediaType | Should -Be $mockAdapter.PhysicalMediaType
                $script:result.Status | Should -Be $mockAdapter.Status
                $script:result.MacAddress | Should -Be $mockAdapter.MacAddress
                $script:result.InterfaceDescription | Should -Be $mockAdapter.InterfaceDescription
                $script:result.InterfaceIndex | Should -Be $mockAdapter.InterfaceIndex
                $script:result.InterfaceGuid | Should -Be $mockAdapter.InterfaceGuid
                $script:result.DriverDescription | Should -Be $mockAdapter.DriverDescription
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Find-NetworkAdapter -ParameterFilter { $Name -eq 'Adapter' } -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Find-NetworkAdapter -ParameterFilter { $Name -eq 'NewAdapter' } -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetAdapterName\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            function script:Rename-NetAdapter
            {
                [CmdletBinding()]
                param (
                    [Parameter(ValueFromPipeline = $true)]
                    $InputObject,

                    [Parameter()]
                    [System.String]
                    $NewName
                )
            }
        }
    }

    Context 'Matching adapter can be found' {
        BeforeAll {
            Mock -CommandName Find-NetworkAdapter -MockWith {
                @{
                    Name                 = 'Adapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }
            }

            Mock -CommandName Rename-NetAdapter -MockWith {
                @{
                    Name                 = 'NewAdapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }
            } -ParameterFilter { $NewName -eq 'NewAdapter' }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $adapterParameters = @{
                    Name                 = 'Adapter'
                    NewName              = 'NewAdapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }

                { Set-TargetResource @adapterParameters } | Should -Not -Throw
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Find-NetworkAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Rename-NetAdapter -ParameterFilter { $NewName -eq 'NewAdapter' } -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetAdapterName\Test-TargetResource' -Tag 'Test' {
    Context 'Matching adapter can be found and has correct Name' {
        BeforeAll {
            Mock -CommandName Find-NetworkAdapter -MockWith {
                @{
                    Name                 = 'NewAdapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $adapterParameters = @{
                    Name                 = 'Adapter'
                    NewName              = 'NewAdapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }

                $script:result = Test-TargetResource @adapterParameters

                { $script:result } | Should -Not -Throw
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeTrue
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -commandName Find-NetworkAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Renamed adapter does not exist, but matching adapter can be found and has wrong Name' {
        BeforeAll {
            Mock -CommandName Find-NetworkAdapter -MockWith {
                @{
                    Name                 = 'Adapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }
            } -ParameterFilter { $Name -and $Name -eq 'Adapter' }

            Mock -CommandName Find-NetworkAdapter -ParameterFilter { $Name -and $Name -eq 'NewAdapter' }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $adapterParameters = @{
                    Name                 = 'Adapter'
                    NewName              = 'NewAdapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }

                { $script:result = Test-TargetResource @adapterParameters } | Should -Not -Throw
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeFalse
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Find-NetworkAdapter -Exactly -Times 1 -Scope Context -ParameterFilter { $Name -and $Name -eq 'Adapter' }
            Should -Invoke -CommandName Find-NetworkAdapter -Exactly -Times 1 -Scope Context -ParameterFilter { $Name -and $Name -eq 'NewAdapter' }
        }
    }

    Context 'Adapter name changed by Set-TargetResource' {
        BeforeAll {
            Mock -CommandName Find-NetworkAdapter -MockWith {
                @{
                    Name                 = 'NewAdapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }
            } -ParameterFilter {
                $Name -eq 'NewAdapter'
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $adapterParameters = @{
                    Name                 = 'Adapter'
                    NewName              = 'NewAdapter'
                    PhysicalMediaType    = '802.3'
                    Status               = 'Up'
                    MacAddress           = '11-22-33-44-55-66'
                    InterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
                    InterfaceIndex       = 2
                    InterfaceGuid        = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
                    DriverDescription    = 'Hyper-V Virtual Ethernet Adapter'
                }

                $script:result = Test-TargetResource @adapterParameters

                { $script:result } | Should -Not -Throw
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeTrue
            }
        }

        It 'Should call all the mocks' {
            Should -Invoke -CommandName Find-NetworkAdapter -ParameterFilter { $Name -eq 'NewAdapter' } -Exactly -Times 1 -Scope Context
        }
    }
}
