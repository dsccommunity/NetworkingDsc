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
    $script:dscResourceName = 'DSC_DnsConnectionSuffix'

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

Describe 'DSC_DnsConnectionSuffix\Get-TargetResource' -Tag 'Get' {
    Context 'Validates "Get-TargetResource" method' {
        Context 'When the Dns Suffix does match' {
            BeforeAll {
                Mock -CommandName Get-DnsClient -MockWith {
                    @{
                        InterfaceAlias                 = 'Ethernet'
                        ConnectionSpecificSuffix       = 'example.local'
                        RegisterThisConnectionsAddress = $true
                        UseSuffixWhenRegistering       = $false
                    }
                }
            }

            It 'Should return a "System.Collections.Hashtable" object type' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                    }

                    $targetResource = Get-TargetResource @testDnsSuffixParams

                    $targetResource -is [System.Collections.Hashtable] | Should -BeTrue
                }
            }

            It 'Should return "Present" when DNS suffix matches and "Ensure" = "Present"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                    }

                    $targetResource = Get-TargetResource @testDnsSuffixParams

                    $targetResource.Ensure | Should -Be 'Present'
                }
            }

            It 'Should return "Present" when DNS suffix is defined and "Ensure" = "Absent"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                        Ensure                   = 'Absent'
                    }

                    $targetResource = Get-TargetResource @testDnsSuffixParams

                    $targetResource.Ensure | Should -Be 'Present'
                }
            }
        }

        Context 'When the Dns Suffix is blank' {
            BeforeAll {
                Mock -CommandName Get-DnsClient -MockWith {
                    @{
                        InterfaceAlias                 = 'Ethernet'
                        ConnectionSpecificSuffix       = ''
                        RegisterThisConnectionsAddress = $true
                        UseSuffixWhenRegistering       = $false
                    }
                }
            }

            It 'Should return "Absent" when no DNS suffix is defined and "Ensure" = "Present"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                    }

                    $targetResource = Get-TargetResource @testDnsSuffixParams

                    $targetResource.Ensure | Should -Be 'Absent'
                }
            }

            It 'Should return "Absent" when no DNS suffix is defined and "Ensure" = "Absent"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                        Ensure                   = 'Absent'
                    }

                    $targetResource = Get-TargetResource @testDnsSuffixParams

                    $targetResource.Ensure | Should -Be 'Absent'
                }
            }
        }

        Context 'When the Dns Suffix does not match' {
            It 'Should return "Absent" when DNS suffix does not match and "Ensure" = "Present"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                    }

                    $targetResource = Get-TargetResource @testDnsSuffixParams

                    $targetResource.Ensure | Should -Be 'Absent'
                }
            }
        }
    }
}

Describe 'DSC_DnsConnectionSuffix\Test-TargetResource' -Tag 'Test' {
    Context 'Validates "Test-TargetResource" method' {
        Context 'When the Dns Suffix is present' {
            BeforeAll {
                Mock -CommandName Get-DnsClient -MockWith { @{
                        InterfaceAlias                 = 'Ethernet'
                        ConnectionSpecificSuffix       = 'example.local'
                        RegisterThisConnectionsAddress = $true
                        UseSuffixWhenRegistering       = $false
                    }
                }
            }

            It 'Should pass when all properties match and "Ensure" = "Present"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                    }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -BeTrue
                }
            }

            It 'Should pass when "RegisterThisConnectionsAddress" setting is correct' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias                 = 'Ethernet'
                        ConnectionSpecificSuffix       = 'example.local'
                        RegisterThisConnectionsAddress = $true
                    }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -BeTrue
                }
            }

            It 'Should pass when "UseSuffixWhenRegistering" setting is correct' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                        UseSuffixWhenRegistering = $false
                    }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -BeTrue
                }
            }

            It 'Should fail when a DNS suffix is registered and "Ensure" = "Absent"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                        Ensure                   = 'Absent'
                    }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -BeFalse
                }
            }

            It 'Should fail when "RegisterThisConnectionsAddress" setting is incorrect' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias                 = 'Ethernet'
                        ConnectionSpecificSuffix       = 'example.local'
                        RegisterThisConnectionsAddress = $false
                    }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -BeFalse
                }
            }

            It 'Should fail when "UseSuffixWhenRegistering" setting is incorrect' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                        UseSuffixWhenRegistering = $true
                    }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -BeFalse
                }
            }
        }

        Context 'When the Dns Suffix is Absent' {
            BeforeAll {
                Mock -CommandName Get-DnsClient -MockWith {
                    @{
                        InterfaceAlias                 = 'Ethernet'
                        ConnectionSpecificSuffix       = ''
                        RegisterThisConnectionsAddress = $true
                        UseSuffixWhenRegistering       = $false
                    }
                }
            }

            It 'Should pass when no DNS suffix is registered and "Ensure" = "Absent"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                        Ensure                   = 'Absent'
                    }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -BeTrue
                }
            }

            It 'Should fail when no DNS suffix is registered and "Ensure" = "Present"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                    }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -BeFalse
                }
            }

        }

        Context 'When the Dns Suffix is blank' {
            BeforeAll {
                Mock -CommandName Get-DnsClient -MockWith {
                    @{
                        InterfaceAlias                 = 'Ethernet'
                        ConnectionSpecificSuffix       = 'mismatch.local'
                        RegisterThisConnectionsAddress = $true
                        UseSuffixWhenRegistering       = $false
                    }
                }
            }

            It 'Should fail when the registered DNS suffix is incorrect and "Ensure" = "Present"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                    }

                    $targetResource = Test-TargetResource @testDnsSuffixParams

                    $targetResource | Should -BeFalse
                }
            }
        }
    }
}

Describe 'DSC_DnsConnectionSuffix\Set-TargetResource' -Tag 'Set' {
    Context 'Validates "Set-TargetResource" method' {
        Context 'When Dns Suffix should be added' {
            BeforeAll {
                Mock -CommandName Set-DnsClient
            }

            It 'Should call "Set-DnsClient" with specified DNS suffix when "Ensure" = "Present"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                    }

                    Set-TargetResource @testDnsSuffixParams
                }

                Should -Invoke -CommandName Set-DnsClient -ParameterFilter { $ConnectionSpecificSuffix -eq 'example.local' } `
                    -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Dns suffix should be removed' {
            BeforeAll {
                Mock -CommandName Set-DnsClient
            }

            It 'Should call "Set-DnsClient" with no DNS suffix when "Ensure" = "Absent"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testDnsSuffixParams = @{
                        InterfaceAlias           = 'Ethernet'
                        ConnectionSpecificSuffix = 'example.local'
                        Ensure                   = 'Absent'
                    }

                    Set-TargetResource @testDnsSuffixParams
                }

                Should -Invoke -CommandName Set-DnsClient -ParameterFilter { $ConnectionSpecificSuffix -eq '' } `
                    -Exactly -Times 1 -Scope It
            }
        }
    } #end Context 'Validates "Set-TargetResource" method'
}
