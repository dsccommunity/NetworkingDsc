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
    $script:dscResourceName = 'DSC_DnsClientNrptRule'

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

Describe 'DSC_DnsClientNrptRule\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $mockNrptRule = @{
            Name        = 'Contoso Dns Policy'
            Namespace   = '.contoso.com'
            NameServers = @('192.168.1.1')
            Ensure      = 'Present'
        }

        $testNrptRule = @{
            Name        = 'Contoso Dns Policy'
            Namespace   = '.contoso.com'
            NameServers = @('192.168.1.1')
            Ensure      = 'Present'
        }

        InModuleScope -ScriptBlock {
            $script:testNrptRule = @{
                Name        = 'Contoso Dns Policy'
                Namespace   = '.contoso.com'
                NameServers = @('192.168.1.1')
                Ensure      = 'Present'
            }
        }
    }
    Context 'NRPT Rule does not exist' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule
        }

        It 'Should return absent NRPT Rule' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -Name 'Contoso Dns Policy'
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 1 -Scope Context
        }
    }

    Context 'NRPT Rule does exist' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
        }

        It 'Should return correct NRPT Rule' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -Name 'Contoso Dns Policy'
                $result.Ensure | Should -Be 'Present'
                $result.Namespace | Should -Be $testNrptRule.Namespace
                $result.NameServers | Should -Be $testNrptRule.NameServers
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_DnsClientNrptRule\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $mockNrptRule = @{
            Name        = 'Contoso Dns Policy'
            Namespace   = '.contoso.com'
            NameServers = @('192.168.1.1')
            Ensure      = 'Present'
        }

        $testNrptRule = @{
            Name        = 'Contoso Dns Policy'
            Namespace   = '.contoso.com'
            NameServers = @('192.168.1.1')
            Ensure      = 'Present'
        }

        InModuleScope -ScriptBlock {
            $script:testNrptRule = @{
                Name        = 'Contoso Dns Policy'
                Namespace   = '.contoso.com'
                NameServers = @('192.168.1.1')
                Ensure      = 'Present'
            }
        }
    }
    Context 'NRPT Rule does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule
            Mock -CommandName Add-DnsClientNrptRule
            Mock -CommandName Set-DnsClientNrptRule
            Mock -CommandName Remove-DnsClientNrptRule
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $testNrptRule.Clone()

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Add-DnsClientNrptRule -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-DnsClientNrptRule -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-DnsClientNrptRule -Exactly -Times 0 -Scope Context
        }
    }

    Context 'NRPT Rule exists and should but has a different Namespace' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
            Mock -CommandName Add-DnsClientNrptRule
            Mock -CommandName Set-DnsClientNrptRule
            Mock -CommandName Remove-DnsClientNrptRule
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $script:testNrptRule.Clone()
                $setTargetResourceParameters.Namespace = '.fabrikam.com'

                $result = Set-TargetResource @setTargetResourceParameters

                { $result } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Add-DnsClientNrptRule -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-DnsClientNrptRule -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Remove-DnsClientNrptRule -Exactly -Times 0 -Scope Context
        }
    }

    Context 'NRPT Rule exists and should but has a different NameServers' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
            Mock -CommandName Add-DnsClientNrptRule
            Mock -CommandName Set-DnsClientNrptRule
            Mock -CommandName Remove-DnsClientNrptRule
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $testNrptRule.Clone()
                $setTargetResourceParameters.NameServers = @('192.168.0.1')

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Add-DnsClientNrptRule -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-DnsClientNrptRule -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Remove-DnsClientNrptRule -Exactly -Times 0 -Scope Context
        }
    }

    Context 'NRPT Rule exists and but should not' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
            Mock -CommandName Add-DnsClientNrptRule
            Mock -CommandName Set-DnsClientNrptRule
            Mock -CommandName Remove-DnsClientNrptRule `
                -ParameterFilter {
                    ($Name -eq $testNrptRule.Name)
            }
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $testNrptRule.Clone()
                $setTargetResourceParameters.Ensure = 'Absent'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks and parameters' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Add-DnsClientNrptRule -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-DnsClientNrptRule -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-DnsClientNrptRule `
                -ParameterFilter {
                    ($Name -eq $testNrptRule.Name)
            } -Exactly -Times 1 -Scope Context
        }
    }

    Context 'NRPT Rule does not exist and should not' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule
            Mock -CommandName Add-DnsClientNrptRule
            Mock -CommandName Set-DnsClientNrptRule
            Mock -CommandName Remove-DnsClientNrptRule
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $testNrptRule.Clone()
                $setTargetResourceParameters.Ensure = 'Absent'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Add-DnsClientNrptRule -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-DnsClientNrptRule -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-DnsClientNrptRule -Exactly -Times 0 -Scope Context
        }
    }
}

Describe 'DSC_DnsClientNrptRule\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $mockNrptRule = @{
            Name        = 'Contoso Dns Policy'
            Namespace   = '.contoso.com'
            NameServers = @('192.168.1.1')
            Ensure      = 'Present'
        }

        $testNrptRule = @{
            Name        = 'Contoso Dns Policy'
            Namespace   = '.contoso.com'
            NameServers = @('192.168.1.1')
            Ensure      = 'Present'
        }

        InModuleScope -ScriptBlock {
            $script:testNrptRule = @{
                Name        = 'Contoso Dns Policy'
                Namespace   = '.contoso.com'
                NameServers = @('192.168.1.1')
                Ensure      = 'Present'
            }
        }
    }
    Context 'NRPT Rule does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testNrptRule.Clone()
                Test-TargetResource @testTargetResourceParameters | Should -BeFalse
            }

        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 1 -Scope Context
        }
    }

    Context 'NRPT Rule exists and should but has a different Namespace' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testNrptRule.Clone()
                $testTargetResourceParameters.Namespace = '.fabrikam.com'

                $result = Test-TargetResource @testTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 2 -Scope Context
        }
    }

    Context 'NRPT Rule exists and should but has a different NameServers' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testNrptRule.Clone()
                $testTargetResourceParameters.NameServers = @('192.168.0.1')

                $result = Test-TargetResource @testTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 2 -Scope Context
        }
    }

    Context 'NRPT Rule exists and should and all parameters match' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testNrptRule.Clone()

                $result = Test-TargetResource @testTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 2 -Scope Context
        }
    }

    Context 'NRPT Rule exists but should not' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testNrptRule.Clone()
                $testTargetResourceParameters.Ensure = 'Absent'

                $result = Test-TargetResource @testTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 1 -Scope Context
        }
    }

    Context 'NRPT Rule does not exist and should not' {
        BeforeAll {
            Mock -CommandName Get-DnsClientNrptRule
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testNrptRule.Clone()
                $testTargetResourceParameters.Ensure = 'Absent'

                $result = Test-TargetResource @testTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-DnsClientNrptRule -Exactly -Times 1 -Scope Context
        }
    }
}
