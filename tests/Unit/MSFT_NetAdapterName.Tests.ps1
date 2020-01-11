$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetAdapterName'

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
    InModuleScope $script:DSCResourceName {
        # Generate the adapter data to be used for Mocking
        $script:adapterName = 'Adapter'
        $script:newAdapterName = 'NewAdapter'
        $script:adapterPhysicalMediaType = '802.3'
        $script:adapterStatus = 'Up'
        $script:adapterMacAddress = '11-22-33-44-55-66'
        $script:adapterInterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
        $script:adapterInterfaceIndex = 2
        $script:adapterInterfaceGuid = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
        $script:adapterDriverDescription = 'Hyper-V Virtual Ethernet Adapter'

        $script:adapterParameters = [PSObject]@{
            Name                 = $script:adapterName
            NewName              = $script:newAdapterName
            PhysicalMediaType    = $script:adapterPhysicalMediaType
            Status               = $script:adapterStatus
            MacAddress           = $script:adapterMacAddress
            InterfaceDescription = $script:adapterInterfaceDescription
            InterfaceIndex       = $script:adapterInterfaceIndex
            InterfaceGuid        = $script:adapterInterfaceGuid
            DriverDescription    = $script:adapterDriverDescription
        }

        $script:mockAdapter = [PSObject]@{
            Name                 = $script:adapterName
            PhysicalMediaType    = $script:adapterPhysicalMediaType
            Status               = $script:adapterStatus
            MacAddress           = $script:adapterMacAddress
            InterfaceDescription = $script:adapterInterfaceDescription
            InterfaceIndex       = $script:adapterInterfaceIndex
            InterfaceGuid        = $script:adapterInterfaceGuid
            DriverDescription    = $script:adapterDriverDescription
        }

        $script:mockRenamedAdapter = [PSObject]@{
            Name                 = $script:newAdapterName
            PhysicalMediaType    = $script:adapterPhysicalMediaType
            Status               = $script:adapterStatus
            MacAddress           = $script:adapterMacAddress
            InterfaceDescription = $script:adapterInterfaceDescription
            InterfaceIndex       = $script:adapterInterfaceIndex
            InterfaceGuid        = $script:adapterInterfaceGuid
            DriverDescription    = $script:adapterDriverDescription
        }

        function Rename-NetAdapter
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

        Describe 'MSFT_NetAdapterName\Get-TargetResource' -Tag 'Get' {
            Context 'Renamed adapter can be found' {
                Mock `
                    -CommandName Find-NetworkAdapter `
                    -MockWith { $script:mockRenamedAdapter } `
                    -ParameterFilter { $Name -eq $script:newAdapterName }

                It 'Should not throw' {
                    { $script:result = Get-TargetResource @adapterParameters -Verbose } | Should -Not -Throw
                }

                It 'Should return existing adapter' {
                    $script:result.Name                 | Should -Be $script:mockRenamedAdapter.Name
                    $script:result.PhysicalMediaType    | Should -Be $script:mockRenamedAdapter.PhysicalMediaType
                    $script:result.Status               | Should -Be $script:mockRenamedAdapter.Status
                    $script:result.MacAddress           | Should -Be $script:mockRenamedAdapter.MacAddress
                    $script:result.InterfaceDescription | Should -Be $script:mockRenamedAdapter.InterfaceDescription
                    $script:result.InterfaceIndex       | Should -Be $script:mockRenamedAdapter.InterfaceIndex
                    $script:result.InterfaceGuid        | Should -Be $script:mockRenamedAdapter.InterfaceGuid
                    $script:result.DriverDescription    | Should -Be $script:mockRenamedAdapter.DriverDescription
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled `
                        -CommandName Find-NetworkAdapter -Exactly -Times 1 `
                        -ParameterFilter { $Name -eq $script:newAdapterName }
                }
            }

            Context 'Renamed adapter not found but matching adapter can be found' {
                Mock `
                    -CommandName Find-NetworkAdapter `
                    -ParameterFilter { $Name -eq $script:newAdapterName }

                Mock `
                    -CommandName Find-NetworkAdapter -MockWith { $script:mockAdapter } `
                    -ParameterFilter { $Name -eq $script:adapterName }

                It 'Should not throw exception' {
                    { $script:result = Get-TargetResource -Name $script:adapterName -NewName $script:newAdapterName -Verbose } | Should -Not -Throw
                }

                It 'Should return existing adapter' {
                    $script:result.Name                 | Should -Be $script:mockAdapter.Name
                    $script:result.PhysicalMediaType    | Should -Be $script:mockAdapter.PhysicalMediaType
                    $script:result.Status               | Should -Be $script:mockAdapter.Status
                    $script:result.MacAddress           | Should -Be $script:mockAdapter.MacAddress
                    $script:result.InterfaceDescription | Should -Be $script:mockAdapter.InterfaceDescription
                    $script:result.InterfaceIndex       | Should -Be $script:mockAdapter.InterfaceIndex
                    $script:result.InterfaceGuid        | Should -Be $script:mockAdapter.InterfaceGuid
                    $script:result.DriverDescription    | Should -Be $script:mockAdapter.DriverDescription
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled `
                        -CommandName Find-NetworkAdapter -Exactly -Times 1 `
                        -ParameterFilter { $Name -eq $script:adapterName }

                    Assert-MockCalled `
                        -CommandName Find-NetworkAdapter -Exactly -Times 1 `
                        -ParameterFilter { $Name -eq $script:newAdapterName }
                }
            }
        }

        Describe 'MSFT_NetAdapterName\Set-TargetResource' -Tag 'Set' {
            Context 'Matching adapter can be found' {
                Mock `
                    -CommandName Find-NetworkAdapter `
                    -MockWith { $script:mockAdapter }

                Mock `
                    -CommandName Rename-NetAdapter `
                    -ParameterFilter { $NewName -eq $script:newAdapterName } `
                    -MockWith { $script:mockRenamedAdapter }

                It 'Should not throw exception' {
                    { Set-TargetResource @adapterParameters -Verbose } | Should -Not -Throw
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled `
                        -CommandName Find-NetworkAdapter -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Rename-NetAdapter -Exactly -Times 1 `
                        -ParameterFilter { $NewName -eq $script:newAdapterName }
                }
            }
        }

        Describe 'MSFT_NetAdapterName\Test-TargetResource' -Tag 'Test' {
            Context 'Matching adapter can be found and has correct Name' {
                Mock -CommandName Find-NetworkAdapter -MockWith { $script:mockRenamedAdapter }

                It 'Should not throw exception' {
                    { $script:result = Test-TargetResource @adapterParameters -Verbose } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -commandName Find-NetworkAdapter -Exactly -Times 1
                }
            }

            Context 'Renamed adapter does not exist, but matching adapter can be found and has wrong Name' {
                Mock `
                    -CommandName Find-NetworkAdapter `
                    -MockWith { $script:mockAdapter } `
                    -ParameterFilter { $Name -and $Name -eq $script:AdapterName }

                Mock `
                    -CommandName Find-NetworkAdapter `
                    -ParameterFilter { $Name -and $Name -eq $script:newAdapterName }

                It 'Should not throw exception' {
                    { $script:result = Test-TargetResource @adapterParameters -Verbose } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result  | Should -Be $false
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled `
                        -CommandName Find-NetworkAdapter -Exactly -Times 1 `
                        -ParameterFilter { $Name -and $Name -eq $script:AdapterName }

                    Assert-MockCalled `
                        -CommandName Find-NetworkAdapter -Exactly -Times 1 `
                        -ParameterFilter { $Name -and $Name -eq $script:newAdapterName }
                }
            }

            Context 'Adapter name changed by Set-TargetResource' {
                Mock `
                    -CommandName Find-NetworkAdapter `
                    -MockWith { $script:mockRenamedAdapter } `
                    -ParameterFilter { $Name -and $Name -eq $script:newAdapterName }

                It 'Should not throw exception' {
                    { $script:result = Test-TargetResource @adapterParameters -Verbose } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $true
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled `
                        -CommandName Find-NetworkAdapter -Exactly -Times 1 `
                        -ParameterFilter { $Name -and $Name -eq $script:newAdapterName }
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
