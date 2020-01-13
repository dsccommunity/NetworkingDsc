$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_DnsClientGlobalSetting'

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
        $dnsClientGlobalSettings = [PSObject] @{
            SuffixSearchList = 'contoso.com'
            DevolutionLevel  = 1
            UseDevolution    = $true
        }

        $dnsClientGlobalMultiSuffixSettings = [PSObject]@{
            SuffixSearchList = @('fabrikam.com', 'fourthcoffee.com')
            DevolutionLevel  = 1
            UseDevolution    = $true
        }

        $dnsClientGlobalEmptyArraySuffixSettings = [PSObject]@{
            SuffixSearchList = @()
            DevolutionLevel  = 1
            UseDevolution    = $true
        }

        $dnsClientGlobalEmptyStringSuffixSettings = [PSObject]@{
            SuffixSearchList = ''
            DevolutionLevel  = 1
            UseDevolution    = $true
        }

        $dnsClientGlobalSettingsSplat = [PSObject]@{
            IsSingleInstance = 'Yes'
            SuffixSearchList = $dnsClientGlobalSettings.SuffixSearchList
            DevolutionLevel  = $dnsClientGlobalSettings.DevolutionLevel
            UseDevolution    = $dnsClientGlobalSettings.UseDevolution
        }

        Describe 'DSC_DnsClientGlobalSetting\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Get-DnsClientGlobalSetting -MockWith { $dnsClientGlobalSettings }
            }

            Context 'DNS Client Global Settings Exists' {
                It 'Should return correct DNS Client Global Settings values' {
                    $getTargetResourceParameters = Get-TargetResource -IsSingleInstance 'Yes'
                    $getTargetResourceParameters.SuffixSearchList | Should -Be $dnsClientGlobalSettings.SuffixSearchList
                    $getTargetResourceParameters.DevolutionLevel | Should -Be $dnsClientGlobalSettings.DevolutionLevel
                    $getTargetResourceParameters.UseDevolution | Should -Be $dnsClientGlobalSettings.UseDevolution
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-DnsClientGlobalSetting -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_DnsClientGlobalSetting\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Get-DnsClientGlobalSetting -MockWith { $dnsClientGlobalSettings }
            }

            Context 'DNS Client Global Settings all parameters are the same' {
                Mock -CommandName Set-DnsClientGlobalSetting

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    Assert-MockCalled -commandName Set-DnsClientGlobalSetting -Exactly -Times 0
                }
            }

            Context 'DNS Client Global Settings SuffixSearchList is different' {
                Mock -CommandName Set-DnsClientGlobalSetting

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $setTargetResourceParameters.SuffixSearchList = 'fabrikam.com'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    Assert-MockCalled -commandName Set-DnsClientGlobalSetting -Exactly -Times 1
                }
            }

            Context 'DNS Client Global Settings SuffixSearchList Array is different' {
                $suffixSearchListArray = @('fabrikam.com', 'fourthcoffee.com')

                $setDnsClientGlobalMockParameterFilter = {
                    (Compare-Object -ReferenceObject $suffixSearchList -DifferenceObject $suffixSearchListArray -SyncWindow 0).Length -eq 0
                }

                Mock -CommandName Set-DnsClientGlobalSetting -ParameterFilter $setDnsClientGlobalMockParameterFilter

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $setTargetResourceParameters.SuffixSearchList = $suffixSearchListArray
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    Assert-MockCalled -commandName Set-DnsClientGlobalSetting -ParameterFilter $setDnsClientGlobalMockParameterFilter -Exactly -Times 1
                }
            }

            Context 'DNS Client Global Settings DevolutionLevel is different' {
                Mock -CommandName Set-DnsClientGlobalSetting

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $setTargetResourceParameters.DevolutionLevel = $setTargetResourceParameters.DevolutionLevel + 1
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    Assert-MockCalled -commandName Set-DnsClientGlobalSetting -Exactly -Times 1
                }
            }

            Context 'DNS Client Global Settings UseDevolution is different' {
                Mock -CommandName Set-DnsClientGlobalSetting

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $setTargetResourceParameters.UseDevolution = -not $setTargetResourceParameters.UseDevolution
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    Assert-MockCalled -commandName Set-DnsClientGlobalSetting -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_DnsClientGlobalSetting\Test-TargetResource' -Tag 'Test' {
            Context 'Single suffix is in the search list' {
                BeforeEach {
                    Mock -CommandName Get-DnsClientGlobalSetting -MockWith { $dnsClientGlobalSettings }
                }

                Context 'DNS Client Global Settings all parameters are the same' {
                    It 'Should return true' {
                        $testTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        Test-TargetResource @testTargetResourceParameters | Should -Be $true
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    }
                }

                Context 'DNS Client Global Settings SuffixSearchList is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = 'fabrikam.com'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    }
                }

                Context 'DNS Client Global Settings DevolutionLevel is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $testTargetResourceParameters.DevolutionLevel = $testTargetResourceParameters.DevolutionLevel + 1
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    }
                }

                Context 'DNS Client Global Settings UseDevolution is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $testTargetResourceParameters.UseDevolution = -not $testTargetResourceParameters.UseDevolution
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    }
                }
            }

            Context 'Mulitple suffixes are in the search list' {
                BeforeEach {
                    Mock -CommandName Get-DnsClientGlobalSetting -MockWith { $dnsClientGlobalMultiSuffixSettings }
                }

                Context 'DNS Client Global Settings SuffixSearchList Array is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = @('fabrikam.com', 'contoso.com')
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    }
                }

                Context 'DNS Client Global Settings SuffixSearchList Array Order is same' {
                    It 'Should return true' {
                        $testTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = @('fabrikam.com', 'fourthcoffee.com')
                        Test-TargetResource @testTargetResourceParameters | Should -Be $true
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    }
                }

                Context 'DNS Client Global Settings SuffixSearchList Array Order is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = @('fourthcoffee.com', 'fabrikam.com')
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    }
                }
            }

            Context 'When the search list is an empty array' {
                BeforeEach {
                    Mock -CommandName Get-DnsClientGlobalSetting -MockWith { $dnsClientGlobalEmptyArraySuffixSettings }
                }

                Context 'When the DNS Client Global Settings SuffixSearchList Array is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = @('fabrikam.com')
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    }
                }

                Context 'When the DNS Client Global Settings SuffixSearchList is same' {
                    It 'Should return true' {
                        $testTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = @()
                        Test-TargetResource @testTargetResourceParameters | Should -Be $true
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    }
                }
            }

            Context 'When the search list is an empty string' {
                BeforeEach {
                    Mock -CommandName Get-DnsClientGlobalSetting -MockWith { $dnsClientGlobalEmptyStringSuffixSettings }
                }

                Context 'When the DNS Client Global Settings SuffixSearchList Array is different' {
                    It 'Should return false' {
                        $testTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = @('fabrikam.com')
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
                    }
                }

                Context 'When the DNS Client Global Settings SuffixSearchList is same' {
                    It 'Should return true' {
                        $testTargetResourceParameters = $dnsClientGlobalSettingsSplat.Clone()
                        $testTargetResourceParameters.SuffixSearchList = @()
                        Test-TargetResource @testTargetResourceParameters | Should -Be $true
                    }

                    It 'Should call expected Mocks' {
                        Assert-MockCalled -commandName Get-DnsClientGlobalSetting -Exactly -Times 1
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
