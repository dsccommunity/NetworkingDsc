$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_WinsSetting'

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
        # Create the Mock Objects that will be used for running tests
        $mockEnabledLmHostsRegistryKey = {
            [PSObject] @{
                EnableLMHOSTS = 1
            }
        }

        $mockDisabledLmHostsRegistryKey = {
            [PSObject] @{
                EnableLMHOSTS = 0
            }
        }

        $mockEnabledDNSRegistryKey = {
            [PSObject] @{
                EnableDNS = 1
            }
        }

        $mockDisabledDNSRegistryKey = {
            [PSObject] @{
                EnableDNS = 0
            }
        }

        $mockGetTargetResourceAllEnabled = {
            [PSObject] @{
                IsSingleInstance = 'Yes'
                EnableLmHosts    = $true
                EnableDns        = $true
            }
        }

        $mockGetTargetResourceAllDisabled = {
            [PSObject] @{
                IsSingleInstance = 'Yes'
                EnableLmHosts    = $false
                EnableDns        = $false
            }
        }

        $mockInvokeCimMethodReturnValueOK = {
            @{
                ReturnValue = 0
            }
        }

        $mockInvokeCimMethodReturnValueError = {
            @{
                ReturnValue = 74
            }
        }

        $getItemProperty_EnableLmHosts_ParameterFilter = {
            $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableLMHOSTS'
        }

        $getItemProperty_EnableDns_ParameterFilter = {
            $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableDNS'
        }

        $invokeCimMethod_EnableAll_ParameterFilter = {
            $ClassName -eq 'Win32_NetworkAdapterConfiguration' `
                -and $MethodName -eq 'EnableWins' `
                -and $Arguments.DNSEnabledForWINSResolution -eq $true `
                -and $Arguments.WINSEnableLMHostsLookup -eq $true
        }

        $invokeCimMethod_DisableAll_ParameterFilter = {
            $ClassName -eq 'Win32_NetworkAdapterConfiguration' `
                -and $MethodName -eq 'EnableWins' `
                -and $Arguments.DNSEnabledForWINSResolution -eq $false `
                -and $Arguments.WINSEnableLMHostsLookup -eq $false
        }

        Describe 'DSC_WinsSetting\Get-TargetResource' -Tag 'Get' {
            Context 'EnableLmHosts is enabled and EnableDns is enabled' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -ParameterFilter $getItemProperty_EnableLmHosts_ParameterFilter `
                    -MockWith $mockEnabledLmHostsRegistryKey

                Mock `
                    -CommandName Get-ItemProperty `
                    -ParameterFilter $getItemProperty_EnableDns_ParameterFilter `
                    -MockWith $mockEnabledDNSRegistryKey

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource -IsSingleInstance 'Yes' -Verbose } | Should -Not -Throw
                }

                It 'Should return expected results' {
                    $script:result.EnableLmHosts | Should -Be $true
                    $script:result.EnableDns | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -ParameterFilter $getItemProperty_EnableLmHosts_ParameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -ParameterFilter $getItemProperty_EnableDns_ParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'EnableLmHosts is disabled and EnableDns is disabled' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -ParameterFilter $getItemProperty_EnableLmHosts_ParameterFilter `
                    -MockWith $mockDisabledLmHostsRegistryKey

                Mock `
                    -CommandName Get-ItemProperty `
                    -ParameterFilter $getItemProperty_EnableDns_ParameterFilter `
                    -MockWith $mockDisabledDNSRegistryKey

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource -IsSingleInstance 'Yes' -Verbose } | Should -Not -Throw
                }

                It 'Should return expected results' {
                    $script:result.EnableLmHosts | Should -Be $false
                    $script:result.EnableDns | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -ParameterFilter $getItemProperty_EnableLmHosts_ParameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ItemProperty `
                        -ParameterFilter $getItemProperty_EnableDns_ParameterFilter `
                        -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_DnsClientGlobalSetting\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Get-TargetResource -MockWith { $mockGetTargetResourceAllEnabled }
            }

            Context 'Set EnableLmHosts to enabled and EnableDns to enabled' {
                Mock `
                    -CommandName Invoke-CimMethod `
                    -ParameterFilter $invokeCimMethod_EnableAll_ParameterFilter `
                    -MockWith $mockInvokeCimMethodReturnValueOK

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource -IsSingleInstance 'Yes' -EnableLmHosts $true -EnableDns $true -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Invoke-CimMethod `
                        -ParameterFilter $invokeCimMethod_EnableAll_ParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'Set EnableLmHosts to disabled and EnableDns to disabled' {
                Mock `
                    -CommandName Invoke-CimMethod `
                    -ParameterFilter $invokeCimMethod_DisableAll_ParameterFilter `
                    -MockWith $mockInvokeCimMethodReturnValueOK

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource -IsSingleInstance 'Yes' -EnableLmHosts $false -EnableDns $false -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Invoke-CimMethod `
                        -ParameterFilter $invokeCimMethod_DisableAll_ParameterFilter ` `
                        -Exactly -Times 1
                }
            }

            Context 'Set EnableLmHosts and EnableDNS but Invoke-CimMethod returns error' {
                Mock `
                    -CommandName Invoke-CimMethod `
                    -ParameterFilter $invokeCimMethod_EnableAll_ParameterFilter ` `
                    -MockWith $mockInvokeCimMethodReturnValueError

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.FailedUpdatingWinsSettingError -f 74, 'Enable')

                It 'Should throw an exception' {
                    {
                        Set-TargetResource -IsSingleInstance 'Yes' -EnableLmHosts $true -EnableDns $true -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled `
                        -CommandName Invoke-CimMethod `
                        -ParameterFilter $invokeCimMethod_EnableAll_ParameterFilter ` `
                        -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_DnsClientGlobalSetting\Test-TargetResource' -Tag 'Test' {
            Context 'EnableLmHosts is enabled and EnableDns is enabled' {
                Context 'Set EnableLmHosts to true and EnableDns to true' {
                    Mock -CommandName Get-TargetResource -MockWith $mockGetTargetResourceAllEnabled

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableLmHosts $true -EnableDns $true -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'Set EnableLmHosts to false' {
                    Mock -CommandName Get-TargetResource -MockWith $mockGetTargetResourceAllEnabled

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableLmHosts $false -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'Set EnableDns to false' {
                    Mock -CommandName Get-TargetResource -MockWith $mockGetTargetResourceAllEnabled

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableDns $false -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return false' {
                        $script:result | Should -Be $false
                    }
                }
            }

            Context 'EnableLmHosts is disabled and EnableDNS is disabled' {
                Context 'Set EnableLmHosts to false and EnableDNS to false' {
                    Mock -CommandName Get-TargetResource -MockWith $mockGetTargetResourceAllDisabled

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableLmHosts $false -EnableDns $false -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'Set EnableLmHosts to true' {
                    Mock -CommandName Get-TargetResource -MockWith $mockGetTargetResourceAllDisabled

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableLmHosts $true -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'Set EnableDns to true' {
                    Mock -CommandName Get-TargetResource -MockWith $mockGetTargetResourceAllDisabled

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableDns $true -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return false' {
                        $script:result | Should -Be $false
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
