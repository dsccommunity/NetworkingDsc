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

        $script:networkAdapterACimInstance = New-Object `
            -TypeName CimInstance `
            -ArgumentList 'Win32_NetworkAdapter' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name Name `
                    -Value $script:interfaceAliasA `
                    -PassThru

        $script:networkAdapterBCimInstance = New-Object `
            -TypeName CimInstance `
            -ArgumentList 'Win32_NetworkAdapter' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name Name `
                    -Value $script:interfaceAliasB `
                    -PassThru

        $script:mockNetadapterA = {
            $script:networkAdapterACimInstance
        }

        $script:mockNetadapterMulti = {
            @(
                $script:networkAdapterACimInstance,
                $script:networkAdapterBCimInstance
            )
        }

        $script:mockNetadapterSettingsDefault = {
                New-Object `
                -TypeName CimInstance `
                -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name TcpipNetbiosOptions `
                    -Value 0 `
                    -PassThru
        }

        $script:mockNetadapterSettingsEnable = {
            New-Object `
                -TypeName CimInstance `
                -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name TcpipNetbiosOptions `
                    -Value 1 `
                    -PassThru
        }

        $script:mockNetadapterSettingsDisable = {
            New-Object `
                -TypeName CimInstance `
                -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name TcpipNetbiosOptions `
                    -Value 2 `
                    -PassThru
        }

        $script:mockInvokeCimMethodError0 = {
            @{
                ReturnValue = 0
            }
        }

        $script:mockInvokeCimMethodError74 = {
            @{
                ReturnValue = 74
            }
        }

        $script:getCimInstanceParameterFilter = {
            $ClassName -eq 'Win32_NetworkAdapter' -and `
            $Filter -eq 'NetConnectionID="Test Adapter A"'
        }

        $script:getCimInstanceMultiParameterFilter = {
            $ClassName -eq 'Win32_NetworkAdapter' -and `
            $Filter -eq 'NetConnectionID LIKE "%"'
        }

        $script:getCimAssociatedInstanceAParameterFilter = {
            $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and `
            $InputObject.Name -eq $script:interfaceAliasA
        }

        $script:getCimAssociatedInstanceBParameterFilter = {
            $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' -and `
            $InputObject.Name -eq $script:interfaceAliasB
        }

        $script:testCases = @(
            @{
                Setting = 'Default'
                NotSetting = 'Enable'
                SetItemPropertyCalled = 1
                InvokeCimMethodCalled = 0
            },
            @{
                Setting = 'Enable'
                NotSetting = 'Disable'
                SetProcess = 'Invoke-CimMethod'
                SetItemPropertyCalled = 0
                InvokeCimMethodCalled = 1
            },
            @{
                Setting = 'Disable'
                NotSetting = 'Default'
                SetProcess = 'Invoke-CimMethod'
                SetItemPropertyCalled = 0
                InvokeCimMethodCalled = 1
            }
        )

        Describe 'DSC_NetBios\Get-TargetResource' -Tag 'Get' {
            Context 'When specifying a single network adapter' {
                foreach ($testCase in $script:testCases)
                {
                    Context "When NetBios over TCP/IP is set to '$($testCase.Setting)'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                        Mock -CommandName Get-CimAssociatedInstance -MockWith (Get-Variable -Name "mockNetadapterSettings$($testCase.Setting)" -Scope Script).Value

                        It 'Should not throw exception' {
                            {
                                $script:result = Get-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting $testCase.Setting -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Returns a hashtable' {
                            $script:result -is [System.Collections.Hashtable] | Should -BeTrue
                        }

                        It "Setting should return '$($testCase.Setting)'" {
                            $script:result.Setting | Should -Be $testCase.Setting
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter -Exactly -Times 1
                        }
                    }
                }

                Context 'When specifying a wildcard network adapter' {
                    Context "When both NetBios over TCP/IP is set to 'Default' on both and Settting is 'Default'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterSettingsDefault

                        It 'Should not throw exception' {
                            {
                                $script:result = Get-TargetResource -InterfaceAlias '*' -Setting 'Default' -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Returns a hashtable' {
                            $script:result -is [System.Collections.Hashtable] | Should -BeTrue
                        }

                        It "Setting should return 'Default'" {
                            $script:result.Setting | Should -Be 'Default'
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceBParameterFilter -Exactly -Times 1
                        }
                    }

                    Context "When both NetBios over TCP/IP is set to 'Enable' on both and Settting is 'Default'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockNetadapterSettingsEnable

                        It 'Should not throw exception' {
                            {
                                $script:result = Get-TargetResource -InterfaceAlias '*' -Setting 'Default' -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Returns a hashtable' {
                            $script:result -is [System.Collections.Hashtable] | Should -BeTrue
                        }

                        It "Setting should return 'Enable'" {
                            $script:result.Setting | Should -Be 'Enable'
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceBParameterFilter -Exactly -Times 0
                        }
                    }

                    Context "When NetBios over TCP/IP is set to 'Enable' on the first, 'Disable' on the second and Settting is 'Default'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter -MockWith $script:mockNetadapterSettingsEnable
                        Mock -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceBParameterFilter -MockWith $script:mockNetadapterSettingsDisable

                        It 'Should not throw exception' {
                            {
                                $script:result = Get-TargetResource -InterfaceAlias '*' -Setting 'Default' -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Returns a hashtable' {
                            $script:result -is [System.Collections.Hashtable] | Should -BeTrue
                        }

                        It "Setting should return 'Enable'" {
                            $script:result.Setting | Should -Be 'Enable'
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceBParameterFilter -Exactly -Times 0
                        }
                    }

                    Context "When NetBios over TCP/IP is set to 'Default' on the first, 'Disable' on the second and Settting is 'Default'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter -MockWith $script:mockNetadapterSettingsEnable
                        Mock -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceBParameterFilter -MockWith $script:mockNetadapterSettingsDisable

                        It 'Should not throw exception' {
                            {
                                $script:result = Get-TargetResource -InterfaceAlias '*' -Setting 'Default' -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Returns a hashtable' {
                            $script:result -is [System.Collections.Hashtable] | Should -BeTrue
                        }

                        It "Setting should return 'Enable'" {
                            $script:result.Setting | Should -Be 'Enable'
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceBParameterFilter -Exactly -Times 0
                        }
                    }
                }

                Context 'When interface does not exist' {
                    Mock -CommandName Get-CimInstance
                    Mock -CommandName Get-CimAssociatedInstance

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.InterfaceNotFoundError -f $script:interfaceAliasA)

                    It 'Should throw expected exception' {
                        {
                            $script:result = Get-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Default' -Verbose
                        } | Should -Throw $errorRecord
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceParameterFilter -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Exactly -Times 0
                    }
                }
            }
        }

        Describe 'DSC_NetBios\Test-TargetResource' -Tag 'Test' {
            Context 'When specifying a single network adapter' {
                foreach ($testCase in $script:testCases)
                    {
                    Context 'When NetBios over TCP/IP is set to "Default"' {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                        Mock -CommandName Get-CimAssociatedInstance -MockWith (Get-Variable -Name "mockNetadapterSettings$($testCase.Setting)" -Scope Script).Value

                        It "Should return true when value '$($testCase.Setting)' is set" {
                            Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting $testCase.Setting -Verbose | Should -BeTrue
                        }

                        It "Should return false when value '$($testCase.NotSetting)' is set" {
                            Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting $testCase.NotSetting -Verbose | Should -BeFalse
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceParameterFilter -Exactly -Times 2
                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter -Exactly -Times 2
                        }
                    }
                }

                Context 'When interface does not exist' {
                    Mock -CommandName Get-CimInstance
                    Mock -CommandName Get-CimAssociatedInstance

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.InterfaceNotFoundError -f $script:interfaceAliasA)

                    It 'Should throw expected exception' {
                        {
                            Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Enable' -Verbose
                        } | Should -Throw $errorRecord
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Exactly -Times 0
                    }
                }
            }
        }

        Describe 'DSC_NetBios\Set-TargetResource' -Tag 'Set' {
            Context 'When specifying a single network adapter' {
                foreach ($testCase in $script:testCases)
                {
                    Context "When NetBios over TCP/IP should be set to '$($testCase.Setting)'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                        Mock -CommandName Get-CimAssociatedInstance -MockWith (Get-Variable -Name "mockNetadapterSettings$($testCase.Setting)" -Scope Script).Value
                        Mock -CommandName Set-ItemProperty
                        Mock -CommandName Invoke-CimMethod -MockWith $script:mockInvokeCimMethodError0

                        It 'Should not throw exception' {
                            {
                                Set-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting $testCase.Setting -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times $testCase.SetItemPropertyCalled
                            Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times $testCase.InvokeCimMethodCalled
                        }
                    }
                }

                Context 'When interface does not exist' {
                    Mock -CommandName Get-CimInstance
                    Mock -CommandName Get-CimAssociatedInstance
                    Mock -CommandName Invoke-CimMethod
                    Mock -CommandName Set-ItemProperty

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.InterfaceNotFoundError -f $script:interfaceAliasA)

                    It 'Should throw expected exception' {
                        {
                            Set-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Enable' -Verbose
                        } | Should -Throw $errorRecord
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Exactly -Times 0
                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0
                        Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 0
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
