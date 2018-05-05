Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\NetworkingDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'NetworkingDsc' `
    -DSCResourceName 'MSFT_WeakHostReceive' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope MSFT_WeakHostReceive {

        # Create the Mock Objects that will be used for running tests
        $mockNetAdapter = [PSCustomObject] @{
            Name = 'Ethernet'
        }

        $testNetIPWeakHostReceiveEnabled = [PSObject]@{
            State          = 'Enabled'
            InterfaceAlias = $mockNetAdapter.Name
            AddressFamily  = 'IPv4'
        }

        $testNetIPWeakHostReceiveDisabled = [PSObject]@{
            State          = 'Disabled'
            InterfaceAlias = $mockNetAdapter.Name
            AddressFamily  = 'IPv4'
        }

        $mockNetIPWeakHostReceiveEnabled = [PSObject]@{
            WeakHostReceive = $testNetIPWeakHostReceiveEnabled.State
            InterfaceAlias  = $testNetIPWeakHostReceiveEnabled.Name
            AddressFamily   = $testNetIPWeakHostReceiveEnabled.AddressFamily
        }

        $mockNetIPWeakHostReceiveDisabled = [PSObject]@{
            WeakHostReceive = $testNetIPWeakHostReceiveDisabled.State
            InterfaceAlias  = $testNetIPWeakHostReceiveDisabled.Name
            AddressFamily   = $testNetIPWeakHostReceiveDisabled.AddressFamily
        }

        Describe 'MSFT_WeakHostReceive\Get-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            }

            Context 'Invoking with when Weak Host Receiving is enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostReceiveEnabled }

                It 'Should return Weak Host Receiving state of enabled' {
                    $Result = Get-TargetResource @testNetIPWeakHostReceiveEnabled
                    $Result.State          | Should -Be $testNetIPWeakHostReceiveEnabled.State
                    $Result.InterfaceAlias | Should -Be $testNetIPWeakHostReceiveEnabled.InterfaceAlias
                    $Result.AddressFamily  | Should -Be $testNetIPWeakHostReceiveEnabled.AddressFamily
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with when Weak Host Receiving is disabled' {
                Mock Get-NetIPInterface -MockWith { $mockNetIPWeakHostReceiveDisabled }

                It 'Should return Weak Host Receiving state of disabled' {
                    $Result = Get-TargetResource @testNetIPWeakHostReceiveDisabled
                    $Result.State          | Should -Be $testNetIPWeakHostReceiveDisabled.State
                    $Result.InterfaceAlias | Should -Be $testNetIPWeakHostReceiveDisabled.InterfaceAlias
                    $Result.AddressFamily  | Should -Be $testNetIPWeakHostReceiveDisabled.AddressFamily
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_WeakHostReceive\Set-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
                Mock -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostReceive -eq 'Enabled' }
                Mock -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostReceive -eq 'Disabled' }
            }

            Context 'Invoking with state enabled but Weak Host Receiving is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostReceiveDisabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPWeakHostReceiveEnabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostReceive -eq 'Enabled' } -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostReceive -eq 'Disabled' } -Exactly -Times 0
                }
            }

            Context 'invoking with state disabled and Weak Host Receiving is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostReceiveDisabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPWeakHostReceiveDisabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostReceive -eq 'Enabled' } -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostReceive -eq 'Disabled' } -Exactly -Times 1
                }
            }

            Context 'invoking with state enabled and Weak Host Receiving is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostReceiveEnabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPWeakHostReceiveEnabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostReceive -eq 'Enabled' } -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostReceive -eq 'Disabled' } -Exactly -Times 0
                }
            }

            Context 'invoking with state disabled but Weak Host Receiving is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostReceiveEnabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPWeakHostReceiveDisabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostReceive -eq 'Enabled' } -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostReceive -eq 'Disabled' } -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_WeakHostReceive\Test-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            }

            Context 'Invoking with state enabled but Weak Host Receiving is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostReceiveDisabled }

                It 'Should return false' {
                    Test-TargetResource @testNetIPWeakHostReceiveEnabled | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state disabled and Weak Host Receiving is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostReceiveDisabled }

                It 'Should return true' {
                    Test-TargetResource @testNetIPWeakHostReceiveDisabled | Should -Be $True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state enabled and Weak Host Receiving is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostReceiveEnabled }

                It 'Should return true' {
                    Test-TargetResource @testNetIPWeakHostReceiveEnabled | Should -Be $True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state disabled but Weak Host Receiving is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostReceiveEnabled }

                It 'Should return false' {
                    Test-TargetResource @testNetIPWeakHostReceiveDisabled | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_WeakHostReceive\Assert-ResourceProperty' {
            Context 'Invoking with bad interface alias' {
                Mock -CommandName Get-NetAdapter

                It 'Should throw an InterfaceNotAvailable error' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.InterfaceNotAvailableError -f $testNetIPWeakHostReceiveEnabled.InterfaceAlias)

                    { Assert-ResourceProperty @testNetIPWeakHostReceiveEnabled } | Should -Throw $errorRecord
                }
            }
        }
    } #end InModuleScope
    #endregion
}
finally
{
    Invoke-TestCleanup
}
