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
    $script:dscResourceName = 'DSC_NetBios'

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

# $script:networkAdapterACimInstance = New-Object `
#     -TypeName CimInstance `
#     -ArgumentList 'Win32_NetworkAdapter' |
#     Add-Member `
#         -MemberType NoteProperty `
#         -Name Name `
#         -Value 'Test Adapter A' `
#         -PassThru |
#     Add-Member `
#         -MemberType NoteProperty `
#         -Name NetConnectionID `
#         -Value 'Test Adapter A' `
#         -PassThru |
#     Add-Member `
#         -MemberType NoteProperty `
#         -Name 'GUID' `
#         -Value '{00000000-0000-0000-0000-000000000001}' `
#         -PassThru |
#     Add-Member `
#         -MemberType NoteProperty `
#         -Name InterfaceIndex `
#         -Value 1 `
#         -PassThru

# $script:networkAdapterBCimInstance = New-Object `
#     -TypeName CimInstance `
#     -ArgumentList 'Win32_NetworkAdapter' |
#     Add-Member `
#         -MemberType NoteProperty `
#         -Name Name `
#         -Value 'Test Adapter B' `
#         -PassThru |
#     Add-Member `
#         -MemberType NoteProperty `
#         -Name NetConnectionID `
#         -Value 'Test Adapter B' `
#         -PassThru |
#     Add-Member `
#         -MemberType NoteProperty `
#         -Name 'GUID' `
#         -Value '{00000000-0000-0000-0000-000000000002}' `
#         -PassThru |
#     Add-Member `
#         -MemberType NoteProperty `
#         -Name InterfaceIndex `
#         -Value 2 `
#         -PassThru

# $script:mockNetadapterA = {
#     New-Object `
#         -TypeName CimInstance `
#         -ArgumentList 'Win32_NetworkAdapter' |
#         Add-Member `
#             -MemberType NoteProperty `
#             -Name Name `
#             -Value 'Test Adapter A' `
#             -PassThru |
#         Add-Member `
#             -MemberType NoteProperty `
#             -Name NetConnectionID `
#             -Value 'Test Adapter A' `
#             -PassThru |
#         Add-Member `
#             -MemberType NoteProperty `
#             -Name 'GUID' `
#             -Value '{00000000-0000-0000-0000-000000000001}' `
#             -PassThru |
#         Add-Member `
#             -MemberType NoteProperty `
#             -Name InterfaceIndex `
#             -Value 1 `
#             -PassThru
# }

# $script:mockNetadapterB = {
#     New-Object `
#         -TypeName CimInstance `
#         -ArgumentList 'Win32_NetworkAdapter' |
#         Add-Member `
#             -MemberType NoteProperty `
#             -Name Name `
#             -Value 'Test Adapter B' `
#             -PassThru |
#         Add-Member `
#             -MemberType NoteProperty `
#             -Name NetConnectionID `
#             -Value 'Test Adapter B' `
#             -PassThru |
#         Add-Member `
#             -MemberType NoteProperty `
#             -Name 'GUID' `
#             -Value '{00000000-0000-0000-0000-000000000002}' `
#             -PassThru |
#         Add-Member `
#             -MemberType NoteProperty `
#             -Name InterfaceIndex `
#             -Value 2 `
#             -PassThru
# }

# $script:mockNetadapterMulti = {
#     @(
#         $script:networkAdapterACimInstance,
#         $script:networkAdapterBCimInstance
#     )
# }


# $script:testCases = @(
#     @{
#         Setting    = 'Default'
#         SettingInt = 0
#         NotSetting = 'Enable'
#     },
#     @{
#         Setting    = 'Enable'
#         SettingInt = 1
#         NotSetting = 'Disable'
#     },
#     @{
#         Setting    = 'Disable'
#         SettingInt = 2
#         NotSetting = 'Default'
#     }
# )

Describe 'DSC_NetBios\Get-TargetResource' -Tag 'Get' {
    Context 'When specifying a single network adapter' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    Setting    = 'Default'
                    SettingInt = 0
                    NotSetting = 'Enable'
                },
                @{
                    Setting    = 'Enable'
                    SettingInt = 1
                    NotSetting = 'Disable'
                },
                @{
                    Setting    = 'Disable'
                    SettingInt = 2
                    NotSetting = 'Default'
                }
            )
        }

        Context 'When NetBios over TCP/IP is set to <Setting>' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                    return 'NetConnectionID="Test Adapter A"'
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                        Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                        Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                        Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    $Setting
                }
            }

            It 'Should not throw exception' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getParams = @{
                        InterfaceAlias = 'Test Adapter A'
                        Setting        = $Setting
                    }

                    $script:result = Get-TargetResource @getParams

                    { $script:result } | Should -Not -Throw
                }
            }

            It 'Returns a hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:result | Should -BeOfType [System.Collections.Hashtable]
                }
            }

            It 'Setting should return <Setting>' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:result.Setting | Should -Be $Setting
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_NetworkAdapter' -and
                    $Filter -eq 'NetConnectionID="Test Adapter A"'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When specifying a wildcard network adapter' {
            Context "When both NetBios over TCP/IP is set to 'Default' on both and Setting is 'Default'" {
                BeforeAll {
                    Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                        return 'NetConnectionID LIKE "%"'
                    }

                    Mock -CommandName Get-CimInstance -MockWith {
                        @(
                            (
                                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                    Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                            ),
                            (
                                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                    Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter B' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter B' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000002}' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru
                            )
                        )
                    }

                    Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                        return 'Default'
                    } -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                        $Setting -eq 'Default'
                    }

                    Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                        return 'Default'
                    } -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                        $Setting -eq 'Default'
                    }
                }

                It 'Should not throw exception' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $getParams = @{
                            InterfaceAlias = '*'
                            Setting        = 'Default'
                        }

                        $script:result = Get-TargetResource @getParams

                        { $script:result } | Should -Not -Throw
                    }
                }

                It 'Returns a hashtable' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:result | Should -BeOfType [System.Collections.Hashtable]
                    }
                }

                It "Setting should return 'Default'" {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:result.Setting | Should -Be 'Default'
                    }
                }

                It 'Should call expected mocks' {
                    Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_NetworkAdapter' -and
                        $Filter -eq 'NetConnectionID LIKE "%"'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                        $Setting -eq 'Default'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                        $Setting -eq 'Default'
                    } -Exactly -Times 1 -Scope Context
                }
            }

            Context "When both NetBios over TCP/IP is set to 'Enable' on both and Setting is 'Default'" {
                BeforeAll {
                    Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                        return 'NetConnectionID LIKE "%"'
                    }

                    Mock -CommandName Get-CimInstance -MockWith {
                        @(
                            (
                                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                    Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                            ),
                            (
                                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                    Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter B' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter B' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000002}' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru
                            )
                        )
                    }

                    Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                        return 'Enable'
                    } -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                        $Setting -eq 'Default'
                    }

                    Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                        return 'Enable'
                    } -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                        $Setting -eq 'Default'
                    }
                }

                It 'Should not throw exception' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $getParams = @{
                            InterfaceAlias = '*'
                            Setting        = 'Default'
                        }

                        $script:result = Get-TargetResource @getParams

                        { $script:result } | Should -Not -Throw
                    }
                }

                It 'Returns a hashtable' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:result | Should -BeOfType [System.Collections.Hashtable]
                    }
                }

                It "Setting should return 'Enable'" {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:result.Setting | Should -Be 'Enable'
                    }
                }

                It 'Should call expected mocks' {
                    Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_NetworkAdapter' -and
                        $Filter -eq 'NetConnectionID LIKE "%"'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                        $Setting -eq 'Default'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                        $Setting -eq 'Default'
                    } -Exactly -Times 1 -Scope Context
                }
            }

            Context "When NetBios over TCP/IP is set to 'Enable' on the first, 'Disable' on the second and Setting is 'Default'" {
                BeforeAll {
                    Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                        return 'NetConnectionID LIKE "%"'
                    }

                    Mock -CommandName Get-CimInstance -MockWith {
                        @(
                            (
                                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                    Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                            ),
                            (
                                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                    Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter B' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter B' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000002}' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru
                            )
                        )
                    }

                    Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                        return 'Enable'
                    } -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                        $Setting -eq 'Default'
                    }

                    Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                        return 'Disable'
                    } -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                        $Setting -eq 'Default'
                    }
                }

                It 'Should not throw exception' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $getParams = @{
                            InterfaceAlias = '*'
                            Setting        = 'Default'
                        }

                        $script:result = Get-TargetResource @getParams

                        { $script:result } | Should -Not -Throw
                    }
                }

                It 'Should return a hashtable' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:result | Should -BeOfType [System.Collections.Hashtable]
                    }
                }

                It "Setting should return 'Enable'" {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:result.Setting | Should -Be 'Enable'
                    }
                }

                It 'Should call expected mocks' {
                    Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_NetworkAdapter' -and
                        $Filter -eq 'NetConnectionID LIKE "%"'
                    } -Exactly -Times 1  -Scope Context

                    Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                        $Setting -eq 'Default'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                        $Setting -eq 'Default'
                    } -Exactly -Times 1 -Scope Context
                }
            }

            Context "When NetBios over TCP/IP is set to 'Default' on the first, 'Disable' on the second and Setting is 'Default'" {
                BeforeAll {
                    Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                        return 'NetConnectionID LIKE "%"'
                    }

                    Mock -CommandName Get-CimInstance -MockWith {
                        @(
                            (
                                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                    Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                            ),
                            (
                                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                    Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter B' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter B' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000002}' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru
                            )
                        )
                    }

                    Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                        return 'Default'
                    } -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                        $Setting -eq 'Default'
                    }

                    Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                        return 'Disable'
                    } -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                        $Setting -eq 'Default'
                    }
                }

                It 'Should not throw exception' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $getParams = @{
                            InterfaceAlias = '*'
                            Setting        = 'Default'
                        }

                        $script:result = Get-TargetResource @getParams

                        { $script:result } | Should -Not -Throw
                    }
                }

                It 'Should return a hashtable' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:result | Should -BeOfType [System.Collections.Hashtable]
                    }
                }

                It "Setting should return 'Disable'" {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:result.Setting | Should -Be 'Disable'
                    }
                }

                It 'Should call expected mocks' {
                    Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_NetworkAdapter' -and
                        $Filter -eq 'NetConnectionID LIKE "%"'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                        $Setting -eq 'Default'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -ParameterFilter {
                        $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                        $Setting -eq 'Default'
                    } -Exactly -Times 1 -Scope Context
                }
            }
        }

        Context 'When interface does not exist' {
            BeforeAll {
                Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                    return 'NetConnectionID="Test Adapter A"'
                }

                Mock -CommandName Get-CimInstance
            }

            It 'Should throw expected exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.InterfaceNotFoundError -f 'Test Adapter A')

                    $getParams = @{
                        InterfaceAlias = 'Test Adapter A'
                        Setting        = 'Default'
                    }

                    { Get-TargetResource @getParams } | Should -Throw $errorRecord
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_NetworkAdapter' -and
                    $Filter -eq 'NetConnectionID="Test Adapter A"'
                } -Exactly -Times 1 -Scope Context
            }
        }
    }
}

Describe 'DSC_NetBios\Test-TargetResource' -Tag 'Test' {
    Context 'When specifying a single network adapter' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    Setting    = 'Default'
                    SettingInt = 0
                    NotSetting = 'Enable'
                },
                @{
                    Setting    = 'Enable'
                    SettingInt = 1
                    NotSetting = 'Disable'
                },
                @{
                    Setting    = 'Disable'
                    SettingInt = 2
                    NotSetting = 'Default'
                }
            )
        }

        Context 'When NetBios over TCP/IP is set to <Setting>' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InterfaceAlias = 'Test Adapter A'
                        Setting        = $Setting
                    }
                }
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    Mock -CommandName Test-DscParameterState -MockWith {
                        return $true
                    }
                }

                It 'Should return true when value ''<Setting>'' is set' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            InterfaceAlias = 'Test Adapter A'
                            Setting        = $Setting
                        }

                        Test-TargetResource @testParams | Should -BeTrue
                    }
                }

                It 'Should call expected mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                    Should -Invoke -CommandName Test-DscParameterState -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName Test-DscParameterState -MockWith {
                        return $false
                    }
                }

                It 'Should return false when value ''<NotSetting>'' is set' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            InterfaceAlias = 'Test Adapter A'
                            Setting        = $NotSetting
                        }

                        Test-TargetResource @testParams | Should -BeFalse
                    }
                }

                It 'Should call expected mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                    Should -Invoke -CommandName Test-DscParameterState -Exactly -Times 1 -Scope Context
                }
            }
        }

        Context 'When specifying a wildcard network adapter' {
            Context "When NetBios set to 'Default' on both and Setting is 'Default'" {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InterfaceAlias = '*'
                            Setting        = 'Default'
                        }
                    }

                    Mock -CommandName Test-DscParameterState -MockWith {
                        return $true
                    }
                }

                It 'Should return true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        Test-TargetResource -InterfaceAlias '*' -Setting 'Default' | Should -BeTrue
                    }
                }

                It 'Should call expected mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                    Should -Invoke -CommandName Test-DscParameterState -Exactly -Times 1 -Scope Context
                }
            }

            Context "When NetBios set to 'Default' on both and Setting is 'Enable'" {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InterfaceAlias = '*'
                            Setting        = 'Enable'
                        }
                    }

                    Mock -CommandName Test-DscParameterState -MockWith {
                        return $false
                    }
                }

                It 'Should return false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        Test-TargetResource -InterfaceAlias '*' -Setting 'Default' | Should -BeFalse
                    }
                }

                It 'Should call expected mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                    Should -Invoke -CommandName Test-DscParameterState -Exactly -Times 1 -Scope Context
                }
            }

            Context "When NetBios set to 'Default' on first and 'Enable' on second and Setting is 'Enable'" {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InterfaceAlias = '*'
                            Setting        = 'Enable'
                        }
                    }

                    Mock -CommandName Test-DscParameterState -MockWith {
                        return $false
                    }
                }

                It 'Should return false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        Test-TargetResource -InterfaceAlias '*' -Setting 'Default' | Should -BeFalse
                    }
                }

                It 'Should call expected mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                    Should -Invoke -CommandName Test-DscParameterState -Exactly -Times 1 -Scope Context
                }
            }
        }

        Context 'When interface does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return New-InvalidOperationException -Message ('Interface ''{0}'' was not found.' -f 'Test Adapter A')
                }
            }

            It 'Should throw expected exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.InterfaceNotFoundError -f 'Test Adapter A')

                    $testParams = @{
                        InterfaceAlias = 'Test Adapter A'
                        Setting        = 'Enable'
                    }

                    { Test-TargetResource @testParams } | Should -Throw $errorRecord
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }
    }
}

Describe 'DSC_NetBios\Set-TargetResource' -Tag 'Set' {
    BeforeDiscovery {
        $testCases = @(
            @{
                Setting    = 'Default'
                SettingInt = 0
                NotSetting = 'Enable'
            },
            @{
                Setting    = 'Enable'
                SettingInt = 1
                NotSetting = 'Disable'
            },
            @{
                Setting    = 'Disable'
                SettingInt = 2
                NotSetting = 'Default'
            }
        )
    }

    Context 'When specifying a single network adapter' {
        Context 'When NetBios over TCP/IP should be set to ''<Setting>'' and IPEnabled=True' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                    'NetConnectionID="Test Adapter A"'
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                        Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                        Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                        Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $true -PassThru
                }

                Mock -CommandName Set-NetAdapterNetbiosOptions
            }

            It 'Should not throw exception' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setParams = @{
                        InterfaceAlias = 'Test Adapter A'
                        Setting        = $Setting
                    }

                    { Set-TargetResource @setParams } | Should -Not -Throw
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_NetworkAdapter' -and
                    $Filter -eq 'NetConnectionID="Test Adapter A"'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-CimAssociatedInstance -ParameterFilter {
                    $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and
                    $InputObject.Name -eq 'Test Adapter A'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Set-NetAdapterNetbiosOptions -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When NetBios over TCP/IP should be set to ''<Setting>'' and IPEnabled=False' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                    'NetConnectionID="Test Adapter A"'
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                        Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                        Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                        Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $false -PassThru |
                        Add-Member -MemberType NoteProperty -Name SettingID -Value '{00000000-0000-0000-0000-000000000001}' -PassThru
                }

                Mock -CommandName Set-NetAdapterNetbiosOptions
            }

            It 'Should not throw exception' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setParams = @{
                        InterfaceAlias = 'Test Adapter A'
                        Setting        = $Setting
                    }

                    { Set-TargetResource @setParams } | Should -Not -Throw
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_NetworkAdapter' -and
                    $Filter -eq 'NetConnectionID="Test Adapter A"'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-CimAssociatedInstance -ParameterFilter {
                    $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and
                    $InputObject.Name -eq 'Test Adapter A'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Set-NetAdapterNetbiosOptions -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'When specifying a wildcard network adapter' {
        Context "When all Interfaces are IPEnabled and NetBios set to 'Default' on both and Setting is 'Disable'" {
            BeforeAll {
                Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                    return 'NetConnectionID LIKE "%"'
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    @(
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                        ),
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000002}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru
                        )
                    )
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Default'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Default'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $true -PassThru
                }

                Mock -CommandName Set-NetAdapterNetbiosOptions
            }

            It 'Should not throw exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setParams = @{
                        InterfaceAlias = '*'
                        Setting        = 'Disable'
                    }

                    { Set-TargetResource @setParams } | Should -Not -Throw
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_NetworkAdapter' -and
                    $Filter -eq 'NetConnectionID LIKE "%"'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                    $Setting -eq 'Disable'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                    $Setting -eq 'Disable'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-CimAssociatedInstance -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Set-NetAdapterNetbiosOptions -Exactly -Times 2 -Scope Context
            }
        }

        Context "When all Interfaces are NOT IPEnabled and NetBios set to 'Default' on both and Setting is 'Disable'" {
            BeforeAll {
                Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                    return 'NetConnectionID LIKE "%"'
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    @(
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                        ),
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000002}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru
                        )
                    )
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Default'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Default'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $false -PassThru |
                        Add-Member -MemberType NoteProperty -Name SettingID -Value '{00000000-0000-0000-0000-000000000001}' -PassThru
                }

                Mock -CommandName Set-NetAdapterNetbiosOptions
            }

            It 'Should not throw exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setParams = @{
                        InterfaceAlias = '*'
                        Setting        = 'Disable'
                    }

                    { Set-TargetResource @setParams } | Should -Not -Throw
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_NetworkAdapter' -and
                    $Filter -eq 'NetConnectionID LIKE "%"'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Get-CimAssociatedInstance -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Set-NetAdapterNetbiosOptions -Exactly -Times 2 -Scope Context
            }
        }

        Context "When first Interface is IPEnabled and NetBios set to 'Default' on both and Setting is 'Disable'" {
            BeforeAll {
                Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                    return 'NetConnectionID LIKE "%"'
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    @(
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                        ),
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000002}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru
                        )
                    )
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Default'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Default'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $true -PassThru
                } -ParameterFilter {
                    $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and
                    $InputObject.Name -eq 'Test Adapter A'
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $false -PassThru |
                        Add-Member -MemberType NoteProperty -Name SettingID -Value '{00000000-0000-0000-0000-000000000001}' -PassThru
                } -ParameterFilter {
                    $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and
                    $InputObject.Name -eq 'Test Adapter B'
                }

                Mock -CommandName Set-NetAdapterNetbiosOptions
            }

            It 'Should not throw exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setParams = @{
                        InterfaceAlias = '*'
                        Setting        = 'Disable'
                    }

                    { Set-TargetResource @setParams } | Should -Not -Throw
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_NetworkAdapter' -and
                    $Filter -eq 'NetConnectionID LIKE "%"'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Get-CimAssociatedInstance -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Set-NetAdapterNetbiosOptions -Exactly -Times 2 -Scope Context
            }
        }

        Context "When second Interface is IPEnabled and NetBios set to 'Default' on both and Setting is 'Disable'" {
            BeforeAll {
                Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                    return 'NetConnectionID LIKE "%"'
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    @(
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                        ),
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000002}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru
                        )
                    )
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Default'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Default'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $false -PassThru |
                        Add-Member -MemberType NoteProperty -Name SettingID -Value '{00000000-0000-0000-0000-000000000001}' -PassThru
                } -ParameterFilter {
                    $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and
                    $InputObject.Name -eq 'Test Adapter A'
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $true -PassThru
                } -ParameterFilter {
                    $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and
                    $InputObject.Name -eq 'Test Adapter B'
                }

                Mock -CommandName Set-NetAdapterNetbiosOptions
            }

            It 'Should not throw exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setParams = @{
                        InterfaceAlias = '*'
                        Setting        = 'Disable'
                    }

                    { Set-TargetResource @setParams } | Should -Not -Throw
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_NetworkAdapter' -and
                    $Filter -eq 'NetConnectionID LIKE "%"'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Get-CimAssociatedInstance -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Set-NetAdapterNetbiosOptions -Exactly -Times 2 -Scope Context
            }
        }

        Context "When first Interface is IPEnabled and NetBios set to 'Default' second Interface Netbios set to 'Disable' and Setting is 'Disable'" {
            BeforeAll {
                Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                    return 'NetConnectionID LIKE "%"'
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    @(
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                        ),
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000002}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru
                        )
                    )
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Default'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Disable'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $true -PassThru
                } -ParameterFilter {
                    $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and
                    $InputObject.Name -eq 'Test Adapter A'
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $false -PassThru |
                        Add-Member -MemberType NoteProperty -Name SettingID -Value '{00000000-0000-0000-0000-000000000001}' -PassThru
                } -ParameterFilter {
                    $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and
                    $InputObject.Name -eq 'Test Adapter B'
                }

                Mock -CommandName Set-NetAdapterNetbiosOptions
            }

            It 'Should not throw exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setParams = @{
                        InterfaceAlias = '*'
                        Setting        = 'Disable'
                    }

                    { Set-TargetResource @setParams } | Should -Not -Throw
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_NetworkAdapter' -and
                    $Filter -eq 'NetConnectionID LIKE "%"'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Get-CimAssociatedInstance -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Set-NetAdapterNetbiosOptions -Exactly -Times 1 -Scope Context
            }
        }

        Context "When first Interface is IPEnabled and NetBios set to 'Disable' second Interface Netbios set to 'Default' and Setting is 'Disable'" {
            BeforeAll {
                Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                    return 'NetConnectionID LIKE "%"'
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    @(
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
                        ),
                        (
                            New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                                Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter B' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000002}' -PassThru |
                                Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru
                        )
                    )
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Disable'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000001}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -MockWith {
                    return 'Default'
                } -ParameterFilter {
                    $NetworkAdapterGUID -eq '{00000000-0000-0000-0000-000000000002}' -and
                    $Setting -eq 'Disable'
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $true -PassThru
                } -ParameterFilter {
                    $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and
                    $InputObject.Name -eq 'Test Adapter A'
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                        Add-Member -MemberType NoteProperty -Name IPEnabled -Value $false -PassThru |
                        Add-Member -MemberType NoteProperty -Name SettingID -Value '{00000000-0000-0000-0000-000000000001}' -PassThru
                } -ParameterFilter {
                    $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and
                    $InputObject.Name -eq 'Test Adapter B'
                }

                Mock -CommandName Set-NetAdapterNetbiosOptions
            }

            It 'Should not throw exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setParams = @{
                        InterfaceAlias = '*'
                        Setting        = 'Disable'
                    }

                    { Set-TargetResource @setParams } | Should -Not -Throw
                }
            }

            It 'Should call expected mocks' {
                Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_NetworkAdapter' -and
                    $Filter -eq 'NetConnectionID LIKE "%"'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-NetAdapterNetbiosOptionsFromRegistry -Exactly -Times 2 -Scope Context
                Should -Invoke -CommandName Get-CimAssociatedInstance -Exactly -Times 1 -Scope Context
                Should -Invoke -CommandName Set-NetAdapterNetbiosOptions -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'When interface does not exist' {
        BeforeAll {
            Mock -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -MockWith {
                'NetConnectionID="Test Adapter A"'
            }

            Mock -CommandName Get-CimInstance
        }

        It 'Should throw expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.InterfaceNotFoundError -f 'Test Adapter A'
                )

                $setParams = @{
                    InterfaceAlias = 'Test Adapter A'
                    Setting        = 'Enable'
                }

                { Set-TargetResource @setParams } | Should -Throw $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Format-Win32NetworkAdapterFilterByNetConnectionId -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetBios\Get-NetAdapterNetbiosOptionsFromRegistry' {
    BeforeDiscovery {
        $testCases = @(
            @{
                Setting    = 'Default'
                SettingInt = 0
                NotSetting = 'Enable'
            },
            @{
                Setting    = 'Enable'
                SettingInt = 1
                NotSetting = 'Disable'
            },
            @{
                Setting    = 'Disable'
                SettingInt = 2
                NotSetting = 'Default'
            }
        )
    }

    Context 'When interface NetBios is <Setting>' -ForEach $testCases {
        BeforeAll {
            Mock -CommandName Get-ItemPropertyValue -MockWith {
                return $SettingInt
            } -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions'
            }
        }

        It 'Should return true when value <Setting> is set' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getParams = @{
                    NetworkAdapterGUID = '{00000000-0000-0000-0000-000000000001}'
                    Setting            = $Setting
                }

                $result = Get-NetAdapterNetbiosOptionsFromRegistry @getParams

                $result | Should -Be $Setting
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions'
            } -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When interface Netbios setting missing from registry' {
        BeforeAll {
            Mock -CommandName Get-ItemPropertyValue -MockWith {
                return $null
            } -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions'
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getParams = @{
                    NetworkAdapterGUID = '{00000000-0000-0000-0000-000000000001}'
                    Setting            = 'Enable'
                }

                $result = Get-NetAdapterNetbiosOptionsFromRegistry @getParams

                $result | Should -Be 'Default'
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions'
            } -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When Netbios registry setting invalid number' {
        BeforeAll {
            Mock -CommandName Get-ItemPropertyValue -MockWith {
                return 5
            } -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions'
            }
        }

        It 'Should evaluate true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getParams = @{
                    NetworkAdapterGUID = '{00000000-0000-0000-0000-000000000001}'
                    Setting            = 'Enable'
                }

                $result = Get-NetAdapterNetbiosOptionsFromRegistry @getParams

                $result  | Should -Be 'Default'
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions'
            } -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When Netbios registry setting invalid letters' {
        BeforeAll {
            Mock -CommandName Get-ItemPropertyValue -MockWith {
                return 'invalid'
            } -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions'
            }
        }

        It 'Should evaluate true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getParams = @{
                    NetworkAdapterGUID = '{00000000-0000-0000-0000-000000000001}'
                    Setting            = 'Enable'
                }

                $result = Get-NetAdapterNetbiosOptionsFromRegistry @getParams

                $result  | Should -Be 'Default'
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions'
            } -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_NetBios\Set-NetAdapterNetbiosOptions' {
    Context "When NetBios over TCP/IP should be set to 'Default' and IPEnabled=True" {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                    Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                    Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
            }

            Mock -CommandName Get-CimAssociatedInstance -MockWith {
                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                    Add-Member -MemberType NoteProperty -Name IPEnabled -Value $true -PassThru
            }

            Mock -CommandName Set-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions' -and
                $Value -eq 0
            }

            Mock -CommandName Invoke-CimMethod -MockWith {
                @{
                    ReturnValue = 0
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $netAdapter = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter 'NetConnectionID="Test Adapter A"'
                $netAdapterConfig = $netAdapter | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration -ErrorAction Stop

                $setParams = @{
                    NetworkAdapterObject = $netAdapterConfig
                    InterfaceAlias       = 'Test Adapter A'
                    Setting              = 'Default'
                }

                { Set-NetAdapterNetbiosOptions @setParams } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions' -and
                $Value -eq 0
            } -Exactly -Times 0 -Scope Context

            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-CimAssociatedInstance -Exactly -Times 1 -Scope Context
        }
    }

    Context "When NetBios over TCP/IP should be set to 'Default' and IPEnabled=False" {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapter' |
                    Add-Member -MemberType NoteProperty -Name Name -Value 'Test Adapter A' -PassThru |
                    Add-Member -MemberType NoteProperty -Name NetConnectionID -Value 'Test Adapter A' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'GUID' -Value '{00000000-0000-0000-0000-000000000001}' -PassThru |
                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru
            }

            Mock -CommandName Get-CimAssociatedInstance -MockWith {
                New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                    Add-Member -MemberType NoteProperty -Name IPEnabled -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name SettingID -Value '{00000000-0000-0000-0000-000000000001}' -PassThru
            }

            Mock -CommandName Set-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions' -and
                $Value -eq 0
            }

            Mock -CommandName Invoke-CimMethod -MockWith {
                @{
                    ReturnValue = 0
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $netAdapter = Get-CimInstance `
                    -ClassName Win32_NetworkAdapter `
                    -Filter 'NetConnectionID="Test Adapter A"'

                $netAdapterConfig = $netAdapter | Get-CimAssociatedInstance `
                    -ResultClassName Win32_NetworkAdapterConfiguration `
                    -ErrorAction Stop

                $setParams = @{
                    NetworkAdapterObject = $netAdapterConfig
                    InterfaceAlias       = 'Test Adapter A'
                    Setting              = 'Default'
                }

                { Set-NetAdapterNetbiosOptions @setParams } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and
                $Name -eq 'NetbiosOptions' -and
                $Value -eq 0
            } -Exactly -Times 1 -Scope Context

            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-CimAssociatedInstance -Exactly -Times 1 -Scope Context
        }
    }
}
