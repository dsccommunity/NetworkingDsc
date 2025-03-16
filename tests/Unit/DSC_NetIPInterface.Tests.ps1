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

    # Import the NetTCPIP module
    Import-Module -Name NetTCPIP
}

BeforeAll {
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceName = 'DSC_NetIPInterface'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Import the NetTCPIP module
    Import-Module -Name NetTCPIP

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

    # Remove module NetTCPIP.
    Get-Module -Name 'NetTCPIP' -All | Remove-Module -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_NetIPInterface\Get-TargetResource' -Tag 'Get' {
    BeforeDiscovery {
        <#
        This is an array of parameters that will be used with pester test cases
        to test each individual parameter. The array contains a hash table
        representing each parameter to test. The properties of the hash table are
        - Name: the name of the parameter.
        - MockedValue: The value that the mock for Get-NetIPInterface will return for
          the parameter
        - TestValue: The value that will be used to change the setting to.
        - ParameterFilter: The parameter filter condition used to determine if the
          value has been successfully set in Set-TargetResource.
        #>
        $testParameterList = @(
            @{
                Name            = 'AdvertiseDefaultRoute'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AdvertiseDefaultRoute]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $AdvertiseDefaultRoute -eq 'Disabled'
                }
            },
            @{
                Name            = 'Advertising'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Advertising]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Advertising -eq 'Disabled'
                }
            },
            @{
                Name            = 'AutomaticMetric'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AutomaticMetric]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $AutomaticMetric -eq 'Disabled'
                }
            },
            @{
                Name            = 'Dhcp'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Dhcp]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Dhcp -eq 'Disabled'
                }
            },
            @{
                Name            = 'DirectedMacWolPattern'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.DirectedMacWolPattern]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $DirectedMacWolPattern -eq 'Disabled'
                }
            },
            @{
                Name            = 'EcnMarking'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.EcnMarking]::AppDecide
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $EcnMarking -eq 'Disabled'
                }
            },
            @{
                Name            = 'ForceArpNdWolPattern'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ForceArpNdWolPattern]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $ForceArpNdWolPattern -eq 'Disabled'
                }
            },
            @{
                Name            = 'Forwarding'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Forwarding]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Forwarding -eq 'Disabled'
                }
            },
            @{
                Name            = 'IgnoreDefaultRoutes'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.IgnoreDefaultRoutes]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $IgnoreDefaultRoutes -eq 'Disabled'
                }
            },
            @{
                Name            = 'ManagedAddressConfiguration'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ManagedAddressConfiguration]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $ManagedAddressConfiguration -eq 'Disabled'
                }
            },
            @{
                Name            = 'NeighborUnreachabilityDetection'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.NeighborUnreachabilityDetection]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $NeighborUnreachabilityDetection -eq 'Disabled'
                }
            },
            @{
                Name            = 'OtherStatefulConfiguration'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.OtherStatefulConfiguration]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $OtherStatefulConfiguration -eq 'Disabled'
                }
            },
            @{
                Name            = 'RouterDiscovery'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.RouterDiscovery]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $RouterDiscovery -eq 'Disabled'
                }
            },
            @{
                Name            = 'WeakHostReceive'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostReceive]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $WeakHostReceive -eq 'Disabled'
                }
            },
            @{
                Name            = 'WeakHostSend'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostSend]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $WeakHostSend -eq 'Disabled'
                }
            },
            @{
                Name            = 'NlMtu'
                MockedValue     = [System.Uint32] 1600
                TestValue       = [System.Uint32] 1500
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $NlMtuBytes -eq 1500
                }
            },
            @{
                Name            = 'InterfaceMetric'
                MockedValue     = [System.Uint32] 20
                TestValue       = [System.Uint32] 15
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $InterfaceMetric -eq 15
                }
            }
        )
    }

    Context 'When called with alias and address family of an existing interface' {
        BeforeAll {
            Mock -CommandName Get-NetworkIPInterface -ParameterFilter {
                $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4'
            } -MockWith {
                @{
                    InterfaceAlias                  = 'Ethernet'
                    AddressFamily                   = 'IPv4'
                    AdvertiseDefaultRoute           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AdvertiseDefaultRoute]::Enabled
                    Advertising                     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Advertising]::Enabled
                    AutomaticMetric                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AutomaticMetric]::Enabled
                    Dhcp                            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Dhcp]::Enabled
                    DirectedMacWolPattern           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.DirectedMacWolPattern]::Enabled
                    EcnMarking                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.EcnMarking]::AppDecide
                    ForceArpNdWolPattern            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ForceArpNdWolPattern]::Enabled
                    Forwarding                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Forwarding]::Enabled
                    IgnoreDefaultRoutes             = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.IgnoreDefaultRoutes]::Enabled
                    ManagedAddressConfiguration     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ManagedAddressConfiguration]::Enabled
                    NeighborUnreachabilityDetection = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.NeighborUnreachabilityDetection]::Enabled
                    OtherStatefulConfiguration      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.OtherStatefulConfiguration]::Enabled
                    RouterDiscovery                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.RouterDiscovery]::Enabled
                    WeakHostReceive                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostReceive]::Enabled
                    WeakHostSend                    = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostSend]::Enabled
                    NlMtu                           = [System.Uint32] 1600
                    InterfaceMetric                 = [System.Uint32] 20
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $netIPInterfaceExists = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { $script:result = Get-TargetResource @netIPInterfaceExists } | Should -Not -Throw
            }
        }

        It 'Should return <MockedValue> for parameter <Name>' -ForEach $testParameterList {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result[$Name] | Should -Be $MockedValue
            }
        }
    }
}

Describe 'DSC_NetIPInterface\Test-TargetResource' -Tag 'Test' {
    BeforeDiscovery {
        BeforeDiscovery {
            <#
            This is an array of parameters that will be used with pester test cases
            to test each individual parameter. The array contains a hash table
            representing each parameter to test. The properties of the hash table are
            - Name: the name of the parameter.
            - MockedValue: The value that the mock for Get-NetIPInterface will return for
              the parameter
            - TestValue: The value that will be used to change the setting to.
            - ParameterFilter: The parameter filter condition used to determine if the
              value has been successfully set in Set-TargetResource.
        #>
            $testParameterList = @(
                @{
                    Name            = 'AdvertiseDefaultRoute'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AdvertiseDefaultRoute]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $AdvertiseDefaultRoute -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'Advertising'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Advertising]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Advertising -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'AutomaticMetric'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AutomaticMetric]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $AutomaticMetric -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'Dhcp'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Dhcp]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Dhcp -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'DirectedMacWolPattern'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.DirectedMacWolPattern]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $DirectedMacWolPattern -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'EcnMarking'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.EcnMarking]::AppDecide
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $EcnMarking -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'ForceArpNdWolPattern'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ForceArpNdWolPattern]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $ForceArpNdWolPattern -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'Forwarding'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Forwarding]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Forwarding -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'IgnoreDefaultRoutes'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.IgnoreDefaultRoutes]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $IgnoreDefaultRoutes -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'ManagedAddressConfiguration'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ManagedAddressConfiguration]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $ManagedAddressConfiguration -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'NeighborUnreachabilityDetection'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.NeighborUnreachabilityDetection]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $NeighborUnreachabilityDetection -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'OtherStatefulConfiguration'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.OtherStatefulConfiguration]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $OtherStatefulConfiguration -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'RouterDiscovery'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.RouterDiscovery]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $RouterDiscovery -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'WeakHostReceive'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostReceive]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $WeakHostReceive -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'WeakHostSend'
                    MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostSend]::Enabled
                    TestValue       = 'Disabled'
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $WeakHostSend -eq 'Disabled'
                    }
                },
                @{
                    Name            = 'NlMtu'
                    MockedValue     = [System.Uint32] 1600
                    TestValue       = [System.Uint32] 1500
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $NlMtuBytes -eq 1500
                    }
                },
                @{
                    Name            = 'InterfaceMetric'
                    MockedValue     = [System.Uint32] 20
                    TestValue       = [System.Uint32] 15
                    ParameterFilter = {
                        $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $InterfaceMetric -eq 15
                    }
                }
            )
        }
    }

    Context 'When called with alias and address family of an existing interface and a mismatching value' {
        BeforeAll {
            Mock -CommandName Get-NetworkIPInterface `
                -ParameterFilter {
                $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4'
            } -MockWith {
                @{
                    InterfaceAlias                  = 'Ethernet'
                    AddressFamily                   = 'IPv4'
                    AdvertiseDefaultRoute           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AdvertiseDefaultRoute]::Enabled
                    Advertising                     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Advertising]::Enabled
                    AutomaticMetric                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AutomaticMetric]::Enabled
                    Dhcp                            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Dhcp]::Enabled
                    DirectedMacWolPattern           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.DirectedMacWolPattern]::Enabled
                    EcnMarking                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.EcnMarking]::AppDecide
                    ForceArpNdWolPattern            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ForceArpNdWolPattern]::Enabled
                    Forwarding                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Forwarding]::Enabled
                    IgnoreDefaultRoutes             = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.IgnoreDefaultRoutes]::Enabled
                    ManagedAddressConfiguration     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ManagedAddressConfiguration]::Enabled
                    NeighborUnreachabilityDetection = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.NeighborUnreachabilityDetection]::Enabled
                    OtherStatefulConfiguration      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.OtherStatefulConfiguration]::Enabled
                    RouterDiscovery                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.RouterDiscovery]::Enabled
                    WeakHostReceive                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostReceive]::Enabled
                    WeakHostSend                    = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostSend]::Enabled
                    NlMtu                           = [System.Uint32] 1600
                    InterfaceMetric                 = [System.Uint32] 20
                }
            }
        }

        It 'Should return $false when existing value for parameter <Name> is set to <TestValue> but should be <MockedValue>' -ForEach $testParameterList {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $netIPInterfaceExists = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $comparisonParameter = @{
                    $Name = $TestValue
                }

                $result = Test-TargetResource @netIPInterfaceExists @comparisonParameter

                $result | Should -BeFalse
            }
        }
    }

    Context 'When called with alias and address family of an existing interface and no mismatching values' {
        BeforeAll {
            Mock -CommandName Get-NetworkIPInterface -ParameterFilter {
                $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4'
            } -MockWith {
                @{
                    InterfaceAlias                  = 'Ethernet'
                    AddressFamily                   = 'IPv4'
                    AdvertiseDefaultRoute           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AdvertiseDefaultRoute]::Enabled
                    Advertising                     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Advertising]::Enabled
                    AutomaticMetric                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AutomaticMetric]::Enabled
                    Dhcp                            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Dhcp]::Enabled
                    DirectedMacWolPattern           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.DirectedMacWolPattern]::Enabled
                    EcnMarking                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.EcnMarking]::AppDecide
                    ForceArpNdWolPattern            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ForceArpNdWolPattern]::Enabled
                    Forwarding                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Forwarding]::Enabled
                    IgnoreDefaultRoutes             = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.IgnoreDefaultRoutes]::Enabled
                    ManagedAddressConfiguration     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ManagedAddressConfiguration]::Enabled
                    NeighborUnreachabilityDetection = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.NeighborUnreachabilityDetection]::Enabled
                    OtherStatefulConfiguration      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.OtherStatefulConfiguration]::Enabled
                    RouterDiscovery                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.RouterDiscovery]::Enabled
                    WeakHostReceive                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostReceive]::Enabled
                    WeakHostSend                    = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostSend]::Enabled
                    NlMtu                           = [System.Uint32] 1600
                    InterfaceMetric                 = [System.Uint32] 20
                }
            }
        }

        It 'Should return $true when existing value for parameter <Name> is set to <TestValue> and should be <TestValue>' -ForEach $testParameterList {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $netIPInterfaceExists = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $comparisonParameter = @{
                    $Name = $MockedValue
                }

                $result = Test-TargetResource @netIPInterfaceExists @comparisonParameter

                $result | Should -BeTrue
            }
        }
    }
}

Describe 'DSC_NetIPInterface\Set-TargetResource' -Tag 'Set' {
    BeforeDiscovery {
        <#
            This is an array of parameters that will be used with pester test cases
            to test each individual parameter. The array contains a hash table
            representing each parameter to test. The properties of the hash table are
            - Name: the name of the parameter.
            - MockedValue: The value that the mock for Get-NetIPInterface will return for
              the parameter
            - TestValue: The value that will be used to change the setting to.
            - ParameterFilter: The parameter filter condition used to determine if the
              value has been successfully set in Set-TargetResource.
        #>
        $testParameterList = @(
            @{
                Name            = 'AdvertiseDefaultRoute'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AdvertiseDefaultRoute]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $AdvertiseDefaultRoute -eq 'Disabled'
                }
            },
            @{
                Name            = 'Advertising'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Advertising]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Advertising -eq 'Disabled'
                }
            },
            @{
                Name            = 'AutomaticMetric'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AutomaticMetric]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $AutomaticMetric -eq 'Disabled'
                }
            },
            @{
                Name            = 'Dhcp'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Dhcp]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Dhcp -eq 'Disabled'
                }
            },
            @{
                Name            = 'DirectedMacWolPattern'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.DirectedMacWolPattern]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $DirectedMacWolPattern -eq 'Disabled'
                }
            },
            @{
                Name            = 'EcnMarking'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.EcnMarking]::AppDecide
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $EcnMarking -eq 'Disabled'
                }
            },
            @{
                Name            = 'ForceArpNdWolPattern'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ForceArpNdWolPattern]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $ForceArpNdWolPattern -eq 'Disabled'
                }
            },
            @{
                Name            = 'Forwarding'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Forwarding]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $Forwarding -eq 'Disabled'
                }
            },
            @{
                Name            = 'IgnoreDefaultRoutes'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.IgnoreDefaultRoutes]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $IgnoreDefaultRoutes -eq 'Disabled'
                }
            },
            @{
                Name            = 'ManagedAddressConfiguration'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ManagedAddressConfiguration]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $ManagedAddressConfiguration -eq 'Disabled'
                }
            },
            @{
                Name            = 'NeighborUnreachabilityDetection'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.NeighborUnreachabilityDetection]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $NeighborUnreachabilityDetection -eq 'Disabled'
                }
            },
            @{
                Name            = 'OtherStatefulConfiguration'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.OtherStatefulConfiguration]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $OtherStatefulConfiguration -eq 'Disabled'
                }
            },
            @{
                Name            = 'RouterDiscovery'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.RouterDiscovery]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $RouterDiscovery -eq 'Disabled'
                }
            },
            @{
                Name            = 'WeakHostReceive'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostReceive]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $WeakHostReceive -eq 'Disabled'
                }
            },
            @{
                Name            = 'WeakHostSend'
                MockedValue     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostSend]::Enabled
                TestValue       = 'Disabled'
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $WeakHostSend -eq 'Disabled'
                }
            },
            @{
                Name            = 'NlMtu'
                MockedValue     = [System.Uint32] 1600
                TestValue       = [System.Uint32] 1500
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $NlMtuBytes -eq 1500
                }
            },
            @{
                Name            = 'InterfaceMetric'
                MockedValue     = [System.Uint32] 20
                TestValue       = [System.Uint32] 15
                ParameterFilter = {
                    $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4' -and $InterfaceMetric -eq 15
                }
            }
        )
    }

    Context 'When called with alias and address family of an existing interface and a mismatching value' {
        BeforeAll {
            Mock -CommandName Get-NetworkIPInterface -ParameterFilter {
                $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4'
            } -MockWith {
                @{
                    InterfaceAlias                  = 'Ethernet'
                    AddressFamily                   = 'IPv4'
                    AdvertiseDefaultRoute           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AdvertiseDefaultRoute]::Enabled
                    Advertising                     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Advertising]::Enabled
                    AutomaticMetric                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AutomaticMetric]::Enabled
                    Dhcp                            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Dhcp]::Enabled
                    DirectedMacWolPattern           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.DirectedMacWolPattern]::Enabled
                    EcnMarking                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.EcnMarking]::AppDecide
                    ForceArpNdWolPattern            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ForceArpNdWolPattern]::Enabled
                    Forwarding                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Forwarding]::Enabled
                    IgnoreDefaultRoutes             = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.IgnoreDefaultRoutes]::Enabled
                    ManagedAddressConfiguration     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ManagedAddressConfiguration]::Enabled
                    NeighborUnreachabilityDetection = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.NeighborUnreachabilityDetection]::Enabled
                    OtherStatefulConfiguration      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.OtherStatefulConfiguration]::Enabled
                    RouterDiscovery                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.RouterDiscovery]::Enabled
                    WeakHostReceive                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostReceive]::Enabled
                    WeakHostSend                    = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostSend]::Enabled
                    NlMtu                           = [System.Uint32] 1600
                    InterfaceMetric                 = [System.Uint32] 20
                }
            }

            Mock -CommandName Set-NetIPInterface
        }

        It 'Should set parameter <Name> to <TestValue>' -ForEach $testParameterList {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $netIPInterfaceExists = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $comparisonParameter = @{
                    $Name = $TestValue
                }

                Set-TargetResource @netIPInterfaceExists @comparisonParameter
            }

            Should -Invoke -CommandName Set-NetIPInterface -ParameterFilter $ParameterFilter -Exactly -Times 1 -Scope It
        }
    }

    Context 'When called with alias and address family of an existing interface and no mismatching values' {
        BeforeAll {
            Mock -CommandName Get-NetworkIPInterface -ParameterFilter {
                $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4'
            } -MockWith {
                @{
                    InterfaceAlias                  = 'Ethernet'
                    AddressFamily                   = 'IPv4'
                    AdvertiseDefaultRoute           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AdvertiseDefaultRoute]::Enabled
                    Advertising                     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Advertising]::Enabled
                    AutomaticMetric                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AutomaticMetric]::Enabled
                    Dhcp                            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Dhcp]::Enabled
                    DirectedMacWolPattern           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.DirectedMacWolPattern]::Enabled
                    EcnMarking                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.EcnMarking]::AppDecide
                    ForceArpNdWolPattern            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ForceArpNdWolPattern]::Enabled
                    Forwarding                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Forwarding]::Enabled
                    IgnoreDefaultRoutes             = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.IgnoreDefaultRoutes]::Enabled
                    ManagedAddressConfiguration     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ManagedAddressConfiguration]::Enabled
                    NeighborUnreachabilityDetection = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.NeighborUnreachabilityDetection]::Enabled
                    OtherStatefulConfiguration      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.OtherStatefulConfiguration]::Enabled
                    RouterDiscovery                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.RouterDiscovery]::Enabled
                    WeakHostReceive                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostReceive]::Enabled
                    WeakHostSend                    = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostSend]::Enabled
                    NlMtu                           = [System.Uint32] 1600
                    InterfaceMetric                 = [System.Uint32] 20
                }
            }

            Mock -CommandName Set-NetIPInterface
        }

        It 'Should not call Set-NetIPInterface' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $comparisonParameter = @{
                    AdvertiseDefaultRoute = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AdvertiseDefaultRoute]::Enabled
                }

                $netIPInterfaceExists = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                Set-TargetResource @netIPInterfaceExists @comparisonParameter
            }

            Should -Invoke -CommandName Set-NetIPInterface -ParameterFilter $ParameterFilter -Exactly -Times 0 -Scope It
        }
    }
}

Describe 'DSC_NetIPInterface\Get-NetworkIPInterface' {
    Context 'When called with alias and address family of an interface that does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetIPInterface -ParameterFilter {
                $InterfaceAlias -eq 'EthernetDoesNotExist' -and $AddressFamily -eq 'IPv4'
            }
        }

        It 'Should throw expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $netIPInterfaceMissing = @{
                    InterfaceAlias = 'EthernetDoesNotExist'
                    AddressFamily  = 'IPv4'
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetworkIPInterfaceDoesNotExistMessage -f $netIPInterfaceMissing.InterfaceAlias, $netIPInterfaceMissing.AddressFamily)

                { Get-NetworkIPInterface @netIPInterfaceMissing } | Should -Throw $errorRecord
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetIPInterface -ParameterFilter {
                $InterfaceAlias -eq 'EthernetDoesNotExist' -and $AddressFamily -eq 'IPv4'
            } -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When called with alias and address family of an existing interface' {
        BeforeAll {
            Mock -CommandName Get-NetIPInterface -ParameterFilter {
                $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4'
            } -MockWith {
                @{
                    InterfaceAlias                  = 'Ethernet'
                    AddressFamily                   = 'IPv4'
                    AdvertiseDefaultRoute           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AdvertiseDefaultRoute]::Enabled
                    Advertising                     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Advertising]::Enabled
                    AutomaticMetric                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.AutomaticMetric]::Enabled
                    Dhcp                            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Dhcp]::Enabled
                    DirectedMacWolPattern           = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.DirectedMacWolPattern]::Enabled
                    EcnMarking                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.EcnMarking]::AppDecide
                    ForceArpNdWolPattern            = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ForceArpNdWolPattern]::Enabled
                    Forwarding                      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.Forwarding]::Enabled
                    IgnoreDefaultRoutes             = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.IgnoreDefaultRoutes]::Enabled
                    ManagedAddressConfiguration     = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.ManagedAddressConfiguration]::Enabled
                    NeighborUnreachabilityDetection = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.NeighborUnreachabilityDetection]::Enabled
                    OtherStatefulConfiguration      = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.OtherStatefulConfiguration]::Enabled
                    RouterDiscovery                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.RouterDiscovery]::Enabled
                    WeakHostReceive                 = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostReceive]::Enabled
                    WeakHostSend                    = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetIPInterface.WeakHostSend]::Enabled
                    NlMtu                           = [System.Uint32] 1600
                    InterfaceMetric                 = [System.Uint32] 20
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $netIPInterfaceExists = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                { Get-NetworkIPInterface @netIPInterfaceExists } | Should -Not -Throw
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetIPInterface -ParameterFilter {
                $InterfaceAlias -eq 'Ethernet' -and $AddressFamily -eq 'IPv4'
            } -Exactly -Times 1 -Scope Context
        }
    }
}
