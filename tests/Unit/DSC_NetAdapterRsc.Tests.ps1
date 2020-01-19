$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetAdapterRsc'

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
        $TestAllRscEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'All'
            State    = $true
        }

        $TestAllRscDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'All'
            State    = $false
        }

        $TestIPv4RscEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv4'
            State    = $true
        }

        $TestIPv4RscDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv4'
            State    = $false
        }

        $TestIPv6RscEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv6'
            State    = $true
        }

        $TestIPv6RscDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv6'
            State    = $false
        }

        $TestAdapterNotFound = @{
            Name     = 'Eth'
            Protocol = 'IPv4'
            State    = $true
        }

        Describe 'DSC_NetAdapterRsc\Get-TargetResource' -Tag 'Get' {
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

        Describe 'DSC_NetAdapterRsc\Set-TargetResource' -Tag 'Set' {
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

        Describe 'DSC_NetAdapterRsc\Test-TargetResource' -Tag 'Test' {
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
                    @{IPv4Enabled   = $TestAllRscDisabled.State
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
                    @{ IPv4Enabled  = $TestAllRscDisabled.State
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
    Invoke-TestCleanup
}
