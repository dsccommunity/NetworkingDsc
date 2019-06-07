$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetAdapterLso'

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
        $testV1IPv4LsoEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'V1IPv4'
            State    = $true
        }

        $testV1IPv4LsoDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'V1IPv4'
            State    = $false
        }

        $testIPv4LsoEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv4'
            State    = $true
        }

        $testIPv4LsoDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv4'
            State    = $false
        }

        $testIPv6LsoEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv6'
            State    = $true
        }

        $testIPv6LsoDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv6'
            State    = $false
        }

        $testAdapterNotFound = @{
            Name     = 'Eth'
            Protocol = 'IPv4'
            State    = $true
        }


        Describe 'MSFT_NetAdapterLso\Get-TargetResource' -Tag 'Get' {
            Context 'Adapter exist and LSO for V1IPv4 is enabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ V1IPv4Enabled = $testV1IPv4LsoEnabled.State }
                }

                It 'Should return the LSO state of V1IPv4' {
                    $result = Get-TargetResource @testV1IPv4LsoEnabled
                    $result.State | Should -Be $testV1IPv4LsoEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist and LSO for V1IPv4 is disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ V1IPv4Enabled = $testV1IPv4LsoDisabled.State }
                }

                It 'Should return the LSO state of V1IPv4' {
                    $result = Get-TargetResource @testV1IPv4LsoDisabled
                    $result.State | Should -Be $testV1IPv4LsoDisabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist and LSO for IPv4 is enabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv4Enabled = $testIPv4LsoEnabled.State }
                }

                It 'Should return the LSO state of IPv4' {
                    $result = Get-TargetResource @testIPv4LsoEnabled
                    $result.State | Should -Be $testIPv4LsoEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist and LSO for IPv4 is disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv4Enabled = $testIPv4LsoDisabled.State }
                }

                It 'Should return the LSO state of IPv4' {
                    $result = Get-TargetResource @testIPv4LsoDisabled
                    $result.State | Should -Be $testIPv4LsoDisabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist and LSO for IPv6 is enabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv6Enabled = $testIPv6LsoEnabled.State }
                }

                It 'Should return the LSO state of IPv6' {
                    $result = Get-TargetResource @testIPv6LsoEnabled
                    $result.State | Should -Be $testIPv6LsoEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist and LSO for IPv6 is disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv6Enabled = $testIPv6LsoDisabled.State }
                }

                It 'Should return the LSO state of IPv6' {
                    $result = Get-TargetResource @testIPv6LsoDisabled
                    $result.State | Should -Be $testIPv6LsoDisabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterLso -MockWith { throw 'Network adapter not found' }

                It 'Should throw the correct exception' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.NetAdapterNotFoundMessage)

                    { Get-TargetResource @testAdapterNotFound } | Should -Throw $errorRecord
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_NetAdapterLso\Set-TargetResource' -Tag 'Set' {
            # V1IPv4
            Context 'Adapter exist, LSO is enabled for V1IPv4, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ V1IPv4Enabled = $testV1IPv4LsoEnabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testV1IPv4LsoEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 0
                }
            }

            Context 'Adapter exist, LSO is enabled for V1IPv4, should be disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ V1IPv4Enabled = $testV1IPv4LsoEnabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testV1IPv4LsoDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is disabled for V1IPv4, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ V1IPv4Enabled = $testV1IPv4LsoDisabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testV1IPv4LsoDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 0
                }
            }

            Context 'Adapter exist, LSO is disabled for V1IPv4, should be enabled.' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ V1IPv4Enabled = $testV1IPv4LsoDisabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testV1IPv4LsoEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 1
                }
            }

            # IPv4
            Context 'Adapter exist, LSO is enabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv4Enabled = $testIPv4LsoEnabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testIPv4LsoEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 0
                }
            }

            Context 'Adapter exist, LSO is enabled for IPv4, should be disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv4Enabled = $testIPv4LsoEnabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testIPv4LsoDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is disabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv4Enabled = $testIPv4LsoDisabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testIPv4LsoDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 0
                }
            }

            Context 'Adapter exist, LSO is disabled for IPv4, should be enabled.' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv4Enabled = $testIPv4LsoDisabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testIPv4LsoEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 1
                }
            }

            # IPv6
            Context 'Adapter exist, LSO is enabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv6Enabled = $testIPv6LsoEnabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testIPv6LsoEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 0
                }
            }

            Context 'Adapter exist, LSO is enabled for IPv6, should be disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv6Enabled = $testIPv6LsoEnabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testIPv6LsoDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is disabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv6Enabled = $testIPv6LsoDisabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testIPv6LsoDisabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 0
                }
            }

            Context 'Adapter exist, LSO is disabled for IPv6, should be enabled.' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv6Enabled = $testIPv6LsoDisabled.State }
                }
                Mock -CommandName Set-NetAdapterLso

                It 'Should not throw an exception' {
                    { Set-TargetResource @testIPv6LsoEnabled } | Should -Not -Throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterLso -Exactly -Times 1
                }
            }

            # Adapter
            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterLso -MockWith { throw 'Network adapter not found' }

                It 'Should throw the correct exception' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.NetAdapterNotFoundMessage)

                    { Set-TargetResource @testAdapterNotFound } | Should -Throw $errorRecord
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

        }

        Describe 'MSFT_NetAdapterLso\Test-TargetResource' -Tag 'Test' {
            # V1IPv4
            Context 'Adapter exist, LSO is enabled for V1IPv4, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ V1IPv4Enabled = $testV1IPv4LsoEnabled.State }
                }

                It 'Should return true' {
                    Test-TargetResource @testV1IPv4LsoEnabled | Should -Be $true
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is enabled for V1IPv4, should be disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ V1IPv4Enabled = $testV1IPv4LsoEnabled.State }
                }

                It 'Should return false' {
                    Test-TargetResource @testV1IPv4LsoDisabled | Should -Be $false
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is disabled for V1IPv4, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ V1IPv4Enabled = $testV1IPv4LsoDisabled.State }
                }

                It 'Should return true' {
                    Test-TargetResource @testV1IPv4LsoDisabled | Should -Be $true
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is disabled for V1IPv4, should be enabled.' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ V1IPv4Enabled = $testV1IPv4LsoDisabled.State }
                }

                It 'Should return false' {
                    Test-TargetResource @testV1IPv4LsoEnabled | Should -Be $false
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            # IPv4
            Context 'Adapter exist, LSO is enabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv4Enabled = $testIPv4LsoEnabled.State }
                }

                It 'Should return true' {
                    Test-TargetResource @testIPv4LsoEnabled | Should -Be $true
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is enabled for IPv4, should be disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv4Enabled = $testIPv4LsoEnabled.State }
                }

                It 'Should return false' {
                    Test-TargetResource @testIPv4LsoDisabled | Should -Be $false
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is disabled for IPv4, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv4Enabled = $testIPv4LsoDisabled.State }
                }

                It 'Should return true' {
                    Test-TargetResource @testIPv4LsoDisabled | Should -Be $true
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is disabled for IPv4, should be enabled.' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv4Enabled = $testIPv4LsoDisabled.State }
                }

                It 'Should return false' {
                    Test-TargetResource @testIPv4LsoEnabled | Should -Be $false
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            # IPv6
            Context 'Adapter exist, LSO is enabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv6Enabled = $testIPv6LsoEnabled.State }
                }

                It 'Should return true' {
                    Test-TargetResource @testIPv6LsoEnabled | Should -Be $true
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is enabled for IPv6, should be disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv6Enabled = $testIPv6LsoEnabled.State }
                }

                It 'Should return false' {
                    Test-TargetResource @testIPv6LsoDisabled | Should -Be $false
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is disabled for IPv6, no action required' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv6Enabled = $testIPv6LsoDisabled.State }
                }

                It 'Should return true' {
                    Test-TargetResource @testIPv6LsoDisabled | Should -Be $true
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            Context 'Adapter exist, LSO is disabled for IPv6, should be enabled.' {
                Mock -CommandName Get-NetAdapterLso -MockWith {
                    @{ IPv6Enabled = $testIPv6LsoDisabled.State }
                }

                It 'Should return false' {
                    Test-TargetResource @testIPv6LsoEnabled | Should -Be $false
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
                }
            }

            # Adapter
            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterLso -MockWith { throw 'Network adapter not found' }

                It 'Should throw the correct exception' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.NetAdapterNotFoundMessage)

                    { Test-TargetResource @testAdapterNotFound } | Should -Throw $errorRecord
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly -Times 1
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
