$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_FirewallProfile'

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

# Load the parameter List from the data file
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$resourceData = Import-LocalizedData `
    -BaseDirectory (Join-Path -Path $moduleRoot -ChildPath 'source\DscResources\DSC_FirewallProfile') `
    -FileName 'DSC_FirewallProfile.data.psd1'

$script:parameterList = $resourceData.ParameterList

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        # Create the Mock Objects that will be used for running tests
        $firewallProfile = [PSObject] @{
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

        $firewallProfileSplat = [PSObject] @{
            Name                            = $firewallProfile.Name
            Enabled                         = $firewallProfile.Enabled
            DefaultInboundAction            = $firewallProfile.DefaultInboundAction
            DefaultOutboundAction           = $firewallProfile.DefaultOutboundAction
            AllowInboundRules               = $firewallProfile.AllowInboundRules
            AllowLocalFirewallRules         = $firewallProfile.AllowLocalFirewallRules
            AllowLocalIPsecRules            = $firewallProfile.AllowLocalIPsecRules
            AllowUserApps                   = $firewallProfile.AllowUserApps
            AllowUserPorts                  = $firewallProfile.AllowUserPorts
            AllowUnicastResponseToMulticast = $firewallProfile.AllowUnicastResponseToMulticast
            NotifyOnListen                  = $firewallProfile.NotifyOnListen
            EnableStealthModeForIPsec       = $firewallProfile.EnableStealthModeForIPsec
            LogFileName                     = $firewallProfile.LogFileName
            LogMaxSizeKilobytes             = $firewallProfile.LogMaxSizeKilobytes
            LogAllowed                      = $firewallProfile.LogAllowed
            LogBlocked                      = $firewallProfile.LogBlocked
            LogIgnored                      = $firewallProfile.LogIgnored
            DisabledInterfaceAliases        = $firewallProfile.DisabledInterfaceAliases
        }

        $gpoTypeParameters = $script:parameterList | Where-Object -FilterScript {
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
        $actionTypeParameters = $script:parameterList | Where-Object -FilterScript {
            $_.Name -in @(
                'DefaultInboundAction'
                'DefaultOutboundAction'
            )
        }

        Describe 'DSC_FirewallProfile\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Get-NetFirewallProfile -MockWith { $firewallProfile }
            }

            Context 'Firewall Profile Exists' {
                It 'Should return correct Firewall Profile values' {
                    $getTargetResourceParameters = Get-TargetResource -Name 'Private'
                    $getTargetResourceParameters.Name | Should -Be $firewallProfile.Name
                    $getTargetResourceParameters.Enabled | Should -Be $firewallProfile.Enabled
                    $getTargetResourceParameters.DefaultInboundAction | Should -Be $firewallProfile.DefaultInboundAction
                    $getTargetResourceParameters.DefaultOutboundAction | Should -Be $firewallProfile.DefaultOutboundAction
                    $getTargetResourceParameters.AllowInboundRules | Should -Be $firewallProfile.AllowInboundRules
                    $getTargetResourceParameters.AllowLocalFirewallRules | Should -Be $firewallProfile.AllowLocalFirewallRules
                    $getTargetResourceParameters.AllowLocalIPsecRules | Should -Be $firewallProfile.AllowLocalIPsecRules
                    $getTargetResourceParameters.AllowUserApps | Should -Be $firewallProfile.AllowUserApps
                    $getTargetResourceParameters.AllowUserPorts | Should -Be $firewallProfile.AllowUserPorts
                    $getTargetResourceParameters.AllowUnicastResponseToMulticast | Should -Be $firewallProfile.AllowUnicastResponseToMulticast
                    $getTargetResourceParameters.NotifyOnListen | Should -Be $firewallProfile.NotifyOnListen
                    $getTargetResourceParameters.EnableStealthModeForIPsec | Should -Be $firewallProfile.EnableStealthModeForIPsec
                    $getTargetResourceParameters.LogFileName | Should -Be $firewallProfile.LogFileName
                    $getTargetResourceParameters.LogMaxSizeKilobytes | Should -Be $firewallProfile.LogMaxSizeKilobytes
                    $getTargetResourceParameters.LogAllowed | Should -Be $firewallProfile.LogAllowed
                    $getTargetResourceParameters.LogBlocked | Should -Be $firewallProfile.LogBlocked
                    $getTargetResourceParameters.LogIgnored | Should -Be $firewallProfile.LogIgnored
                    $getTargetResourceParameters.DisabledInterfaceAliases | Should -Be $firewallProfile.DisabledInterfaceAliases
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetFirewallProfile -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_FirewallProfile\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Get-NetFirewallProfile -MockWith { $firewallProfile }
            }

            Context 'Firewall Profile all parameters are the same' {
                Mock -CommandName Set-NetFirewallProfile

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $firewallProfileSplat.Clone()
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    Assert-MockCalled -commandName Set-NetFirewallProfile -Exactly -Times 0
                }
            }

            foreach ($parameter in $gpoTypeParameters)
            {
                $parameterName = $parameter.Name
                Context "Firewall Profile $parameterName is different" {
                    Mock -CommandName Set-NetFirewallProfile

                    It 'Should not throw error' {
                        {
                            $setTargetResourceParameters = $firewallProfileSplat.Clone()
                            $setTargetResourceParameters.$parameterName = 'True'
                            Set-TargetResource @setTargetResourceParameters
                        } | Should -Not -Throw
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                        Assert-MockCalled -commandName Set-NetFirewallProfile -Exactly -Times 1
                    }
                }
            }

            foreach ($parameter in $actionTypeParameters)
            {
                $parameterName = $parameter.Name
                Context "Firewall Profile $parameterName is different" {
                    Mock -CommandName Set-NetFirewallProfile

                    It 'Should not throw error' {
                        {
                            $setTargetResourceParameters = $firewallProfileSplat.Clone()
                            $setTargetResourceParameters.$parameterName = 'Allow'
                            Set-TargetResource @setTargetResourceParameters
                        } | Should -Not -Throw
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                        Assert-MockCalled -commandName Set-NetFirewallProfile -Exactly -Times 1
                    }
                }
            }

            Context 'Firewall Profile LogFileName is different' {
                Mock -CommandName Set-NetFirewallProfile

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $firewallProfileSplat.Clone()
                        $setTargetResourceParameters.LogFileName = 'c:\differentfile.txt'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    Assert-MockCalled -commandName Set-NetFirewallProfile -Exactly -Times 1
                }
            }

            Context 'Firewall Profile DisabledInterfaceAliases is different' {
                Mock -CommandName Set-NetFirewallProfile

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $firewallProfileSplat.Clone()
                        $setTargetResourceParameters.DisabledInterfaceAliases = 'DifferentInterface'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    Assert-MockCalled -commandName Set-NetFirewallProfile -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_FirewallProfile\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Get-NetFirewallProfile -MockWith { $firewallProfile }
            }

            Context 'Firewall Profile all parameters are the same' {
                It 'Should return true' {
                    $testTargetResourceParameters = $firewallProfileSplat.Clone()
                    Test-TargetResource @testTargetResourceParameters | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                }
            }

            foreach ($parameter in $gpoTypeParameters)
            {
                $parameterName = $parameter.Name
                Context "Firewall Profile $parameterName is different" {
                    It 'Should return false' {
                        $testTargetResourceParameters = $firewallProfileSplat.Clone()
                        $testTargetResourceParameters.$parameterName = 'True'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    }
                }
            }

            foreach ($parameter in $actionTypeParameters)
            {
                $parameterName = $parameter.Name
                Context "Firewall Profile $parameterName is different" {
                    It 'Should return false' {
                        $testTargetResourceParameters = $firewallProfileSplat.Clone()
                        $testTargetResourceParameters.$parameterName = 'Allow'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    }
                }
            }

            Context 'Firewall Profile LogFileName is different' {
                It 'Should return false' {
                    $testTargetResourceParameters = $firewallProfileSplat.Clone()
                    $testTargetResourceParameters.LogFileName = 'c:\differentfile.txt'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $False
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                }
            }

            Context 'Firewall Profile DisabledInterfaceAliases is different' {
                It 'Should return false' {
                    $testTargetResourceParameters = $firewallProfileSplat.Clone()
                    $testTargetResourceParameters.DisabledInterfaceAliases = 'DifferentInterface'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $False
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
