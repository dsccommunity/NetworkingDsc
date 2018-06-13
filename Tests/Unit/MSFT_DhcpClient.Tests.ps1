$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_DhcpClient'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\NetworkingDsc'
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
            Dhcp           = $testNetIPInterfaceEnabled.State
            InterfaceAlias = $testNetIPInterfaceEnabled.Name
            AddressFamily  = $testNetIPInterfaceEnabled.AddressFamily
        }

        $mockNetIPInterfaceDisabled = [PSObject]@{
            Dhcp           = $testNetIPInterfaceDisabled.State
            InterfaceAlias = $testNetIPInterfaceDisabled.Name
            AddressFamily  = $testNetIPInterfaceDisabled.AddressFamily
        }

        Describe 'MSFT_DhcpClient\Get-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            }

            Context 'Invoking with when DHCP is enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceEnabled }

                It 'Should return DHCP state of enabled' {
                    $Result = Get-TargetResource @testNetIPInterfaceEnabled
                    $Result.State          | Should -Be $testNetIPInterfaceEnabled.State
                    $Result.InterfaceAlias | Should -Be $testNetIPInterfaceEnabled.InterfaceAlias
                    $Result.AddressFamily  | Should -Be $testNetIPInterfaceEnabled.AddressFamily
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with when DHCP is disabled' {
                Mock Get-NetIPInterface -MockWith { $mockNetIPInterfaceDisabled }

                It 'Should return DHCP state of disabled' {
                    $Result = Get-TargetResource @testNetIPInterfaceDisabled
                    $Result.State          | Should -Be $testNetIPInterfaceDisabled.State
                    $Result.InterfaceAlias | Should -Be $testNetIPInterfaceDisabled.InterfaceAlias
                    $Result.AddressFamily  | Should -Be $testNetIPInterfaceDisabled.AddressFamily
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_DhcpClient\Set-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
                Mock -CommandName Set-NetIPInterface -ParameterFilter { $dhcp -eq 'Enabled' }
                Mock -CommandName Set-NetIPInterface -ParameterFilter { $dhcp -eq 'Disabled' }
            }

            Context 'Invoking with state enabled but DHCP is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceDisabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPInterfaceEnabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $dhcp -eq 'Enabled' } -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $dhcp -eq 'Disabled' } -Exactly -Times 0
                }
            }

            Context 'invoking with state disabled and DHCP is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceDisabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPInterfaceDisabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $dhcp -eq 'Enabled' } -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $dhcp -eq 'Disabled' } -Exactly -Times 1
                }
            }

            Context 'invoking with state enabled and DHCP is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceEnabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPInterfaceEnabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $dhcp -eq 'Enabled' } -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $dhcp -eq 'Disabled' } -Exactly -Times 0
                }
            }

            Context 'invoking with state disabled but DHCP is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceEnabled }

                It 'Should not throw an exception' {
                    { Set-TargetResource @testNetIPInterfaceDisabled } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $dhcp -eq 'Enabled' } -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetIPInterface -ParameterFilter { $dhcp -eq 'Disabled' } -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_DhcpClient\Test-TargetResource' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            }

            Context 'Invoking with state enabled but DHCP is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceDisabled }

                It 'Should return false' {
                    Test-TargetResource @testNetIPInterfaceEnabled | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state disabled and DHCP is currently disabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceDisabled }

                It 'Should return true' {
                    Test-TargetResource @testNetIPInterfaceDisabled | Should -Be $true
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state enabled and DHCP is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceEnabled }

                It 'Should return true' {
                    Test-TargetResource @testNetIPInterfaceEnabled | Should -Be $true
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }

            Context 'Invoking with state disabled but DHCP is currently enabled' {
                Mock -CommandName Get-NetIPInterface -MockWith { $mockNetIPInterfaceEnabled }

                It 'Should return false' {
                    Test-TargetResource @testNetIPInterfaceDisabled | Should -Be $False
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetIPInterface -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_DhcpClient\Assert-ResourceProperty' {
            Context 'Invoking with bad interface alias' {
                Mock -CommandName Get-NetAdapter

                It 'Should throw an InterfaceNotAvailable error' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.InterfaceNotAvailableError -f $testNetIPInterfaceEnabled.InterfaceAlias)

                    { Assert-ResourceProperty @testNetIPInterfaceEnabled } | Should -Throw $errorRecord
                }
            }
        }
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
