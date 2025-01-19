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
    $script:dscResourceName = 'DSC_Firewall'

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

Describe 'DSC_Firewall\Get-TargetResource' -Tag 'Get' {
    BeforeDiscovery {
        $firewallRule = Get-NetFirewallRule |
            Sort-Object -Property Name |
            Where-Object -Property DisplayGroup -ne $null |
            Select-Object -First 1
    }

    Context 'Absent should return correctly' {
        BeforeAll {
            Mock -CommandName Get-NetFirewallRule
        }

        It "Should return absent on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -Name 'FirewallRule'
                $result.Name | Should -Be 'FirewallRule'
                $result.Ensure | Should -Be 'Absent'
            }
        }
    }

    Context 'Present should return correctly' -ForEach $firewallRule {
        BeforeDiscovery {
            # Load the parameter List from the data file
            $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            $resourceData = Import-LocalizedData `
                -BaseDirectory (Join-Path -Path $moduleRoot -ChildPath 'source\DscResources\DSC_Firewall') `
                -FileName 'DSC_Firewall.data.psd1'

            $parameterList = $resourceData.ParameterList
        }

        BeforeAll {
            InModuleScope -Parameters @{
                firewallRule = $_
            } -ScriptBlock {
                $script:firewallRule = $firewallRule
                $script:properties = Get-FirewallRuleProperty -FirewallRule $firewallRule

                $script:result = Get-TargetResource -Name $firewallRule.Name
            }
        }

        It "Should have the correct <Name> on firewall rule $($firewallRule.Name)" -ForEach $parameterList {
            InModuleScope -Parameters @{
                parameter = $_
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                if ($parameter.ContainsKey('Property'))
                {
                    $parameterValue = (Get-Variable -Name ($parameter.Variable)).value.$($parameter.Property).$($parameter.Name)
                }
                else
                {
                    $parameterValue = (Get-Variable -Name ($parameter.Variable)).value.$($parameter.Name)
                }

                $parameterNew = $result.$($parameter.Name)
                if ($parameter.ContainsKey('Delimiter'))
                {
                    $parameterNew = $parameterNew -join ','
                }

                $parameterNew | Should -Be $parameterValue
            }
        }
    }
}

Describe 'DSC_Firewall\Test-TargetResource' -Tag 'Test' {
    BeforeDiscovery {
        $firewallRule = Get-NetFirewallRule |
            Sort-Object -Property Name |
            Where-Object -Property DisplayGroup -ne $null |
            Select-Object -First 1
    }

    Context 'Ensure is Absent and the Firewall is not Present' {
        BeforeAll {
            Mock -CommandName Get-FirewallRule
        }

        It "Should return $true on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    Name   = 'FirewallRule'
                    Ensure = 'Absent'
                }

                Test-TargetResource @testTargetResourceParameters | Should -BeTrue
            }
        }
    }

    Context 'Ensure is Absent and the Firewall is Present' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Test-RuleProperties
        }

        It "Should return $false on firewall rule $($firewallRule.Name)" {
            InModuleScope -Parameters @{
                firewallRule = $_
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    Name   = $firewallRule.Name
                    Ensure = 'Absent'
                }

                Test-TargetResource @testTargetResourceParameters | Should -BeFalse
            }
        }
    }

    Context 'Ensure is Present and the Firewall is Present and properties match' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Test-RuleProperties -MockWith { return $true }
        }

        It "Should return $true on firewall rule $($firewallRule.Name)" {
            InModuleScope -Parameters @{
                firewallRule = $_
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource -Name $firewallRule.Name | Should -BeTrue
            }
        }
    }

    Context 'Ensure is Present and the Firewall is Present and properties are different' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should return $false on firewall rule $($firewallRule.Name)" {
            InModuleScope -Parameters @{
                firewallRule = $_
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource -Name $firewallRule.Name | Should -BeFalse
            }
        }
    }

    Context 'Ensure is Present and the Firewall is Absent' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Get-FirewallRule
        }

        It "Should return $false on firewall rule $($firewallRule.Name)" {
            InModuleScope -Parameters @{
                firewallRule = $_
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource -Name $firewallRule.Name | Should -BeFalse
            }
        }
    }
}

Describe 'DSC_Firewall\Set-TargetResource' -Tag 'Set' {
    BeforeDiscovery {
        $firewallRule = Get-NetFirewallRule |
            Sort-Object -Property Name |
            Where-Object -Property DisplayGroup -ne $null |
            Select-Object -First 1
    }

    BeforeAll {
        $firewallRule = Get-NetFirewallRule |
            Sort-Object -Property Name |
            Where-Object -Property DisplayGroup -ne $null |
            Select-Object -First 1

        $properties = Get-FirewallRuleProperty -FirewallRule $firewallRule

        # To speed up all these tests create Mocks so that these functions are not repeatedly called
        Mock -CommandName Get-FirewallRule -MockWith { $firewallRule }
        Mock -CommandName Get-FirewallRuleProperty -MockWith { $properties }

        InModuleScope -Parameters @{
            firewallRule = $firewallRule
        } -ScriptBlock {
            $script:firewallRule = $firewallRule
        }
    }

    Context 'Ensure is Absent and Firewall rule exists' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Remove-NetFirewallRule
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name $firewallRule.Name -Ensure 'Absent'
            }

            Should -Invoke -CommandName Remove-NetFirewallRule -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Absent and Firewall rule with wildcard characters in name exists' {
        BeforeAll {
            Mock -CommandName Remove-NetFirewallRule -ParameterFilter {
                $Name -eq 'Test `[With`] Wildcard`*'
            }
        }

        It "Should call expected mocks on firewall rule 'Test [With] Wildcard*'" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name 'Test [With] Wildcard*' -Ensure 'Absent'
            }

            Should -Invoke -CommandName Remove-NetFirewallRule -ParameterFilter {
                $Name -eq 'Test `[With`] Wildcard`*'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Absent and the Firewall rule does not exist' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Get-FirewallRule
            Mock -CommandName Remove-NetFirewallRule
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name $firewallRule.Name -Ensure 'Absent'
            }

            Should -Invoke -CommandName Get-FirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-NetFirewallRule -Exactly -Times 0 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does not exist' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Get-FirewallRule
            Mock -CommandName New-NetFirewallRule
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name $firewallRule.Name -Ensure 'Present'
            }

            Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-FirewallRule -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different DisplayName' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name $firewallRule.Name -DisplayName 'Different' -Ensure 'Present'
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule with wildcard characters in name does exist but has a different DisplayName' {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule -ParameterFilter {
                $Name -eq 'Test `[With`] Wildcard`*'
            }

            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule 'Test [With] Wildcard*'" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name        = 'Test [With] Wildcard*'
                    DisplayName = 'Different'
                    Ensure      = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -ParameterFilter {
                $Name -eq 'Test `[With`] Wildcard`*'
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Group' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName New-NetFirewallRule
            Mock -CommandName Remove-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name        = $firewallRule.Name
                    DisplayName = $firewallRule.DisplayName
                    Group       = 'Different'
                    Ensure      = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist with a specified Group that is unchanged but some other parameter is different' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should remove Group from parameters before calling Set-NetFirewallRule mock on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                # 1. Group is specified but unchanged
                # 2. Some other parameter is different (Description)
                $setTargetResourceParameters = @{
                    Name        = $firewallRule.Name
                    Group       = $firewallRule.Group
                    Description = 'Different'
                    Ensure      = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -ExclusiveFilter {
                -not $PSBoundParameters.ContainsKey('Group')
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Enabled' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                if ( $firewallRule.Enabled -eq 'True' )
                {
                    $newEnabled = 'False'
                }
                else
                {
                    $newEnabled = 'True'
                }

                $setTargetResourceParameters = @{
                    Name    = $firewallRule.Name
                    Enabled = $newEnabled
                    Ensure  = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Action' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                if ( $firewallRule.Action -eq 'Allow')
                {
                    $NewAction = 'Block'
                }
                else
                {
                    $NewAction = 'Allow'
                }

                $setTargetResourceParameters = @{
                    Name   = $firewallRule.Name
                    Action = $NewAction
                    Ensure = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Profile' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                if ( $firewallRule.Profile -ccontains 'Domain')
                {
                    $NewProfile = @('Public', 'Private')
                }
                else
                {
                    $NewProfile = @('Domain', 'Public')
                }

                $setTargetResourceParameters = @{
                    Name    = $firewallRule.Name
                    Profile = $NewProfile
                    Ensure  = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Direction' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                if ( $firewallRule.Direction -eq 'Inbound')
                {
                    $NewDirection = 'Outbound'
                }
                else
                {
                    $NewDirection = 'Inbound'
                }

                $setTargetResourceParameters = @{
                    Name      = $firewallRule.Name
                    Direction = $NewDirection
                    Ensure    = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different RemotePort' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name       = $firewallRule.Name
                    RemotePort = 9999
                    Ensure     = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different LocalPort' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name      = $firewallRule.Name
                    LocalPort = 9999
                    Ensure    = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Protocol' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                if ( $firewallRule.Protocol -eq 'TCP')
                {
                    $NewProtocol = 'UDP'
                }
                else
                {
                    $NewProtocol = 'TCP'
                }

                $setTargetResourceParameters = @{
                    Name     = $firewallRule.Name
                    Protocol = $NewProtocol
                    Ensure   = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Description' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }
        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name        = $firewallRule.Name
                    Description = 'Different'
                    Ensure      = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Program' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name    = $firewallRule.Name
                    Program = 'Different'
                    Ensure  = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Service' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name    = $firewallRule.Name
                    Service = 'Different'
                    Ensure  = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Authentication' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                if ( $properties.SecurityFilters.Authentication -eq 'Required')
                {
                    $NewAuthentication = 'NotRequired'
                }
                else
                {
                    $NewAuthentication = 'Required'
                }

                $setTargetResourceParameters = @{
                    Name           = $firewallRule.Name
                    Authentication = $NewAuthentication
                    Ensure         = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Encryption' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                if ( $properties.SecurityFilters.Encryption -eq 'Required')
                {
                    $NewEncryption = 'NotRequired'
                }
                else
                {
                    $NewEncryption = 'Required'
                }

                $setTargetResourceParameters = @{
                    Name       = $firewallRule.Name
                    Encryption = $NewEncryption
                    Ensure     = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different InterfaceAlias' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name           = $firewallRule.Name
                    InterfaceAlias = 'Different'
                    Ensure         = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different InterfaceType' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                if ( $properties.InterfaceTypeFilters.InterfaceType -eq 'Wired')
                {
                    $NewInterfaceType = 'Wireless'
                }
                else
                {
                    $NewInterfaceType = 'Wired'
                }

                $setTargetResourceParameters = @{
                    Name          = $firewallRule.Name
                    InterfaceType = $NewInterfaceType
                    Ensure        = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different LocalAddress' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name         = $firewallRule.Name
                    LocalAddress = @('10.0.0.1/255.0.0.0', '10.1.1.0-10.1.2.0')
                    Ensure       = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different LocalUser' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name      = $firewallRule.Name
                    LocalUser = 'Different'
                    Ensure    = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Package' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name    = $firewallRule.Name
                    Package = 'Different'
                    Ensure  = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Platform' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name     = $firewallRule.Name
                    Platform = @('6.1')
                    Ensure   = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different RemoteAddress' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }
        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name          = $firewallRule.Name
                    RemoteAddress = @('10.0.0.1/255.0.0.0', '10.1.1.0-10.1.2.0')
                    Ensure        = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different RemoteMachine' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name          = $firewallRule.Name
                    RemoteMachine = 'Different'
                    Ensure        = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different RemoteUser' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }
        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name       = $firewallRule.Name
                    RemoteUser = 'Different'
                    Ensure     = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different DynamicTransport' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name             = $firewallRule.Name
                    DynamicTransport = 'WifiDirectDisplay'
                    Ensure           = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }
    Context 'Ensure is Present and the Firewall rule does exist but has a different EdgeTraversalPolicy' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name                = $firewallRule.Name
                    EdgeTraversalPolicy = 'Block'
                    Ensure              = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different IcmpType' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name     = $firewallRule.Name
                    IcmpType = @('52', '53')
                    Ensure   = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different LocalOnlyMapping' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name             = $firewallRule.Name
                    LocalOnlyMapping = $true
                    Ensure           = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different LooseSourceMapping' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name               = $firewallRule.Name
                    LooseSourceMapping = $true
                    Ensure             = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different OverrideBlockRules' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name               = $firewallRule.Name
                    OverrideBlockRules = $true
                    Ensure             = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist but has a different Owner' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $false }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name   = $firewallRule.Name
                    Owner  = (Get-CimInstance win32_useraccount | Select-Object -First 1).Sid
                    Ensure = 'Present'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'Ensure is Present and the Firewall rule does exist and is the same' -ForEach $firewallRule {
        BeforeAll {
            Mock -CommandName Set-NetFirewallRule
            Mock -CommandName Test-RuleProperties -MockWith { return $true }
        }

        It "Should call expected mocks on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name $firewallRule.Name -Ensure 'Present'
            }

            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Test-RuleProperties -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_Firewall\Test-RuleProperties' {
    BeforeDiscovery {
        $firewallRule = Get-NetFirewallRule |
            Sort-Object -Property Name |
            Where-Object -Property DisplayGroup -ne $null |
            Select-Object -First 1
    }

    Context 'When testing with a rule that has property differences' -ForEach $firewallRule {
        BeforeDiscovery {
            $testCases = @(
                @{
                    PropertyName  = 'Name'
                    PropertyValue = 'Different'
                },
                @{
                    PropertyName  = 'DisplayName'
                    PropertyValue = 'Different'
                },
                @{
                    PropertyName  = 'Group'
                    PropertyValue = 'Different'
                },
                @{
                    PropertyName  = 'RemotePort'
                    PropertyValue = 1
                },
                @{
                    PropertyName  = 'LocalPort'
                    PropertyValue = 1
                },
                @{
                    PropertyName  = 'Description'
                    PropertyValue = 'Different'
                },
                @{
                    PropertyName  = 'Program'
                    PropertyValue = 'Different'
                },
                @{
                    PropertyName  = 'Service'
                    PropertyValue = 'Different'
                },
                @{
                    PropertyName  = 'InterfaceAlias'
                    PropertyValue = 'Different'
                },
                @{
                    PropertyName  = 'LocalAddress'
                    PropertyValue = @('10.0.0.1/255.0.0.0', '10.1.1.0-10.1.2.0')
                },
                @{
                    PropertyName  = 'LocalUser'
                    PropertyValue = 'Different'
                },
                @{
                    PropertyName  = 'Package'
                    PropertyValue = 'Different'
                },
                @{
                    PropertyName  = 'Platform'
                    PropertyValue = @('6.2')
                },
                @{
                    PropertyName  = 'RemoteAddress'
                    PropertyValue = @('10.0.0.1/255.0.0.0', '10.1.1.0-10.1.2.0')
                },
                @{
                    PropertyName  = 'RemoteMachine'
                    PropertyValue = 'Different'
                },
                @{
                    PropertyName  = 'RemoteUser'
                    PropertyValue = 'Different'
                },
                @{
                    PropertyName  = 'DynamicTransport'
                    PropertyValue = 'WifiDirectDevices'
                },
                @{
                    PropertyName  = 'EdgeTraversalPolicy'
                    PropertyValue = 'DeferToApp'
                },
                @{
                    PropertyName  = 'IcmpType'
                    PropertyValue = @('53', '54')
                },
                @{
                    PropertyName  = 'LocalOnlyMapping'
                    PropertyValue = ! $compareRule.LocalOnlyMapping
                },
                @{
                    PropertyName  = 'LooseSourceMapping'
                    PropertyValue = ! $compareRule.LooseSourceMapping
                },
                @{
                    PropertyName  = 'OverrideBlockRules'
                    PropertyValue = ! $compareRule.OverrideBlockRules
                },
                @{
                    PropertyName  = 'Owner'
                    PropertyValue = (Get-CimInstance win32_useraccount | Select-Object -First 1).Sid
                }
            )
        }

        BeforeAll {
            $properties = Get-FirewallRuleProperty -FirewallRule $_

            # To speed up all these tests create Mocks so that these functions are not repeatedly called
            Mock -CommandName Get-FirewallRule -MockWith { $_ }
            Mock -CommandName Get-FirewallRuleProperty -MockWith { $properties }

            # Load the parameter List from the data file
            $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            $resourceData = Import-LocalizedData `
                -BaseDirectory (Join-Path -Path $moduleRoot -ChildPath 'source\DscResources\DSC_Firewall') `
                -FileName 'DSC_Firewall.data.psd1'

            $parameterList = $resourceData.ParameterList

            InModuleScope -Parameters @{
                parameterList = $parameterList
                firewallRule  = $_
                properties    = $properties
            } -ScriptBlock {
                $script:firewallRule = $firewallRule

                # Make an object that can be splatted onto the function
                $script:testRuleProperties = @{
                    Verbose = $false
                }

                foreach ($parameter in $ParameterList)
                {
                    if ($parameter.Property)
                    {
                        $parameterValue = (Get-Variable -Name ($parameter.Variable)).value.$($parameter.Property).$($parameter.Name)
                    }
                    else
                    {
                        $parameterValue = (Get-Variable -Name ($parameter.Variable)).value.$($parameter.Name)
                    }

                    if ($parameter.Delimiter)
                    {
                        $parameterValue = $parameterValue -split $parameter.Delimiter
                    }

                    $script:testRuleProperties += @{ $parameter.Name = $parameterValue }
                }
            }
        }

        Context 'When testing with a rule with a different ''<PropertyName>''' -ForEach $testCases {
            It "Should return False on firewall rule $($firewallRule.Name)" {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()
                    $compareRule.$PropertyName = $PropertyValue

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeFalse
                }
            }
        }

        Context 'When testing with a rule with a different enabled' {
            It "Should return False on firewall rule $($firewallRule.Name)" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()

                    if ( $compareRule.Enabled -eq 'True' )
                    {
                        $compareRule.Enabled = 'False'
                    }
                    else
                    {
                        $compareRule.Enabled = 'True'
                    }

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeFalse
                }
            }
        }

        Context 'When testing with a rule with a different action' {
            It "Should return False on firewall rule $($firewallRule.Name)" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()

                    if ($compareRule.Action -eq 'Allow')
                    {
                        $compareRule.Action = 'Block'
                    }
                    else
                    {
                        $compareRule.Action = 'Allow'
                    }

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeFalse
                }
            }
        }

        Context 'When testing with a rule with a different profile' {
            It "Should return False on firewall rule $($firewallRule.Name)" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()

                    if ( $compareRule.Profile -ccontains 'Domain')
                    {
                        $compareRule.Profile = @('Public', 'Private')
                    }
                    else
                    {
                        $compareRule.Profile = @('Domain', 'Public')
                    }

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeFalse
                }
            }
        }

        Context 'When testing with a rule with a different direction' {
            It "Should return False on firewall rule $($firewallRule.Name)" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()

                    if ($compareRule.Direction -eq 'Inbound')
                    {
                        $compareRule.Direction = 'Outbound'
                    }
                    else
                    {
                        $compareRule.Direction = 'Inbound'
                    }

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeFalse
                }
            }
        }

        Context 'When testing with a rule with a different protocol' {
            It "Should return False on firewall rule $($firewallRule.Name)" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()

                    if ( $compareRule.Protocol -eq 'TCP')
                    {
                        $compareRule.Protocol = 'UDP'
                    }
                    else
                    {
                        $compareRule.Protocol = 'TCP'
                    }

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeFalse
                }
            }
        }

        Context 'When testing with a rule with a different Authentication' {
            It "Should return False on firewall rule $($firewallRule.Name)" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()

                    if ( $compareRule.Authentication -eq 'Required')
                    {
                        $compareRule.Authentication = 'NotRequired'
                    }
                    else
                    {
                        $compareRule.Authentication = 'Required'
                    }

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeFalse
                }
            }
        }

        Context 'When testing with a rule with a different Encryption' {
            It "Should return False on firewall rule $($firewallRule.Name)" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()

                    if ( $compareRule.Encryption -eq 'Required')
                    {
                        $compareRule.Encryption = 'NotRequired'
                    }
                    else
                    {
                        $compareRule.Encryption = 'Required'
                    }

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeFalse
                }
            }
        }

        Context 'When testing with a rule with a different InterfaceType' {
            It "Should return False on firewall rule $($firewallRule.Name)" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()

                    if ( $compareRule.InterfaceType -eq 'Wired')
                    {
                        $compareRule.InterfaceType = 'Wireless'
                    }
                    else
                    {
                        $compareRule.InterfaceType = 'Wired'
                    }

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeFalse
                }
            }
        }
    }

    Context 'When testing with a rule with no differences' -ForEach $firewallRule {
        Context 'When there are no format differences' {
            BeforeAll {
                $script:properties = Get-FirewallRuleProperty -FirewallRule $_

                Mock -CommandName Get-FirewallRule -MockWith { $_ }
                Mock -CommandName Get-FirewallRuleProperty -MockWith { $properties }

                # Load the parameter List from the data file
                $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                $resourceData = Import-LocalizedData `
                    -BaseDirectory (Join-Path -Path $moduleRoot -ChildPath 'source\DscResources\DSC_Firewall') `
                    -FileName 'DSC_Firewall.data.psd1'

                $parameterList = $resourceData.ParameterList

                InModuleScope -Parameters @{
                    parameterList = $parameterList
                    firewallRule  = $_
                    properties    = $properties
                } -ScriptBlock {
                    $script:firewallRule = $firewallRule

                    # Make an object that can be splatted onto the function
                    $script:testRuleProperties = @{
                        Verbose = $false
                    }

                    foreach ($parameter in $ParameterList)
                    {
                        if ($parameter.Property)
                        {
                            $parameterValue = (Get-Variable -Name ($parameter.Variable)).value.$($parameter.Property).$($parameter.Name)
                        }
                        else
                        {
                            $parameterValue = (Get-Variable -Name ($parameter.Variable)).value.$($parameter.Name)
                        }

                        if ($parameter.Delimiter)
                        {
                            $parameterValue = $parameterValue -split $parameter.Delimiter
                        }

                        $script:testRuleProperties += @{ $parameter.Name = $parameterValue }
                    }
                }
            }

            It "Should return True on firewall rule $($firewallRule.Name)" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeTrue
                }
            }
        }

        Context 'When the LocalAddress subnet mask uses CIDR bits format' {
            BeforeAll {
                $localAddressProperties = $properties.Clone()
                $localAddressProperties.AddressFilters = [PSCustomObject] @{
                    LocalAddress  = '10.0.0.0/255.0.0.0'
                    RemoteAddress = $localAddressProperties.AddressFilters.RemoteAddress
                }

                Mock -CommandName Get-FirewallRule -MockWith { $_ }
                Mock -CommandName Get-FirewallRuleProperty -MockWith { $localAddressProperties }
            }

            It "Should return True on firewall rule $($firewallRule.Name)" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()
                    $compareRule.LocalAddress = '10.0.0.0/8'

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeTrue
                }
            }
        }

        Context 'When the RemoteAddress subnet mask uses CIDR bits format' {
            BeforeAll {
                $remoteAddressProperties = $properties.Clone()
                $remoteAddressProperties.AddressFilters = [PSCustomObject] @{
                    LocalAddress  = $remoteAddressProperties.AddressFilters.LocalAddress
                    RemoteAddress = '10.0.0.0/255.0.0.0'
                }

                Mock -CommandName Get-FirewallRule -MockWith { $_ }
                Mock -CommandName Get-FirewallRuleProperty -MockWith { $remoteAddressProperties }
            }

            It "Should return True on firewall rule $($firewallRule.Name)" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareRule = $testRuleProperties.Clone()
                    $compareRule.RemoteAddress = '10.0.0.0/8'

                    Test-RuleProperties -FirewallRule $firewallRule @compareRule | Should -BeTrue
                }
            }
        }
    }
}

Describe 'DSC_Firewall\Get-FirewallRule' {
    BeforeDiscovery {
        $firewallRule = Get-NetFirewallRule |
            Sort-Object -Property Name |
            Where-Object -Property DisplayGroup -ne $null |
            Select-Object -First 1
    }

    Context 'Testing with firewall that exists' -ForEach $firewallRule {
        It "Should return a firewall rule when name is passed on firewall rule $($firewallRule.Name)" {
            InModuleScope -Parameters @{
                firewallRule = $_
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-FirewallRule -Name $firewallRule.Name
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When testing with firewall that does not exist' -ForEach $firewallRule {
        It "Should not return anything on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-FirewallRule -Name 'Does not exist'
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When testing with firewall that somehow occurs more than once' -ForEach $firewallRule {
        BeforeAll {
            $firewallRules = Get-NetFirewallRule |
                Sort-Object -Property Name |
                Where-Object -Property DisplayGroup -ne $null |
                Select-Object -First 2

            Mock -CommandName Get-NetFirewallRule -MockWith { $firewallRules }
        }

        It "Should throw RuleNotUnique exception on firewall rule $($firewallRule.Name)" {
            InModuleScope -Parameters @{
                firewallRule = $_
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.RuleNotUniqueError -f 2, $firewallRule.Name)

                { Get-FirewallRule -Name $firewallRule.Name } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When testing with firewall that exists and name contains wildcard characters' {
        BeforeAll {
            $script:firewallRule = Get-NetFirewallRule |
                Sort-Object -Property Name |
                Where-Object -Property DisplayGroup -ne $null |
                Select-Object -First 1

            Mock -CommandName Get-NetFirewallRule -ParameterFilter {
                $Name -eq 'Test `[With`] Wildcard`*'
            } -MockWith { $firewallRule }
        }

        It 'Should return a firewall rule when name is passed with wildcard characters' {
            InModuleScope -Parameters @{
                firewallRule = $firewallRule
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-FirewallRule -Name 'Test [With] Wildcard*'
                $result.Name | Should -Be $firewallRule.Name
            }
        }

        It 'Should call Get-NetFirewallRule with Name parameter value escaped' {
            Should -Invoke -CommandName Get-NetFirewallRule -ParameterFilter {
                $Name -eq 'Test `[With`] Wildcard`*'
            } -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_Firewall\Get-FirewallRuleProperty' {
    BeforeDiscovery {
        $firewallRule = Get-NetFirewallRule |
            Sort-Object -Property Name |
            Where-Object -Property DisplayGroup -ne $null |
            Select-Object -First 1
    }

    Context 'All Properties' -ForEach $firewallRule {
        BeforeAll {
            InModuleScope -Parameters @{
                firewallRule = $_
            } -ScriptBlock {
                $script:firewallRule = $firewallRule
                $script:result = Get-FirewallRuleProperty -FirewallRule $firewallRule
            }
        }

        It "Should return the right address filter on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $expected = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $firewallRule

                $($result.AddressFilters | Out-String -Stream) |
                    Should -Be $($expected | Out-String -Stream)
            }
        }

        It "Should return the right application filter on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $expected = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $firewallRule

                $($result.ApplicationFilters | Out-String -Stream) |
                    Should -Be $($expected | Out-String -Stream)
            }
        }

        It "Should return the right interface filter on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $expected = Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $firewallRule

                $($result.InterfaceFilters | Out-String -Stream) |
                    Should -Be $($expected | Out-String -Stream)
            }
        }

        It "Should return the right interface type filter on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $expected = Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $firewallRule

                $($result.InterfaceTypeFilters | Out-String -Stream) |
                    Should -Be $($expected | Out-String -Stream)
            }
        }

        It "Should return the right port filter on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $expected = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $firewallRule

                $($result.PortFilters | Out-String -Stream) |
                    Should -Be $($expected | Out-String -Stream)
            }
        }

        It "Should return the right Profile on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $expected = Get-NetFirewallProfile -AssociatedNetFirewallRule $firewallRule

                $($result.Profile | Out-String -Stream) |
                    Should -Be $($expected | Out-String -Stream)
            }
        }

        It "Should return the right Security Filters on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $expected = Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $firewallRule

                $($result.SecurityFilters | Out-String -Stream) |
                    Should -Be $($expected | Out-String -Stream)
            }
        }

        It "Should return the right Service Filters on firewall rule $($firewallRule.Name)" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $expected = Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $firewallRule

                $($result.ServiceFilters | Out-String -Stream) |
                    Should -Be $($expected | Out-String -Stream)
            }
        }
    }
}

Describe 'DSC_Firewall\ConvertTo-FirewallRuleNameEscapedString' {
    Context 'Rule name that contains no escaped characters' {
        It 'Should return the rule name with no backticks added' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                ConvertTo-FirewallRuleNameEscapedString -Name 'No Escaped Characters' | Should -Be 'No Escaped Characters'
            }
        }
    }

    Context 'Rule name that contains at least one of each escaped characters' {
        It 'Should return the rule name with expected backticks added' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                ConvertTo-FirewallRuleNameEscapedString -Name 'Left [ Right ] Asterisk *' | Should -Be 'Left `[ Right `] Asterisk `*'
            }
        }
    }
}
