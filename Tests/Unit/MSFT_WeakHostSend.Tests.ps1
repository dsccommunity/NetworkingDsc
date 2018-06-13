Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\NetworkingDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'NetworkingDsc' `
    -DSCResourceName 'MSFT_WeakHostSend' `
    -TestType Unit

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope MSFT_WeakHostSend {

        # Create the Mock Objects that will be used for running tests
        $mockNetAdapter = [PSCustomObject] @{
            Name = 'Ethernet'
        }

        $testNetIPWeakHostSendEnabled = [PSObject]@{
            State          = 'Enabled'
            InterfaceAlias = $mockNetAdapter.Name
            AddressFamily  = 'IPv4'
        }

        $testNetIPWeakHostSendDisabled = [PSObject]@{
            State          = 'Disabled'
            InterfaceAlias = $mockNetAdapter.Name
            AddressFamily  = 'IPv4'
        }

        $mockNetIPWeakHostSendEnabled = [PSObject]@{
            WeakHostSend = $testNetIPWeakHostSendEnabled.State
            InterfaceAlias  = $testNetIPWeakHostSendEnabled.Name
            AddressFamily   = $testNetIPWeakHostSendEnabled.AddressFamily
        }

        $mockNetIPWeakHostSendDisabled = [PSObject]@{
            WeakHostSend = $testNetIPWeakHostSendDisabled.State
            InterfaceAlias  = $testNetIPWeakHostSendDisabled.Name
            AddressFamily   = $testNetIPWeakHostSendDisabled.AddressFamily
        }

        Describe 'MSFT_WeakHostSend\Get-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            }

            Context 'Invoking with when Weak Host Sending is enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostSendEnabled }

                It 'Should return Weak Host Sending state of enabled' {
                    $Result = Get-TargetResource @testNetIPWeakHostSendEnabled
                    $Result.State          | Should -Be $testNetIPWeakHostSendEnabled.State
                    $Result.InterfaceAlias | Should -Be $testNetIPWeakHostSendEnabled.InterfaceAlias
                    $Result.AddressFamily  | Should -Be $testNetIPWeakHostSendEnabled.AddressFamily
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with when Weak Host Sending is disabled' {
                Mock Get-NetIPInterface -MockWith { $mockNetIPWeakHostSendDisabled }

                It 'Should return Weak Host Sending state of disabled' {
                    $Result = Get-TargetResource @testNetIPWeakHostSendDisabled
                    $Result.State          | Should -Be $testNetIPWeakHostSendDisabled.State
                    $Result.InterfaceAlias | Should -Be $testNetIPWeakHostSendDisabled.InterfaceAlias
                    $Result.AddressFamily  | Should -Be $testNetIPWeakHostSendDisabled.AddressFamily
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_WeakHostSend\Set-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
                Mock -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Enabled' }
                Mock -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Disabled' }
            }

            Context 'Invoking with state enabled but Weak Host Sending is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostSendDisabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPWeakHostSendEnabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Enabled' } -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Disabled' } -Exactly -Times 0
                }
            }

            Context 'invoking with state disabled and Weak Host Sending is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostSendDisabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPWeakHostSendDisabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Enabled' } -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Disabled' } -Exactly -Times 1
                }
            }

            Context 'invoking with state enabled and Weak Host Sending is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostSendEnabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPWeakHostSendEnabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Enabled' } -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Disabled' } -Exactly -Times 0
                }
            }

            Context 'invoking with state disabled but Weak Host Sending is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostSendEnabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPWeakHostSendDisabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Enabled' } -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Disabled' } -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_WeakHostSend\Test-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            }

            Context 'Invoking with state enabled but Weak Host Sending is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostSendDisabled }

                It 'Should return false' {
                    Test-TargetResource @testNetIPWeakHostSendEnabled | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state disabled and Weak Host Sending is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostSendDisabled }

                It 'Should return true' {
                    Test-TargetResource @testNetIPWeakHostSendDisabled | Should -Be $True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state enabled and Weak Host Sending is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostSendEnabled }

                It 'Should return true' {
                    Test-TargetResource @testNetIPWeakHostSendEnabled | Should -Be $True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state disabled but Weak Host Sending is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPWeakHostSendEnabled }

                It 'Should return false' {
                    Test-TargetResource @testNetIPWeakHostSendDisabled | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_WeakHostSend\Assert-ResourceProperty' {
            Context 'Invoking with bad interface alias' {
                Mock -CommandName Get-NetAdapter

                It 'Should throw an InterfaceNotAvailable error' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.InterfaceNotAvailableError -f $testNetIPWeakHostSendEnabled.InterfaceAlias)

                    { Assert-ResourceProperty @testNetIPWeakHostSendEnabled } | Should -Throw $errorRecord
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
