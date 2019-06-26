$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetIPInterface'

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
        <#
            This is an array of parameters that will be used with pester test cases
            to test each individual parameter. The array contains a hash table
            representing each paramter to test. The properties of the hash table are
            - Name: the name of the parameter.
            - MockedValue: The value that the mock for Get-NetIPInterface will return for
              the parameter
            - TestValue: The value that will be used to change the setting to.
            - ParameterFilter: The parameter filter condition used to determine if the
              value has been successfully set in Set-TargetResource.
        #>
        $testParameterList = @(
            @{
                Name = 'AdvertiseDefaultRoute'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $AdvertiseDefaultRoute -eq 'Disabled'
                }
            },
            @{
                Name = 'Advertising'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Advertising -eq 'Disabled'
                }
            },
            @{
                Name = 'AutomaticMetric'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $AutomaticMetric -eq 'Disabled'
                }
            },
            @{
                Name = 'Dhcp'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Dhcp -eq 'Disabled'
                }
            },
            @{
                Name = 'DirectedMacWolPattern'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $DirectedMacWolPattern -eq 'Disabled'
                }
            },
            @{
                Name = 'EcnMarking'
                MockedValue = 'AppDecide'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $EcnMarking -eq 'Disabled'
                }
            },
            @{
                Name = 'ForceArpNdWolPattern'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $ForceArpNdWolPattern -eq 'Disabled'
                }
            },
            @{
                Name = 'Forwarding'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Forwarding -eq 'Disabled'
                }
            },
            @{
                Name = 'IgnoreDefaultRoutes'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $IgnoreDefaultRoutes -eq 'Disabled'
                }
            },
            @{
                Name = 'ManagedAddressConfiguration'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $ManagedAddressConfiguration -eq 'Disabled'
                }
            },
            @{
                Name = 'NeighborUnreachabilityDetection'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $NeighborUnreachabilityDetection -eq 'Disabled'
                }
            },
            @{
                Name = 'OtherStatefulConfiguration'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $OtherStatefulConfiguration -eq 'Disabled'
                }
            },
            @{
                Name = 'RouterDiscovery'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $RouterDiscovery -eq 'Disabled'
                }
            },
            @{
                Name = 'WeakHostReceive'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $WeakHostReceive -eq 'Disabled'
                }
            },
            @{
                Name = 'WeakHostSend'
                MockedValue = 'Enabled'
                TestValue = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $WeakHostSend -eq 'Disabled'
                }
            }
        )

        $script:netIPInterfaceExists = @{
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            Verbose        = $true
        }

        $script:netIPInterfaceExists_ParameterFilter = {
            $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4'
        }

        $script:netIPInterfaceExists_Settings = @{
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }

        foreach ($parameter in $testParameterList)
        {
            $null = $script:netIPInterfaceExists_Settings.Add($parameter.Name,$parameter.MockedValue)
        }

        $script:netIPInterfaceMissing = @{
            InterfaceAlias = 'EthernetDoesNotExist'
            AddressFamily  = 'IPv4'
            Verbose        = $true
        }

        $script:netIPInterfaceMissing_ParameterFilter = {
            $InterfaceAlias -eq 'EthernetDoesNotExist' -and $AddressFamily -eq 'IPv4'
        }

        Describe 'MSFT_NetIPInterface\Get-TargetResource' -Tag 'Get' {
            Context 'When called with alias and address family of an existing interface' {
                Mock `
                    -CommandName Get-NetworkIPInterface `
                    -ParameterFilter $script:netIPInterfaceExists_ParameterFilter `
                    -MockWith { $script:netIPInterfaceExists_Settings }

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource @script:netIPInterfaceExists
                    } | Should -Not -Throw
                }

                It 'Should return <MockedValue> for parameter <Name>' -TestCases $testParameterList {
                    param
                    (
                        $Name, $MockedValue, $TestValue, $ParameterFilter
                    )

                    $script:result[$Name] | Should -Be $MockedValue
                }
            }
        }

        Describe 'MSFT_NetIPInterface\Test-TargetResource' -Tag 'Test' {
            Context 'When called with alias and address family of an existing interface and a mismatching value' {
                Mock `
                    -CommandName Get-NetworkIPInterface `
                    -ParameterFilter $script:netIPInterfaceExists_ParameterFilter `
                    -MockWith { $script:netIPInterfaceExists_Settings }

                It 'Should return $false when existing value for parameter <Name> is set to <TestValue> but should be <MockedValue>' -TestCases $testParameterList {
                    param
                    (
                        $Name, $MockedValue, $TestValue, $ParameterFilter
                    )

                    $comparisonParameter = @{
                        $Name = $TestValue
                    }

                    $script:result = Test-TargetResource @script:netIPInterfaceExists @comparisonParameter

                    $script:result | Should -Be $false
                }
            }

            Context 'When called with alias and address family of an existing interface and no mismatching values' {
                Mock `
                    -CommandName Get-NetworkIPInterface `
                    -ParameterFilter $script:netIPInterfaceExists_ParameterFilter `
                    -MockWith { $script:netIPInterfaceExists_Settings }

                It 'Should return $true when existing value for parameter <Name> is set to <TestValue> and should be <TestValue>' -TestCases $testParameterList {
                    param
                    (
                        $Name, $MockedValue, $TestValue, $ParameterFilter
                    )

                    $comparisonParameter = @{
                        $Name = $MockedValue
                    }

                    $script:result = Test-TargetResource @script:netIPInterfaceExists @comparisonParameter

                    $script:result | Should -Be $true
                }
            }
        }

        Describe 'MSFT_NetIPInterface\Set-TargetResource' -Tag 'Set' {
            Context 'When called with alias and address family of an existing interface and a mismatching value' {
                Mock `
                    -CommandName Get-NetworkIPInterface `
                    -ParameterFilter $script:netIPInterfaceExists_ParameterFilter `
                    -MockWith { $script:netIPInterfaceExists_Settings }

                It 'Should set parameter <Name> to <TestValue>' -TestCases $testParameterList {
                    param
                    (
                        $Name, $MockedValue, $TestValue, $ParameterFilter
                    )

                    $comparisonParameter = @{
                        $Name = $TestValue
                    }

                    Mock `
                        -CommandName Set-NetIPInterface

                    Set-TargetResource @script:netIPInterfaceExists @comparisonParameter

                    Assert-MockCalled `
                        -CommandName Set-NetIPInterface `
                        -ParameterFilter $ParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'When called with alias and address family of an existing interface and no mismatching values' {
                Mock `
                    -CommandName Get-NetworkIPInterface `
                    -ParameterFilter $script:netIPInterfaceExists_ParameterFilter `
                    -MockWith { $script:netIPInterfaceExists_Settings }

                It 'Should not call Set-NetIPInterface' {
                    $comparisonParameter = @{
                        $testParameterList[0].Name = $testParameterList[0].MockedValue
                    }

                    Mock `
                        -CommandName Set-NetIPInterface

                    Set-TargetResource @script:netIPInterfaceExists @comparisonParameter

                    Assert-MockCalled `
                        -CommandName Set-NetIPInterface `
                        -ParameterFilter $ParameterFilter `
                        -Exactly -Times 0
                }
            }
        }

        Describe 'MSFT_NetIPInterface\Get-NetworkIPInterface' {
            Context 'When called with alias and address family of an interface that does not exist' {
                Mock `
                    -CommandName Get-NetIPInterface `
                    -ParameterFilter $script:netIPInterfaceMissing_ParameterFilter

                It 'Should throw expected exception' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.NetIPInterfaceDoesNotExistMessage -f $script:netIPInterfaceMissing.InterfaceAlias, $script:netIPInterfaceMissing.AddressFamily)

                    {
                        $script:result = Get-NetworkIPInterface @script:netIPInterfaceMissing
                    } | Should -Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetIPInterface `
                        -ParameterFilter $script:netIPInterfaceMissing_ParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'When called with alias and address family of an existing interface' {
                Mock `
                    -CommandName Get-NetIPInterface `
                    -ParameterFilter $script:netIPInterfaceExists_ParameterFilter `
                    -MockWith { $script:netIPInterfaceExists_Settings }

                It 'Should not throw exception' {
                    {
                        $script:result = Get-NetworkIPInterface @script:netIPInterfaceExists
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-NetIPInterface `
                        -ParameterFilter $script:netIPInterfaceExists_ParameterFilter `
                        -Exactly -Times 1
                }
            }
        }
    } #end InModuleScope $DSCResourceName
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
