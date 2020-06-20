$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetBios'

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
        $script:interfaceAliasA = 'Test Adapter A'
        $script:interfaceAliasB = 'Test Adapter B'

        $script:mockNetadapterA = {
            New-Object `
                -TypeName CimInstance `
                -ArgumentList 'Win32_NetworkAdapter' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name Name `
                    -Value $script:interfaceAliasA `
                    -PassThru
        }

        $script:mockNetadapterASettingsDefault = {
                New-Object `
                -TypeName CimInstance `
                -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name TcpipNetbiosOptions `
                    -Value 0 `
                    -PassThru
        }

        $script:mockNetadapterASettingsEnable = {
            New-Object `
                -TypeName CimInstance `
                -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name TcpipNetbiosOptions `
                    -Value 1 `
                    -PassThru
        }

        $script:mockNetadapterASettingsDisable = {
            New-Object `
                -TypeName CimInstance `
                -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name TcpipNetbiosOptions `
                    -Value 2 `
                    -PassThru
        }

        $script:getCimInstanceParameterFilter = {
            $ClassName -eq '-Win32_NetworkAdapter' -and `
            $Filter -eq 'NetConnectionID = "Test Adapter A"'
        }

        Describe 'DSC_NetBios\Get-TargetResource' -Tag 'Get' {
            Context 'When NetBios over TCP/IP is set to "Default"' {
                Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterASettingsDefault

                It 'Should not throw exception' {
                    {
                        $script:result = Get-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Default' -Verbose
                    } | Should -Not -Throw
                }

                It 'Returns a hashtable' {
                    $script:result -is [System.Collections.Hashtable] | Should -Be $true
                }

                It 'Setting should return "Default"' {
                    $script:result.Setting | Should -Be 'Default'
                }
            }

            Context 'When NetBios over TCP/IP is set to "Enable"' {
                Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterASettingsEnable

                It 'Should not throw exception' {
                    {
                        $script:result = Get-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Default' -Verbose
                    } | Should -Not -Throw
                }

                It 'Returns a hashtable' {
                    $script:result -is [System.Collections.Hashtable] | Should -Be $true
                }

                It 'Setting should return "Enable"' {
                    $script:result.Setting | Should -Be 'Enable'
                }
            }

            Context 'When NetBios over TCP/IP is set to "Disable"' {
                Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterASettingsDisable

                It 'Should not throw exception' {
                    {
                        $script:result = Get-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Default' -Verbose
                    } | Should -Not -Throw
                }

                It 'Returns a hashtable' {
                    $script:result -is [System.Collections.Hashtable] | Should -Be $true
                }

                It 'Setting should return "Disable"' {
                    $script:result.Setting | Should -Be 'Disable'
                }
            }

            Context 'When interface does not exist' {
                Mock -CommandName Get-CimInstance
                Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterASettingsDisable

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.InterfaceNotFoundError -f $script:interfaceAliasA)

                It 'Should throw expected exception' {
                    {
                        $script:result = Get-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Default' -Verbose
                    } | Should -Throw $errorRecord
                }
            }
        }

        Describe 'DSC_NetBios\Test-TargetResource' -Tag 'Test' {
            Context 'When NetBios over TCP/IP is set to "Default"' {
                Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterASettingsDefault

                It 'Should return true when value "Default" is set' {
                    Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Default' -Verbose | Should -Be $true
                }

                It 'Should return false when value "Disable" is set' {
                    Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Disable' -Verbose | Should -Be $false
                }
            }

            Context 'When NetBios over TCP/IP is set to "Disable"' {
                Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterASettingsDisable

                It 'Should return true when value "Disable" is set' {
                    Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Disable' -Verbose | Should -Be $true
                }

                It 'Should return false when value "Enable" is set' {
                    Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Enable' -Verbose | Should -Be $false
                }
            }

            Context 'When NetBios over TCP/IP is set to "Enable"' {
                Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterASettingsEnable

                It 'Should return true when value "Enable" is set' {
                    Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Enable' -Verbose | Should -Be $true
                }

                It 'Should return false when value "Disable" is set' {
                    Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Disable' -Verbose | Should -Be $false
                }
            }

            Context 'When interface does not exist' {
                Mock -CommandName Get-CimInstance -MockWith { }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.InterfaceNotFoundError -f $script:interfaceAliasA)

                It 'Should throw expected exception' {
                    {
                        Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Enable' -Verbose
                    } | Should -Throw $errorRecord
                }
            }
        }

        Describe 'DSC_NetBios\Set-TargetResource' -Tag 'Set' {
            Context 'When NetBios over TCP/IP should be set to "Default"' {
                Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterASettingsEnable
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Invoke-CimMethod -MockWith {
                    @{
                        ReturnValue = 0
                    }
                }

                It 'Should not throw exception' {
                    {
                        Set-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Default' -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call "Set-ItemProperty" instead of "Invoke-CimMethod"' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
                    Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 0
                }
            }

            Context 'When NetBios over TCP/IP should be set to "Disable"' {
                Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterASettingsEnable
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Invoke-CimMethod -MockWith { @{
                    ReturnValue = 0
                } }

                It 'Should not throw exception' {
                    {
                        Set-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Disable' -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call "Invoke-CimMethod" instead of "Set-ItemProperty"' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 1
                }
            }

            Context 'When NetBios over TCP/IP should be set to "Enable"' {
                Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterASettingsDisable
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Invoke-CimMethod -MockWith {
                    @{
                        ReturnValue = 0
                    }
                }

                It 'Should not throw exception' {
                    {
                        Set-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Enable' -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call "Invoke-CimMethod" instead of "Set-ItemProperty"' {

                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 1
                }
            }

            Context 'When NetBios over TCP/IP should be set to "Enable" but error returned from "Invoke-CimMethod"' {
                Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterASettingsDisable
                Mock -CommandName Invoke-CimMethod -MockWith {
                    @{
                        ReturnValue = 74
                    }
                }
                Mock -CommandName Set-ItemProperty

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.FailedUpdatingNetBiosError -f $script:interfaceAliasA, 74, 'Enable')

                It 'Should throw expected exception' {
                    {
                        Set-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Enable' -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call "Invoke-CimMethod" instead of "Set-ItemProperty"' {
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 1
                }
            }

            Context 'When interface does not exist' {
                Mock -CommandName Get-CimInstance -MockWith { }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.InterfaceNotFoundError -f $script:interfaceAliasA)

                It 'Should throw expected exception' {
                    {
                        Set-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Enable' -Verbose
                    } | Should -Throw $errorRecord
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
