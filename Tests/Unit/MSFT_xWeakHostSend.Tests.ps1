<#
    .SYNOPSIS
        Template for creating DSC Resource Unit Tests
    .DESCRIPTION
        To Use:
        1. Copy to \Tests\Unit\ folder and rename <ResourceName>.tests.ps1 (e.g. MSFT_xFirewall.tests.ps1)
        2. Customize TODO sections.
        3. Delete all template comments (TODOs, etc.)

    .NOTES
        There are multiple methods for writing unit tests. This template provides a few examples
        which you are welcome to follow but depending on your resource, you may want to
        design it differently. Read through our TestsGuidelines.md file for an intro on how to
        write unit tests for DSC resources: https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md
#>

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xNetWorking' `
    -DSCResourceName 'MSFT_xWeakHostSend' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    # TODO: Optional init code goes here...
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    # TODO: Other Optional Cleanup Code Goes Here...
}

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope MSFT_xWeakHostSend {

        # Create the Mock Objects that will be used for running tests
        $mockNetAdapter = [PSCustomObject] @{
            Name = 'Ethernet'
        }

        $testNetIPInterfaceEnabled = [PSObject]@{
            State          = 'Enabled'
            InterfaceAlias = $mockNetAdapter.Name
            AddressFamily  = 'IPv4'
        }

        $testNetIPInterfaceDisabled = [PSObject]@{
            State          = 'Disabled'
            InterfaceAlias = $mockNetAdapter.Name
            AddressFamily  = 'IPv4'
        }

        $mockNetIPInterfaceEnabled = [PSObject]@{
            WeakHostSend = $testNetIPInterfaceEnabled.State
            InterfaceAlias  = $testNetIPInterfaceEnabled.Name
            AddressFamily   = $testNetIPInterfaceEnabled.AddressFamily
        }

        $mockNetIPInterfaceDisabled = [PSObject]@{
            WeakHostSend = $testNetIPInterfaceDisabled.State
            InterfaceAlias  = $testNetIPInterfaceDisabled.Name
            AddressFamily   = $testNetIPInterfaceDisabled.AddressFamily
        }

        Describe 'MSFT_xWeakHostSend\Get-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            }

            Context 'Invoking with when Weak Host Receiving is enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceEnabled }

                It 'Should return Weak Host Receiving state of enabled' {
                    $Result = Get-TargetResource @testNetIPInterfaceEnabled
                    $Result.State          | Should Be $testNetIPInterfaceEnabled.State
                    $Result.InterfaceAlias | Should Be $testNetIPInterfaceEnabled.InterfaceAlias
                    $Result.AddressFamily  | Should Be $testNetIPInterfaceEnabled.AddressFamily
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with when Weak Host Receiving is disabled' {
                Mock Get-NetIPInterface -MockWith { $mockNetIPInterfaceDisabled }

                It 'Should return Weak Host Receiving state of disabled' {
                    $Result = Get-TargetResource @testNetIPInterfaceDisabled
                    $Result.State          | Should Be $testNetIPInterfaceDisabled.State
                    $Result.InterfaceAlias | Should Be $testNetIPInterfaceDisabled.InterfaceAlias
                    $Result.AddressFamily  | Should Be $testNetIPInterfaceDisabled.AddressFamily
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_xWeakHostSend\Set-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
                Mock -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Enabled' }
                Mock -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Disabled' }
            }

            Context 'Invoking with state enabled but Weak Host Receiving is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceDisabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPInterfaceEnabled } | Should Not Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Enabled' } -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Disabled' } -Exactly -Times 0
                }
            }

            Context 'invoking with state disabled and Weak Host Receiving is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceDisabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPInterfaceDisabled } | Should Not Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Enabled' } -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Disabled' } -Exactly -Times 1
                }
            }

            Context 'invoking with state enabled and Weak Host Receiving is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceEnabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPInterfaceEnabled } | Should Not Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Enabled' } -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Disabled' } -Exactly -Times 0
                }
            }

            Context 'invoking with state disabled but Weak Host Receiving is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceEnabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPInterfaceDisabled } | Should Not Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Enabled' } -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $WeakHostSend -eq 'Disabled' } -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_xWeakHostSend\Test-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            }

            Context 'Invoking with state enabled but Weak Host Receiving is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceDisabled }

                It 'Should return false' {
                    Test-TargetResource @testNetIPInterfaceEnabled | Should Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state disabled and Weak Host Receiving is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceDisabled }

                It 'Should return true' {
                    Test-TargetResource @testNetIPInterfaceDisabled | Should Be $True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state enabled and Weak Host Receiving is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceEnabled }

                It 'Should return true' {
                    Test-TargetResource @testNetIPInterfaceEnabled | Should Be $True
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state disabled but Weak Host Receiving is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceEnabled }

                It 'Should return false' {
                    Test-TargetResource @testNetIPInterfaceDisabled | Should Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_xWeakHostSend\Assert-ResourceProperty' {
            Context 'Invoking with bad interface alias' {
                Mock -CommandName Get-NetAdapter

                It 'Should throw an InterfaceNotAvailable error' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.InterfaceNotAvailableError -f $testNetIPInterfaceEnabled.InterfaceAlias)

                    { Assert-ResourceProperty @testNetIPInterfaceEnabled } | Should Throw $errorRecord
                }
            }
        }
    } #end InModuleScope
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
    Invoke-TestCleanup
}
