$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetAdapterRss'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {

        $TestRssEnabled = @{
            Name    = 'Ethernet'
            Enabled = $true
        }

        $TestRssDisabled = @{
            Name    = 'Ethernet'
            Enabled = $false
        }

        $TestAdapterNotFound = @{
            Name    = 'Ethe'
            Enabled = $true
        }

        Describe 'MSFT_NetAdapterRss\Get-TargetResource' -Tag 'Get' {
            Context 'Adapter exist and RSS is enabled' {
                Mock Get-NetAdapterRss -Verbose -MockWith { @{ Enabled = $true } }

                It 'Should return the RSS Enabled' {
                    $result = Get-TargetResource @TestRssEnabled
                    $result.Enabled | Should -Be $TestRSSEnabled.Enabled
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                }
            }

            Context 'Adapter exist and RSS is disabled' {
                Mock -CommandName Get-NetAdapterRSS -MockWith {
                    @{ Enabled = $TestRSSDisabled.Enabled}
                }

                It 'Should return the RSS Enabled' {
                    $result = Get-TargetResource @TestRSSDisabled
                    $result.Enabled | Should -Be $TestRSSDisabled.Enabled
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                }
            }
            Context 'Adapter does not exist' {

                Mock -CommandName Get-NetAdapterRss -MockWith { throw 'Network adapter not found' }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                It 'Should throw an exception' {
                    { Get-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRss -Exactly -Time 1
                }
            }

            Describe 'MSFT_NetAdapterRss\Set-TargetResource' -Tag 'Set' {

                Context 'Adapter exist, RSS is enabled, no action required' {
                    Mock -CommandName Get-NetAdapterRSS -MockWith {
                        @{ Enabled = $TestRSSEnabled.Enabled}
                    }
                    Mock -CommandName Set-NetAdapterRSS

                    It 'Should not throw an exception' {
                        { Set-TargetResource @TestRSSEnabled } | Should -Not -Throw
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                        Assert-MockCalled -CommandName Set-NetAdapterRSS -Exactly -Time 0
                    }
                }

                Context 'Adapter exist, RSS is enabled, should be disabled' {
                    Mock -CommandName Get-NetAdapterRSS -MockWith {
                        @{ Enabled = $TestRSSEnabled.Enabled }
                    }
                    Mock -CommandName Set-NetAdapterRSS

                    It 'Should not throw an exception' {
                        { Set-TargetResource @TestRSSDisabled } | Should -Not -Throw
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                        Assert-MockCalled -CommandName Set-NetAdapterRSS -Exactly -Time 1
                    }
                }

                Context 'Adapter exist, RSS is disabled, no action required' {
                    Mock -CommandName Get-NetAdapterRSS -MockWith {
                        @{ Enabled = $TestRSSDisabled.Enabled}
                    }
                    Mock -CommandName Set-NetAdapterRSS

                    It 'Should not throw an exception' {
                        { Set-TargetResource @TestRSSDisabled } | Should -Not -Throw
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                        Assert-MockCalled -CommandName Set-NetAdapterRSS -Exactly -Time 0
                    }
                }

                Context 'Adapter exist, RSS is disabled, should be enabled.' {
                    Mock -CommandName Get-NetAdapterRSS -MockWith {
                        @{ Enabled = $TestRSSDisabled.Enabled}
                    }
                    Mock -CommandName Set-NetAdapterRSS

                    It 'Should not throw an exception' {
                        { Set-TargetResource @TestRSSEnabled } | Should -Not -Throw
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                        Assert-MockCalled -CommandName Set-NetAdapterRSS -Exactly -Time 1
                    }
                }

                # Adapter
                Context 'Adapter does not exist' {
                    Mock -CommandName Get-NetAdapterRSS -MockWith { throw 'Network adapter not found' }

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.NetAdapterNotFoundMessage)

                    It 'Should throw an exception' {
                        { Set-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                    }
                }

            }

            Describe 'MSFT_NetAdapterRss\Test-TargetResource' -Tag 'Test' {
                # All
                Context 'Adapter exist, RSS is enabled, no action required' {
                    Mock -CommandName Get-NetAdapterRSS -MockWith {
                        @{ Enabled = $TestRSSEnabled.Enabled}
                    }

                    It 'Should return true' {
                        Test-TargetResource @TestRSSEnabled | Should -Be $true
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                    }
                }

                Context 'Adapter exist, RSS is enabled, should be disabled' {
                    Mock -CommandName Get-NetAdapterRSS -MockWith {
                        @{ Enabled = $TestRSSEnabled.Enabled}
                    }

                    It 'Should return false' {
                        Test-TargetResource @TestRSSDisabled | Should -Be $false
                    }

                    it 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                    }
                }

                Context 'Adapter exist, RSS is disabled, no action required' {
                    Mock -CommandName Get-NetAdapterRSS -MockWith {
                        @{ Enabled = $TestRSSDisabled.Enabled}
                    }

                    It 'Should return true' {
                        Test-TargetResource @TestRSSDisabled | Should -Be $true
                    }

                    it 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                    }
                }

                Context 'Adapter exist, RSS is disabled, should be enabled.' {
                    Mock -CommandName Get-NetAdapterRSS -MockWith {
                        @{ Enabled = $TestRSSDisabled.Enabled}
                    }

                    It 'Should return false' {
                        Test-TargetResource @TestRSSEnabled | Should -Be $false
                    }

                    it 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                    }
                }

                # Adapter
                Context 'Adapter does not exist' {
                    Mock -CommandName Get-NetAdapterRSS -MockWith { throw 'Network adapter not found' }

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.NetAdapterNotFoundMessage)

                    It 'Should throw an exception' {
                        { Test-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
                    }

                    It 'Should call all mocks' {
                        Assert-MockCalled -CommandName Get-NetAdapterRSS -Exactly -Time 1
                    }
                }
            }
        }
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
