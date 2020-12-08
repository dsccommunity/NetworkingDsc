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
                    -PassThru |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name NetConnectionID `
                    -Value $script:interfaceAliasA `
                    -PassThru |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name 'GUID' `
                    -Value '{00000000-0000-0000-0000-000000000001}' `
                    -PassThru |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name InterfaceIndex `
                    -Value 1 `
                    -PassThru

        $script:networkAdapterBCimInstance = New-Object `
            -TypeName CimInstance `
            -ArgumentList 'Win32_NetworkAdapter' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name Name `
                    -Value $script:interfaceAliasB `
                    -PassThru |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name NetConnectionID `
                    -Value $script:interfaceAliasB `
                    -PassThru |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name 'GUID' `
                    -Value '{00000000-0000-0000-0000-000000000002}' `
                    -PassThru |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name InterfaceIndex `
                    -Value 2 `
                    -PassThru

        $script:mockNetadapterA = {
            $script:networkAdapterACimInstance
        }

        $script:mockNetadapterB = {
            $script:networkAdapterBCimInstance
        }

        $script:mockNetadapterMulti = {
            @(
                $script:networkAdapterACimInstance,
                $script:networkAdapterBCimInstance
            )
        }

        $script:mockWin32NetworkAdapterConfiguration = {
                New-Object `
                -TypeName CimInstance `
                -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name IPEnabled `
                    -Value $false `
                    -PassThru
        }

        $script:mockWin32NetworkAdapterConfigurationIpEnabled = {
                New-Object `
                -TypeName CimInstance `
                -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name IPEnabled `
                    -Value $true `
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

        $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter = {
            $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000001}' -and `
            $Name -eq 'NetbiosOptions' 
        }

        $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter = {
            $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_{00000000-0000-0000-0000-000000000002}' -and `
            $Name -eq 'NetbiosOptions' 
        }

        $script:testCases = @(
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

        Describe 'DSC_NetBios\Get-TargetResource' -Tag 'Get' {
            Context 'When specifying a single network adapter' {
                foreach ($testCase in $script:testCases)
                {
                    Context "When NetBios over TCP/IP is set to '$($testCase.Setting)'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return $testCase.SettingInt } `
                                                                -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        
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
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                        }
                    }
                }

                Context 'When specifying a wildcard network adapter' {
                    Context "When both NetBios over TCP/IP is set to 'Default' on both and Setting is 'Default'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter

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
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                        }
                    }

                    Context "When both NetBios over TCP/IP is set to 'Enable' on both and Setting is 'Default'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 1 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 1 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter

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
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                        }
                    }

                    Context "When NetBios over TCP/IP is set to 'Enable' on the first, 'Disable' on the second and Setting is 'Default'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 1 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 2 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter

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
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                        }
                    }

                    Context "When NetBios over TCP/IP is set to 'Default' on the first, 'Disable' on the second and Setting is 'Default'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 2 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter

                        It 'Should not throw exception' {
                            {
                                $script:result = Get-TargetResource -InterfaceAlias '*' -Setting 'Default' -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Returns a hashtable' {
                            $script:result -is [System.Collections.Hashtable] | Should -BeTrue
                        }

                        It "Setting should return 'Enable'" {
                            $script:result.Setting | Should -Be 'Disable'
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                        }
                    }
                }

                Context 'When interface does not exist' {
                    Mock -CommandName Get-CimInstance

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.InterfaceNotFoundError -f $script:interfaceAliasA)

                    It 'Should throw expected exception' {
                        {
                            $script:result = Get-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Default' -Verbose
                        } | Should -Throw $errorRecord
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceParameterFilter -Exactly -Times 1
                    }
                }
            }
        }

        Describe 'DSC_NetBios\Test-TargetResource' -Tag 'Test' {
            Context 'When specifying a single network adapter' {
                foreach ($testCase in $script:testCases)
                {
                    Context "When NetBios over TCP/IP is set to '$($testCase.Setting)'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return $testCase.SettingInt } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter

                        It "Should return true when value '$($testCase.Setting)' is set" {
                            Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting $testCase.Setting -Verbose | Should -BeTrue
                        }

                        It "Should return false when value '$($testCase.NotSetting)' is set" {
                            Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting $testCase.NotSetting -Verbose | Should -BeFalse
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceParameterFilter -Exactly -Times 2
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 2
                        }
                    }
                }

                Context 'When specifying a wildcard network adapter' {
                    Context "When NetBios set to 'Default' on both and Setting is 'Default'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter

                        It 'Should return true' {
                            Test-TargetResource -InterfaceAlias '*' -Setting 'Default' -Verbose | Should -BeTrue
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                        }
                    }

                    Context "When NetBios set to 'Default' on both and Setting is 'Enable'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 1 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 1 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter

                        It 'Should return false' {
                            Test-TargetResource -InterfaceAlias '*' -Setting 'Default' -Verbose | Should -BeFalse
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                        }
                    }

                    Context "When NetBios set to 'Default' on first and 'Enable' on second and Setting is 'Enable'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 1 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter

                        It 'Should return false' {
                            Test-TargetResource -InterfaceAlias '*' -Setting 'Default' -Verbose | Should -BeFalse
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                        }
                    }
                }

                Context 'When interface does not exist' {
                    Mock -CommandName Get-CimInstance

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.InterfaceNotFoundError -f $script:interfaceAliasA)

                    It 'Should throw expected exception' {
                        {
                            Test-TargetResource -InterfaceAlias $script:interfaceAliasA -Setting 'Enable' -Verbose
                        } | Should -Throw $errorRecord
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                    }
                }
            }
        }

        Describe 'DSC_NetBios\Set-TargetResource' -Tag 'Set' {
            Context 'When specifying a single network adapter' {
                foreach ($testCase in $script:testCases)
                {
                    Context "When NetBios over TCP/IP should be set to '$($testCase.Setting)' and IPEnabled=True" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfigurationIpEnabled
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
                            Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0
                            Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 1
                        }
                    }
                }

                foreach ($testCase in $script:testCases)
                {
                    Context "When NetBios over TCP/IP should be set to '$($testCase.Setting)' and IPEnabled=False" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterA
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfiguration
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
                            Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
                            Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 0
                        }
                    }
                }

                Context 'When specifying a wildcard network adapter' {
                    Context "When all Interfaces are IPEnabled and NetBios set to 'Default' on both and Setting is 'Disable'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfigurationIpEnabled
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter
                        Mock -CommandName Invoke-CimMethod -MockWith $script:mockInvokeCimMethodError0
                        Mock -CommandName Set-ItemProperty

                        It 'Should not throw exception' {
                            {
                                Set-TargetResource -InterfaceAlias '*' -Setting $testCase.Setting -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 2
                            Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0
                        }
                    }

                    Context "When all Interfaces are NOT IPEnabled and NetBios set to 'Default' on both and Setting is 'Disable'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfiguration
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter
                        Mock -CommandName Invoke-CimMethod -MockWith $script:mockInvokeCimMethodError0
                        Mock -CommandName Set-ItemProperty

                        It 'Should not throw exception' {
                            {
                                Set-TargetResource -InterfaceAlias '*' -Setting $testCase.Setting -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 0
                            Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 2
                        }
                    }

                    Context "When first Interface is IPEnabled and NetBios set to 'Default' on both and Setting is 'Disable'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfigurationIpEnabled -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfiguration          -ParameterFilter $script:getCimAssociatedInstanceBParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter
                        Mock -CommandName Set-ItemProperty
                        Mock -CommandName Invoke-CimMethod -MockWith $script:mockInvokeCimMethodError0

                        It 'Should not throw exception' {
                            {
                                Set-TargetResource -InterfaceAlias '*' -Setting $testCase.Setting -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 1
                            Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
                        }
                    }

                    Context "When second Interface is IPEnabled and NetBios set to 'Default' on both and Setting is 'Disable'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfiguration          -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfigurationIpEnabled -ParameterFilter $script:getCimAssociatedInstanceBParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter
                        Mock -CommandName Invoke-CimMethod -MockWith $script:mockInvokeCimMethodError0
                        Mock -CommandName Set-ItemProperty

                        It 'Should not throw exception' {
                            {
                                Set-TargetResource -InterfaceAlias '*' -Setting $testCase.Setting -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 1
                            Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
                        }
                    }

                    Context "When first Interface is IPEnabled and NetBios set to 'Default' second Interface Netbios set to 'Disable' and Setting is 'Disable'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfigurationIpEnabled -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfiguration          -ParameterFilter $script:getCimAssociatedInstanceBParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 2 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter
                        Mock -CommandName Invoke-CimMethod -MockWith $script:mockInvokeCimMethodError0
                        Mock -CommandName Set-ItemProperty

                        It 'Should not throw exception' {
                            {
                                Set-TargetResource -InterfaceAlias '*' -Setting $testCase.Setting -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 1
                            Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0
                        }
                    }

                    Context "When first Interface is IPEnabled and NetBios set to 'Disable' second Interface Netbios set to 'Default' and Setting is 'Disable'" {
                        Mock -CommandName Get-CimInstance -MockWith $script:mockNetadapterMulti
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfigurationIpEnabled -ParameterFilter $script:getCimAssociatedInstanceAParameterFilter
                        Mock -CommandName Get-CimAssociatedInstance -MockWith $script:mockWin32NetworkAdapterConfiguration          -ParameterFilter $script:getCimAssociatedInstanceBParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 2 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter
                        Mock -CommandName Get-ItemPropertyValue -MockWith { return 0 } -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter
                        Mock -CommandName Invoke-CimMethod -MockWith $script:mockInvokeCimMethodError0
                        Mock -CommandName Set-ItemProperty

                        It 'Should not throw exception' {
                            {
                                Set-TargetResource -InterfaceAlias '*' -Setting $testCase.Setting -Verbose
                            } | Should -Not -Throw
                        }

                        It 'Should call expected mocks' {
                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceMultiParameterFilter -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_One_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Get-ItemPropertyValue -ParameterFilter $script:getItemPropertyValue_NetbiosOptions_Two_ParameterFilter `
                                                                                 -Exactly -Times 1
                            Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 0
                            Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
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
