$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetAdapterName'

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

        Describe 'DSC_NetAdapterName\Get-TargetResource' -Tag 'Get' {
            Context 'Renamed adapter can be found' {
                Mock `
                    -CommandName Find-NetworkAdapter `
                    -MockWith { $script:mockRenamedAdapter } `
                    -ParameterFilter { $Name -eq $script:newAdapterName }

                It 'Should not throw' {
                    { $script:result = Get-TargetResource @adapterParameters -Verbose } | Should -Not -Throw
                }

                It 'Should return existing adapter' {
                    $script:result.Name | Should -Be $script:mockRenamedAdapter.Name
                    $script:result.PhysicalMediaType | Should -Be $script:mockRenamedAdapter.PhysicalMediaType
                    $script:result.Status | Should -Be $script:mockRenamedAdapter.Status
                    $script:result.MacAddress | Should -Be $script:mockRenamedAdapter.MacAddress
                    $script:result.InterfaceDescription | Should -Be $script:mockRenamedAdapter.InterfaceDescription
                    $script:result.InterfaceIndex | Should -Be $script:mockRenamedAdapter.InterfaceIndex
                    $script:result.InterfaceGuid | Should -Be $script:mockRenamedAdapter.InterfaceGuid
                    $script:result.DriverDescription | Should -Be $script:mockRenamedAdapter.DriverDescription
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
                    $script:result.Name | Should -Be $script:mockAdapter.Name
                    $script:result.PhysicalMediaType | Should -Be $script:mockAdapter.PhysicalMediaType
                    $script:result.Status | Should -Be $script:mockAdapter.Status
                    $script:result.MacAddress | Should -Be $script:mockAdapter.MacAddress
                    $script:result.InterfaceDescription | Should -Be $script:mockAdapter.InterfaceDescription
                    $script:result.InterfaceIndex | Should -Be $script:mockAdapter.InterfaceIndex
                    $script:result.InterfaceGuid | Should -Be $script:mockAdapter.InterfaceGuid
                    $script:result.DriverDescription | Should -Be $script:mockAdapter.DriverDescription
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

        Describe 'DSC_NetAdapterName\Set-TargetResource' -Tag 'Set' {
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

        Describe 'DSC_NetAdapterName\Test-TargetResource' -Tag 'Test' {
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
                    $script:result | Should -Be $false
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
}
finally
{
    Invoke-TestCleanup
}
