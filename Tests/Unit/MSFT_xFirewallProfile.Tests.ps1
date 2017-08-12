$script:DSCModuleName = 'xNetworking'
$script:DSCResourceName = 'MSFT_xFirewallProfile'

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

        Describe 'MSFT_xDnsClientGlobalSetting\Get-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetFirewallProfile -MockWith { $firewallProfile }
            }

            Context 'Firewall Profile Exists' {
                It 'Should return correct DNS Client Global Settings values' {
                    $getTargetResourceParameters = Get-TargetResource -Name 'Private'
                    $getTargetResourceParameters.Name                            | Should Be $firewallProfile.Name
                    $getTargetResourceParameters.Enabled                         | Should Be $firewallProfile.Enabled
                    $getTargetResourceParameters.DefaultInboundAction            | Should Be $firewallProfile.DefaultInboundAction
                    $getTargetResourceParameters.DefaultOutboundAction           | Should Be $firewallProfile.DefaultOutboundAction
                    $getTargetResourceParameters.AllowInboundRules               | Should Be $firewallProfile.AllowInboundRules
                    $getTargetResourceParameters.AllowLocalFirewallRules         | Should Be $firewallProfile.AllowLocalFirewallRules
                    $getTargetResourceParameters.AllowLocalIPsecRules            | Should Be $firewallProfile.AllowLocalIPsecRules
                    $getTargetResourceParameters.AllowUserApps                   | Should Be $firewallProfile.AllowUserApps
                    $getTargetResourceParameters.AllowUserPorts                  | Should Be $firewallProfile.AllowUserPorts
                    $getTargetResourceParameters.AllowUnicastResponseToMulticast | Should Be $firewallProfile.AllowUnicastResponseToMulticast
                    $getTargetResourceParameters.NotifyOnListen                  | Should Be $firewallProfile.NotifyOnListen
                    $getTargetResourceParameters.EnableStealthModeForIPsec       | Should Be $firewallProfile.EnableStealthModeForIPsec
                    $getTargetResourceParameters.LogFileName                     | Should Be $firewallProfile.LogFileName
                    $getTargetResourceParameters.LogMaxSizeKilobytes             | Should Be $firewallProfile.LogMaxSizeKilobytes
                    $getTargetResourceParameters.LogAllowed                      | Should Be $firewallProfile.LogAllowed
                    $getTargetResourceParameters.LogBlocked                      | Should Be $firewallProfile.LogBlocked
                    $getTargetResourceParameters.LogIgnored                      | Should Be $firewallProfile.LogIgnored
                    $getTargetResourceParameters.DisabledInterfaceAliases        | Should Be $firewallProfile.DisabledInterfaceAliases
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetFirewallProfile -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_xDnsClientGlobalSetting\Set-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetFirewallProfile -MockWith { $firewallProfile }
            }

            Context 'DNS Client Global Settings all parameters are the same' {
                Mock -CommandName Set-NetFirewallProfile

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $firewallProfileSplat.Clone()
                        Set-TargetResource @setTargetResourceParameters
                    } | Should Not Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    Assert-MockCalled -commandName Set-NetFirewallProfile -Exactly -Times 0
                }
            }

            Context 'DNS Client Global Settings SuffixSearchList is different' {
                Mock -CommandName Set-NetFirewallProfile

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $firewallProfileSplat.Clone()
                        $setTargetResourceParameters.SuffixSearchList = 'fabrikam.com'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should Not Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    Assert-MockCalled -commandName Set-NetFirewallProfile -Exactly -Times 1
                }
            }

            Context 'DNS Client Global Settings SuffixSearchList Array is different' {
                $suffixSearchListArray = @('fabrikam.com', 'fourthcoffee.com')

                $setDnsClientGlobalMockParameterFilter = {
                    (Compare-Object -ReferenceObject $suffixSearchList -DifferenceObject $suffixSearchListArray -SyncWindow 0).Length -eq 0
                }

                Mock -CommandName Set-NetFirewallProfile -ParameterFilter $setDnsClientGlobalMockParameterFilter

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $firewallProfileSplat.Clone()
                        $setTargetResourceParameters.SuffixSearchList = $suffixSearchListArray
                        Set-TargetResource @setTargetResourceParameters
                    } | Should Not Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    Assert-MockCalled -commandName Set-NetFirewallProfile -ParameterFilter $setDnsClientGlobalMockParameterFilter -Exactly -Times 1
                }
            }

            Context 'DNS Client Global Settings DevolutionLevel is different' {
                Mock -CommandName Set-NetFirewallProfile

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $firewallProfileSplat.Clone()
                        $setTargetResourceParameters.DevolutionLevel = $setTargetResourceParameters.DevolutionLevel + 1
                        Set-TargetResource @setTargetResourceParameters
                    } | Should Not Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    Assert-MockCalled -commandName Set-NetFirewallProfile -Exactly -Times 1
                }
            }

            Context 'DNS Client Global Settings UseDevolution is different' {
                Mock -CommandName Set-NetFirewallProfile

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $firewallProfileSplat.Clone()
                        $setTargetResourceParameters.UseDevolution = -not $setTargetResourceParameters.UseDevolution
                        Set-TargetResource @setTargetResourceParameters
                    } | Should Not Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    Assert-MockCalled -commandName Set-NetFirewallProfile -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_xDnsClientGlobalSetting\Test-TargetResource' {
            Context 'Single suffix is in the search list' {
                BeforeEach {
                    Mock -CommandName Get-NetFirewallProfile -MockWith { $firewallProfile }
                }

                Context 'DNS Client Global Settings all parameters are the same' {
                    It 'Should return true' {
                        $testTargetResourceParameters = $firewallProfileSplat.Clone()
                        Test-TargetResource @testTargetResourceParameters | Should Be $True
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    }
                }

                Context 'DNS Client Global Settings SuffixSearchList is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $firewallProfileSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = 'fabrikam.com'
                        Test-TargetResource @testTargetResourceParameters | Should Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    }
                }

                Context 'DNS Client Global Settings DevolutionLevel is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $firewallProfileSplat.Clone()
                        $testTargetResourceParameters.DevolutionLevel = $testTargetResourceParameters.DevolutionLevel + 1
                        Test-TargetResource @testTargetResourceParameters | Should Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    }
                }

                Context 'DNS Client Global Settings UseDevolution is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $firewallProfileSplat.Clone()
                        $testTargetResourceParameters.UseDevolution = -not $testTargetResourceParameters.UseDevolution
                        Test-TargetResource @testTargetResourceParameters | Should Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    }
                }
            }

            Context 'Mulitple suffixes are in the search list' {
                BeforeEach {
                    Mock -CommandName Get-NetFirewallProfile -MockWith { $dnsClientGlobalMultiSuffixSettings }
                }

                Context 'DNS Client Global Settings SuffixSearchList Array is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $firewallProfileSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = @('fabrikam.com', 'contoso.com')
                        Test-TargetResource @testTargetResourceParameters | Should Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    }
                }

                Context 'DNS Client Global Settings SuffixSearchList Array Order is same' {
                    It 'Should return true' {
                        $testTargetResourceParameters = $firewallProfileSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = @('fabrikam.com', 'fourthcoffee.com')
                        Test-TargetResource @testTargetResourceParameters | Should Be $True
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
                    }
                }

                Context 'DNS Client Global Settings SuffixSearchList Array Order is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $firewallProfileSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = @('fourthcoffee.com', 'fabrikam.com')
                        Test-TargetResource @testTargetResourceParameters | Should Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-NetFirewallProfile -Exactly -Times 1
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
