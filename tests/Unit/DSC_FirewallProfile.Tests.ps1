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
    $script:dscResourceName = 'DSC_FirewallProfile'

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

Describe 'DSC_FirewallProfile\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $script:firewallProfile = @{
            Name                            = 'Private'
            Enabled                         = 'False'
            DefaultInboundAction            = 'Block'
            DefaultOutboundAction           = 'Block'
            AllowInboundRules               = 'False'
            AllowLocalFirewallRules         = 'False'
            AllowLocalIPsecRules            = 'False'
            AllowUserApps                   = 'False'
            AllowUserPorts                  = 'False'
            AllowUnicastResponseToMulticast = 'False'
            NotifyOnListen                  = 'False'
            EnableStealthModeForIPsec       = 'False'
            LogFileName                     = '%systemroot%\system32\LogFiles\Firewall\pfirewall.log'
            LogMaxSizeKilobytes             = 32767
            LogAllowed                      = 'False'
            LogBlocked                      = 'False'
            LogIgnored                      = 'False'
            DisabledInterfaceAliases        = 'Ethernet'
        }

        Mock -CommandName Get-NetFirewallProfile -MockWith { $firewallProfile }
    }

    Context 'Firewall Profile Exists' {
        It 'Should return correct Firewall Profile values' {
            InModuleScope -Parameters @{
                firewallProfile = $firewallProfile
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -Name 'Private'

                $result.Name | Should -Be $firewallProfile.Name
                $result.Enabled | Should -Be $firewallProfile.Enabled
                $result.DefaultInboundAction | Should -Be $firewallProfile.DefaultInboundAction
                $result.DefaultOutboundAction | Should -Be $firewallProfile.DefaultOutboundAction
                $result.AllowInboundRules | Should -Be $firewallProfile.AllowInboundRules
                $result.AllowLocalFirewallRules | Should -Be $firewallProfile.AllowLocalFirewallRules
                $result.AllowLocalIPsecRules | Should -Be $firewallProfile.AllowLocalIPsecRules
                $result.AllowUserApps | Should -Be $firewallProfile.AllowUserApps
                $result.AllowUserPorts | Should -Be $firewallProfile.AllowUserPorts
                $result.AllowUnicastResponseToMulticast | Should -Be $firewallProfile.AllowUnicastResponseToMulticast
                $result.NotifyOnListen | Should -Be $firewallProfile.NotifyOnListen
                $result.EnableStealthModeForIPsec | Should -Be $firewallProfile.EnableStealthModeForIPsec
                $result.LogFileName | Should -Be $firewallProfile.LogFileName
                $result.LogMaxSizeKilobytes | Should -Be $firewallProfile.LogMaxSizeKilobytes
                $result.LogAllowed | Should -Be $firewallProfile.LogAllowed
                $result.LogBlocked | Should -Be $firewallProfile.LogBlocked
                $result.LogIgnored | Should -Be $firewallProfile.LogIgnored
                $result.DisabledInterfaceAliases | Should -Be $firewallProfile.DisabledInterfaceAliases
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetFirewallProfile -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_FirewallProfile\Set-TargetResource' -Tag 'Set' {
    BeforeDiscovery {
        # Load the parameter List from the data file
        $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $resourceData = Import-LocalizedData `
            -BaseDirectory (Join-Path -Path $moduleRoot -ChildPath 'source\DscResources\DSC_FirewallProfile') `
            -FileName 'DSC_FirewallProfile.data.psd1'

        $parameterList = $resourceData.ParameterList

        $gpoTypeParameters = $parameterList | Where-Object -FilterScript {
            $_.Name -in @(
                'AllowInboundRules'
                'AllowLocalFirewallRules'
                'AllowLocalIPsecRules'
                'AllowUnicastResponseToMulticast'
                'AllowUserApps'
                'AllowUserPorts'
                'Enabled'
                'EnableStealthModeForIPsec'
                'LogAllowed'
                'LogBlocked'
                'LogIgnored'
                'NotifyOnListen'
            )
        }

        $actionTypeParameters = $parameterList | Where-Object -FilterScript {
            $_.Name -in @(
                'DefaultInboundAction'
                'DefaultOutboundAction'
            )
        }
    }

    BeforeAll {
        $script:firewallProfile = @{
            Name                            = 'Private'
            Enabled                         = 'False'
            DefaultInboundAction            = 'Block'
            DefaultOutboundAction           = 'Block'
            AllowInboundRules               = 'False'
            AllowLocalFirewallRules         = 'False'
            AllowLocalIPsecRules            = 'False'
            AllowUserApps                   = 'False'
            AllowUserPorts                  = 'False'
            AllowUnicastResponseToMulticast = 'False'
            NotifyOnListen                  = 'False'
            EnableStealthModeForIPsec       = 'False'
            LogFileName                     = '%systemroot%\system32\LogFiles\Firewall\pfirewall.log'
            LogMaxSizeKilobytes             = 32767
            LogAllowed                      = 'False'
            LogBlocked                      = 'False'
            LogIgnored                      = 'False'
            DisabledInterfaceAliases        = 'Ethernet'
        }

        Mock -CommandName Get-NetFirewallProfile -MockWith { $firewallProfile }
    }

    Context 'Firewall Profile all parameters are the same' {
        BeforeAll {
            Mock -CommandName Set-NetFirewallProfile
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                firewallProfile = $firewallProfile
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $firewallProfile.Clone()

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetFirewallProfile -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetFirewallProfile -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Firewall Profile <Name> is different' -ForEach $gpoTypeParameters {
        BeforeAll {
            Mock -CommandName Set-NetFirewallProfile
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                firewallProfile = $firewallProfile
                Name            = $Name
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $firewallProfile.Clone()
                $setTargetResourceParameters.$Name = 'True'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetFirewallProfile -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetFirewallProfile -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Firewall Profile <Name> is different' -ForEach $actionTypeParameters {
        BeforeAll {
            Mock -CommandName Set-NetFirewallProfile
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                firewallProfile = $firewallProfile
                Name            = $Name
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $firewallProfile.Clone()
                $setTargetResourceParameters.$Name = 'Allow'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetFirewallProfile -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetFirewallProfile -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Firewall Profile LogFileName is different' {
        BeforeAll {
            Mock -CommandName Set-NetFirewallProfile
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                firewallProfile = $firewallProfile
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $firewallProfile.Clone()
                $setTargetResourceParameters.LogFileName = 'c:\differentfile.txt'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetFirewallProfile -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetFirewallProfile -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Firewall Profile DisabledInterfaceAliases is different' {
        BeforeAll {
            Mock -CommandName Set-NetFirewallProfile
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                firewallProfile = $firewallProfile
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $firewallProfile.Clone()
                $setTargetResourceParameters.DisabledInterfaceAliases = 'DifferentInterface'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetFirewallProfile -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetFirewallProfile -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_FirewallProfile\Test-TargetResource' -Tag 'Test' {
    BeforeDiscovery {
        # Load the parameter List from the data file
        $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $resourceData = Import-LocalizedData `
            -BaseDirectory (Join-Path -Path $moduleRoot -ChildPath 'source\DscResources\DSC_FirewallProfile') `
            -FileName 'DSC_FirewallProfile.data.psd1'

        $parameterList = $resourceData.ParameterList

        $gpoTypeParameters = $parameterList | Where-Object -FilterScript {
            $_.Name -in @(
                'AllowInboundRules'
                'AllowLocalFirewallRules'
                'AllowLocalIPsecRules'
                'AllowUnicastResponseToMulticast'
                'AllowUserApps'
                'AllowUserPorts'
                'Enabled'
                'EnableStealthModeForIPsec'
                'LogAllowed'
                'LogBlocked'
                'LogIgnored'
                'NotifyOnListen'
            )
        }

        $actionTypeParameters = $parameterList | Where-Object -FilterScript {
            $_.Name -in @(
                'DefaultInboundAction'
                'DefaultOutboundAction'
            )
        }
    }

    BeforeAll {
        $script:firewallProfile = @{
            Name                            = 'Private'
            Enabled                         = 'False'
            DefaultInboundAction            = 'Block'
            DefaultOutboundAction           = 'Block'
            AllowInboundRules               = 'False'
            AllowLocalFirewallRules         = 'False'
            AllowLocalIPsecRules            = 'False'
            AllowUserApps                   = 'False'
            AllowUserPorts                  = 'False'
            AllowUnicastResponseToMulticast = 'False'
            NotifyOnListen                  = 'False'
            EnableStealthModeForIPsec       = 'False'
            LogFileName                     = '%systemroot%\system32\LogFiles\Firewall\pfirewall.log'
            LogMaxSizeKilobytes             = 32767
            LogAllowed                      = 'False'
            LogBlocked                      = 'False'
            LogIgnored                      = 'False'
            DisabledInterfaceAliases        = 'Ethernet'
        }

        Mock -CommandName Get-NetFirewallProfile -MockWith { $firewallProfile }
    }

    Context 'Firewall Profile all parameters are the same' {
        It 'Should return true' {
            InModuleScope -Parameters @{
                firewallProfile = $firewallProfile
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $firewallProfile.Clone()
                Test-TargetResource @testTargetResourceParameters | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetFirewallProfile -Exactly -Times 1 -Scope Context
        }
    }


    Context 'Firewall Profile <Name> is different' -ForEach $gpoTypeParameters {
        It 'Should return false' {
            InModuleScope -Parameters @{
                firewallProfile = $firewallProfile
                Name            = $Name
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $firewallProfile.Clone()
                $testTargetResourceParameters.$Name = 'True'

                Test-TargetResource @testTargetResourceParameters | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetFirewallProfile -Exactly -Times 1 -Scope Context
        }
    }


    Context 'Firewall Profile <Name> is different' -ForEach $actionTypeParameters {
        It 'Should return false' {
            InModuleScope -Parameters @{
                firewallProfile = $firewallProfile
                Name            = $Name
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $firewallProfile.Clone()
                $testTargetResourceParameters.$Name = 'Allow'

                Test-TargetResource @testTargetResourceParameters | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetFirewallProfile -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Firewall Profile LogFileName is different' {
        It 'Should return false' {
            InModuleScope -Parameters @{
                firewallProfile = $firewallProfile
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $firewallProfile.Clone()
                $testTargetResourceParameters.LogFileName = 'c:\differentfile.txt'

                Test-TargetResource @testTargetResourceParameters | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetFirewallProfile -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Firewall Profile DisabledInterfaceAliases is different' {
        It 'Should return false' {
            InModuleScope -Parameters @{
                firewallProfile = $firewallProfile
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $firewallProfile.Clone()
                $testTargetResourceParameters.DisabledInterfaceAliases = 'DifferentInterface'

                Test-TargetResource @testTargetResourceParameters | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetFirewallProfile -Exactly -Times 1 -Scope Context
        }
    }
}
