$script:DSCModuleName = 'xNetworking'
$script:DSCResourceName = 'MSFT_xWinsSetting'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        # Create the Mock Objects that will be used for running tests
        $mockEnabledLmHostsRegistryKey = [PSObject] @{
            EnableLMHosts = 1
        }

        $mockDisabledLmHostsRegistryKey = [PSObject] @{
            EnableLMHosts = 0
        }

        $mockEnabledDNSRegistryKey = [PSObject] @{
            EnableDNS = 1
        }

        $mockDisabledDNSRegistryKey = [PSObject] @{
            EnableDNS = 0
        }

        $mockGetTargetResourceAllEnabled = [PSObject] @{
            IsSingleInstance = 'Yes'
            EnableLMHOSTS    = $true
            EnableDNS        = $true
        }

        $mockGetTargetResourceAllDisabled = [PSObject] @{
            IsSingleInstance = 'Yes'
            EnableLMHOSTS    = $false
            EnableDNS        = $false
        }

        Describe 'MSFT_xWinsSetting\Get-TargetResource' {
            Context 'EnableLMHosts is enabled and EnableDNS is enabled' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -ParameterFilter {
                    $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableLMHOSTS'
                } `
                    -MockWith {
                    $mockEnabledLmHostsRegistryKey
                }

                Mock `
                    -CommandName Get-ItemProperty `
                    -ParameterFilter {
                    $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableDNS'
                } `
                    -MockWith {
                    $mockEnabledDNSRegistryKey
                }

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource -IsSingleInstance 'Yes' -Verbose } | Should -Not -Throw
                }

                It 'Should return expected results' {
                    $script:result.EnableLMHOSTS | Should Be $true
                    $script:result.EnableDNS | Should Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 2
                }
            }

            Context 'EnableLMHosts is disabled and EnableDNS is disabled' {
                Mock `
                    -CommandName Get-ItemProperty `
                    -ParameterFilter {
                    $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableLMHOSTS'
                } `
                    -MockWith {
                    $mockDisabledLmHostsRegistryKey
                }

                Mock `
                    -CommandName Get-ItemProperty `
                    -ParameterFilter {
                    $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableDNS'
                } `
                    -MockWith {
                    $mockDisabledDNSRegistryKey
                }

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource -IsSingleInstance 'Yes' -Verbose } | Should -Not -Throw
                }

                It 'Should return expected results' {
                    $script:result.EnableLMHOSTS | Should Be $false
                    $script:result.EnableDNS | Should Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 2
                }
            }
        }

        Describe 'MSFT_xDnsClientGlobalSetting\Set-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-TargetResource -MockWith { $mockGetTargetResourceAllEnabled }
            }

            Context 'Set EnableLMHosts to enabled and EnableDNS to enabled' {
                Mock -CommandName Invoke-CimMethod -MockWith { @{ ReturnValue = 0 } }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource -IsSingleInstance 'Yes' -EnableLMHosts $true -EnableDNS $true -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Invoke-CimMethod -Exactly -Times 1
                }
            }

            Context 'Set EnableLMHosts to disabled and EnableDNS to disabled' {
                Mock -CommandName Invoke-CimMethod -MockWith { @{ ReturnValue = 0 } }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource -IsSingleInstance 'Yes' -EnableLMHosts $false -EnableDNS $false -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Invoke-CimMethod -Exactly -Times 1
                }
            }

            Context 'Set EnableLMHosts and EnableDNS but Invoke-CimMethod returns error' {
                Mock -CommandName Invoke-CimMethod -MockWith { @{ ReturnValue = 74 } }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.FailedUpdatingWinsSettingError -f 74, 'Enable')

                It 'Should throw an exception' {
                    {
                        Set-TargetResource -IsSingleInstance 'Yes' -EnableLMHosts $true -EnableDNS $true -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Invoke-CimMethod -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_xDnsClientGlobalSetting\Test-TargetResource' {
            Context 'EnableLMHosts is enabled and EnableDNS is enabled' {
                Context 'Set EnableLMHosts to true and EnableDNS to true' {
                    Mock -CommandName Get-TargetResource -MockWith { $mockGetTargetResourceAllEnabled }

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableLMHosts $true -EnableDNS $true -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'Set EnableLMHosts to false' {
                    Mock -CommandName Get-TargetResource -MockWith { $mockGetTargetResourceAllEnabled }

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableLMHosts $false -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'Set EnableDNS to false' {
                    Mock -CommandName Get-TargetResource -MockWith { $mockGetTargetResourceAllEnabled }

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableDNS $false -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return false' {
                        $script:result | Should -Be $false
                    }
                }
            }

            Context 'EnableLMHosts is disabled and EnableDNS is disabled' {
                Context 'Set EnableLMHosts to false and EnableDNS to false' {
                    Mock -CommandName Get-TargetResource -MockWith { $mockGetTargetResourceAllDisabled }

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableLMHosts $false -EnableDNS $false -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'Set EnableLMHosts to true' {
                    Mock -CommandName Get-TargetResource -MockWith { $mockGetTargetResourceAllDisabled }

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableLMHosts $true -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'Set EnableDNS to true' {
                    Mock -CommandName Get-TargetResource -MockWith { $mockGetTargetResourceAllDisabled }

                    It 'Should not throw an exception' {
                        {
                            $script:result = Test-TargetResource -IsSingleInstance 'Yes' -EnableDNS $true -Verbose
                        } | Should -Not -Throw
                    }

                    It 'Should return false' {
                        $script:result | Should -Be $false
                    }
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
