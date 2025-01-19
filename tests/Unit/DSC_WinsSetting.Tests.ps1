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
    $script:dscResourceName = 'DSC_WinsSetting'

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

Describe 'DSC_WinsSetting\Get-TargetResource' -Tag 'Get' {
    Context 'EnableLmHosts is enabled and EnableDns is enabled' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableLMHOSTS'
            } -MockWith {
                @{
                    EnableLMHOSTS = 1
                }
            }

            Mock -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableDNS'
            } -MockWith {
                @{
                    EnableDNS = 1
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    IsSingleInstance = 'Yes'
                }

                { $script:result = Get-TargetResource @testParams } | Should -Not -Throw
            }
        }

        It 'Should return expected results' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.EnableLmHosts | Should -BeTrue
                $script:result.EnableDns | Should -BeTrue
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableLMHOSTS'
            } -Exactly -Times 1 -Scope Context

            Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableDNS'
            } -Exactly -Times 1 -Scope Context
        }
    }

    Context 'EnableLmHosts is disabled and EnableDns is disabled' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableLMHOSTS'
            } -MockWith {
                @{
                    EnableLMHOSTS = 0
                }
            }

            Mock -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableDNS'
            } -MockWith {
                @{
                    EnableDNS = 0
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    IsSingleInstance = 'Yes'
                }

                { $script:result = Get-TargetResource @testParams } | Should -Not -Throw
            }
        }

        It 'Should return expected results' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.EnableLmHosts | Should -BeFalse
                $script:result.EnableDns | Should -BeFalse
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableLMHOSTS'
            } -Exactly -Times 1 -Scope Context

            Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -and $Name -eq 'EnableDNS'
            } -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_DnsClientGlobalSetting\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Get-TargetResource -MockWith {
            @{
                IsSingleInstance = 'Yes'
                EnableLmHosts    = $true
                EnableDns        = $true
            }
        }
    }

    Context 'Set EnableLmHosts to enabled and EnableDns to enabled' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                @{
                    ReturnValue = 0
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    IsSingleInstance = 'Yes'
                    EnableLmHosts    = $true
                    EnableDns        = $true
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Set EnableLmHosts to disabled and EnableDns to disabled' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                @{
                    ReturnValue = 0
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    IsSingleInstance = 'Yes'
                    EnableLmHosts    = $false
                    EnableDns        = $false
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Set EnableLmHosts and EnableDNS but Invoke-CimMethod returns error' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                @{
                    ReturnValue = 74
                }
            }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.FailedUpdatingWinsSettingError -f 74, 'Enable')

                $testParams = @{
                    IsSingleInstance = 'Yes'
                    EnableLmHosts    = $true
                    EnableDns        = $true
                }

                { Set-TargetResource @testParams } | Should -Throw $errorRecord
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_DnsClientGlobalSetting\Test-TargetResource' -Tag 'Test' {
    Context 'EnableLmHosts is enabled and EnableDns is enabled' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    IsSingleInstance = 'Yes'
                    EnableLmHosts    = $true
                    EnableDns        = $true
                }
            }
        }

        Context 'Set EnableLmHosts to true and EnableDns to true' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        IsSingleInstance = 'Yes'
                        EnableLmHosts    = $true
                        EnableDns        = $true
                    }

                    { $script:result = Test-TargetResource @testParams } | Should -Not -Throw
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:result | Should -BeTrue
                }
            }
        }

        Context 'Set EnableLmHosts to false' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        IsSingleInstance = 'Yes'
                        EnableLmHosts    = $false
                    }

                    { $script:result = Test-TargetResource @testParams } | Should -Not -Throw
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:result | Should -BeFalse
                }
            }
        }

        Context 'Set EnableDns to false' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        IsSingleInstance = 'Yes'
                        EnableDns        = $false
                    }

                    { $script:result = Test-TargetResource @testParams } | Should -Not -Throw
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:result | Should -BeFalse
                }
            }
        }
    }

    Context 'EnableLmHosts is disabled and EnableDNS is disabled' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    IsSingleInstance = 'Yes'
                    EnableLmHosts    = $false
                    EnableDns        = $false
                }
            }
        }

        Context 'Set EnableLmHosts to false and EnableDNS to false' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        IsSingleInstance = 'Yes'
                        EnableLmHosts    = $false
                        EnableDns        = $false
                    }

                    { $script:result = Test-TargetResource @testParams } | Should -Not -Throw
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:result | Should -BeTrue
                }
            }
        }

        Context 'Set EnableLmHosts to true' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        IsSingleInstance = 'Yes'
                        EnableLmHosts    = $true
                    }

                    { $script:result = Test-TargetResource @testParams } | Should -Not -Throw
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:result | Should -BeFalse
                }
            }
        }

        Context 'Set EnableDns to true' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        IsSingleInstance = 'Yes'
                        EnableDns        = $true
                    }

                    { $script:result = Test-TargetResource @testParams } | Should -Not -Throw
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:result | Should -BeFalse
                }
            }
        }
    }
}
