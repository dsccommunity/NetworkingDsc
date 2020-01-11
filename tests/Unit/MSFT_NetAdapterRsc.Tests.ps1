$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetAdapterRsc'

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
        $TestAllRscEnabled = @{
            Name = 'Ethernet'
            Protocol = 'All'
            State = $true
        }

        $TestAllRscDisabled = @{
            Name = 'Ethernet'
            Protocol = 'All'
            State = $false
        }

        $TestIPv4RscEnabled = @{
            Name = 'Ethernet'
            Protocol = 'IPv4'
            State = $true
        }

        $TestIPv4RscDisabled = @{
            Name = 'Ethernet'
            Protocol = 'IPv4'
            State = $false
        }

        $TestIPv6RscEnabled = @{
            Name = 'Ethernet'
            Protocol = 'IPv6'
            State = $true
        }

        $TestIPv6RscDisabled = @{
            Name = 'Ethernet'
            Protocol = 'IPv6'
            State = $false
        }

        $TestAdapterNotFound = @{
            Name = 'Eth'
            Protocol = 'IPv4'
            State = $true
        }

        Describe 'MSFT_NetAdapterRsc\Get-TargetResource' -Tag 'Get' {
            Context 'Adapter exists and Rsc is enabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestAllRscEnabled.State
                        IPv6Enabled = $TestAllRscEnabled.State
                    }
                }

                It 'Should return the Rsc state' {
                    $result = Get-TargetResource @TestAllRscEnabled
                    $result.StateIPv4 | Should -Be $TestAllRscEnabled.State
                    $result.StateIPv6 | Should -Be $TestAllRscEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists and Rsc is disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestAllRscDisabled.State
                        IPv6Enabled = $TestAllRscDisabled.State
                    }
                }

                It 'Should return the Rsc state' {
                    $result = Get-TargetResource @TestAllRscDisabled
                    $result.StateIPv4 | Should -Be $TestAllRscDisabled.State
                    $result.StateIPv6 | Should -Be $TestAllRscDisabled.State

                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }


            Context 'Adapter exists and Rsc for IPv4 is enabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestIPv4RscEnabled.State
                    }
                }

                It 'Should return the Rsc state of IPv4' {
                    $result = Get-TargetResource @TestIPv4RscEnabled
                    $result.State | Should -Be $TestIPv4RscEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists and Rsc for IPv4 is disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestIPv4RscDisabled.State
                    }
                }

                It 'Should return the Rsc state of IPv4' {
                    $result = Get-TargetResource @TestIPv4RscDisabled
                    $result.State | Should -Be $TestIPv4RscDisabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists and Rsc for IPv6 is enabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv6Enabled = $TestIPv6RscEnabled.State
                    }
                }

                It 'Should return the Rsc state of IPv6' {
                    $result = Get-TargetResource @TestIPv6RscEnabled
                    $result.State | Should -Be $TestIPv6RscEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists and Rsc for IPv6 is disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv6Enabled = $TestIPv6RscDisabled.State
                    }
                }

                It 'Should return the Rsc state of IPv6' {
                    $result = Get-TargetResource @TestIPv6RscDisabled
                    $result.State | Should -Be $TestIPv6RscDisabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { throw 'Network adapter not found' }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                It 'Should throw an exception' {
                    { Get-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }
        }

        Describe 'MSFT_NetAdapterRsc\Set-TargetResource' -Tag 'Set' {
            # All
            Context 'Adapter exists, Rsc is enabled, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestAllRscEnabled.State
                        IPv6Enabled = $TestAllRscEnabled.State
                    }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestAllRscEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 0
                }
            }

            Context 'Adapter exists, Rsc is enabled, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestAllRscEnabled.State
                        IPv6Enabled = $TestAllRscEnabled.State
                    }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestAllRscDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 2
                }
            }

            Context 'Adapter exists, Rsc is disabled, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestAllRscDisabled.State
                        IPv6Enabled = $TestAllRscDisabled.State
                    }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestAllRscDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 0
                }
            }

            Context 'Adapter exists, Rsc is disabled, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestAllRscDisabled.State
                        IPv6Enabled = $TestAllRscDisabled.State
                    }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestAllRscEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 2
                }
            }

            Context 'Adapter exists, Rsc is disabled for IPv4, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestAllRscDisabled.State
                        IPv6Enabled = $TestAllRscEnabled.State
                    }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestAllRscEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is Enabled for IPv6, should be disabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestAllRscDisabled.State
                        IPv6Enabled = $TestAllRscEnabled.State
                    }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestAllRscDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 1
                }
            }

            # IPv4
            Context 'Adapter exists, Rsc is enabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv4Enabled = $TestIPv4RscEnabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv4RscEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 0
                }
            }

            Context 'Adapter exists, Rsc is enabled for IPv4, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv4Enabled = $TestIPv4RscEnabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv4RscDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is disabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv4Enabled = $TestIPv4RscDisabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv4RscDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 0
                }
            }

            Context 'Adapter exists, Rsc is disabled for IPv4, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv4Enabled = $TestIPv4RscDisabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv4RscEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 1
                }
            }

            # IPv6
            Context 'Adapter exists, Rsc is enabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv6Enabled = $TestIPv6RscEnabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv6RscEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 0
                }
            }

            Context 'Adapter exists, Rsc is enabled for IPv6, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv6Enabled = $TestIPv6RscEnabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv6RscDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is disabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv6Enabled = $TestIPv6RscDisabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv6RscDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 0
                }
            }

            Context 'Adapter exists, Rsc is disabled for IPv6, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv6Enabled = $TestIPv6RscDisabled.State }
                }
                Mock -CommandName Set-NetAdapterRsc

                It 'Should not throw an exception' {
                    { Set-TargetResource @TestIPv6RscEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                    Assert-MockCalled -CommandName Set-NetAdapterRsc -Exactly -Time 1
                }
            }

            # Adapter
            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { throw 'Network adapter not found' }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                It 'Should throw an exception' {
                    { Set-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

        }

        Describe 'MSFT_NetAdapterRsc\Test-TargetResource' -Tag 'Test' {
            # All
            Context 'Adapter exists, Rsc is enabled, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestAllRscEnabled.State
                        IPv6Enabled = $TestAllRscEnabled.State
                    }
                }

                It 'Should return true' {
                    Test-TargetResource @TestAllRscEnabled | Should -Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is enabled, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{
                        IPv4Enabled = $TestAllRscEnabled.State
                        IPv6Enabled = $TestAllRscEnabled.State
                    }
                }

                It 'Should return false' {
                    Test-TargetResource @TestAllRscDisabled | Should -Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is disabled, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{IPv4Enabled = $TestAllRscDisabled.State
                        IPv6Enabled = $TestAllRscDisabled.State
                    }
                }

                It 'Should return true' {
                    Test-TargetResource @TestAllRscDisabled | Should -Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is disabled, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv4Enabled = $TestAllRscDisabled.State
                        IPv6Enabled = $TestAllRscDisabled.State
                    }
                }

                It 'Should return false' {
                    Test-TargetResource @TestAllRscEnabled | Should -Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            # IPv4
            Context 'Adapter exists, Rsc is enabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv4Enabled = $TestIPv4RscEnabled.State }
                }

                It 'Should return true' {
                    Test-TargetResource @TestIPv4RscEnabled | Should -Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is enabled for IPv4, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv4Enabled = $TestIPv4RscEnabled.State }
                }

                It 'Should return false' {
                    Test-TargetResource @TestIPv4RscDisabled | Should -Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is disabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv4Enabled = $TestIPv4RscDisabled.State }
                }

                It 'Should return true' {
                    Test-TargetResource @TestIPv4RscDisabled | Should -Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is disabled for IPv4, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv4Enabled = $TestIPv4RscDisabled.State }
                }

                It 'Should return false' {
                    Test-TargetResource @TestIPv4RscEnabled | Should -Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            # IPv6
            Context 'Adapter exists, Rsc is enabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv6Enabled = $TestIPv6RscEnabled.State }
                }

                It 'Should return true' {
                    Test-TargetResource @TestIPv6RscEnabled | Should -Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is enabled for IPv6, should be disabled' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv6Enabled = $TestIPv6RscEnabled.State }
                }

                It 'Should return false' {
                    Test-TargetResource @TestIPv6RscDisabled | Should -Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is disabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv6Enabled = $TestIPv6RscDisabled.State }
                }

                It 'Should return true' {
                    Test-TargetResource @TestIPv6RscDisabled | Should -Be $true
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            Context 'Adapter exists, Rsc is disabled for IPv6, should be enabled.' {
                Mock -CommandName Get-NetAdapterRsc -MockWith {
                    @{ IPv6Enabled = $TestIPv6RscDisabled.State }
                }

                It 'Should return false' {
                    Test-TargetResource @TestIPv6RscEnabled | Should -Be $false
                }

                it 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
                }
            }

            # Adapter
            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterRsc -MockWith { throw 'Network adapter not found' }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundMessage)

                It 'Should throw an exception' {
                    { Test-TargetResource @TestAdapterNotFound } | Should -Throw $errorRecord
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRsc -Exactly -Time 1
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
