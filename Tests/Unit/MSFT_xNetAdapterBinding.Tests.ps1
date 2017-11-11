$script:DSCModuleName = 'xNetworking'
$script:DSCResourceName = 'MSFT_xNetAdapterBinding'

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
    InModuleScope $script:DSCResourceName {

        $testBindingEnabled = @{
            InterfaceAlias = 'Ethernet'
            ComponentId    = 'ms_tcpip63'
            State          = 'Enabled'
        }

        $testBindingDisabled = @{
            InterfaceAlias = 'Ethernet'
            ComponentId    = 'ms_tcpip63'
            State          = 'Disabled'
        }

        $testBindingMixed = @{
            InterfaceAlias = '*'
            ComponentId    = 'ms_tcpip63'
            State          = 'Enabled'
        }

        $mockAdapter = @{
            InterfaceAlias = 'Ethernet'
        }

        $mockBindingEnabled = @{
            InterfaceAlias = 'Ethernet'
            ComponentId    = 'ms_tcpip63'
            Enabled        = $True
        }

        $mockBindingDisabled = @{
            InterfaceAlias = 'Ethernet'
            ComponentId    = 'ms_tcpip63'
            Enabled        = $False
        }

        $MockBindingMixed = @(
            @{
                InterfaceAlias = 'Ethernet'
                ComponentId    = 'ms_tcpip63'
                Enabled        = $False
            },
            @{
                InterfaceAlias = 'Ethernet2'
                ComponentId    = 'ms_tcpip63'
                Enabled        = $True
            }
        )

        Describe "MSFT_xNetAdapterBinding\Get-TargetResource" {
            Context 'Adapter exists and binding Enabled' {
                Mock -CommandName Get-Binding -MockWith { $mockBindingEnabled }

                It 'Should return existing binding' {
                    $Result = Get-TargetResource @testBindingEnabled
                    $Result.InterfaceAlias | Should Be $testBindingEnabled.InterfaceAlias
                    $Result.ComponentId | Should Be $testBindingEnabled.ComponentId
                    $Result.State | Should Be 'Enabled'
                    $Result.CurrentState | Should Be 'Enabled'
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-Binding -Exactly -Times 1
                }
            }

            Context 'Adapter exists and binding Disabled' {
                Mock -CommandName Get-Binding -MockWith { $mockBindingDisabled }

                It 'Should return existing binding' {
                    $Result = Get-TargetResource @testBindingDisabled
                    $Result.InterfaceAlias | Should Be $testBindingDisabled.InterfaceAlias
                    $Result.ComponentId | Should Be $testBindingDisabled.ComponentId
                    $Result.State | Should Be 'Disabled'
                    $Result.CurrentState | Should Be 'Disabled'
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-Binding -Exactly -Times 1
                }
            }

            Context 'More than one Adapter exists and binding is Disabled on one and Enabled on another' {
                Mock -CommandName Get-Binding -MockWith { $MockBindingMixed }

                It 'Should return existing binding' {
                    $Result = Get-TargetResource @testBindingMixed
                    $Result.InterfaceAlias | Should Be $testBindingMixed.InterfaceAlias
                    $Result.ComponentId | Should Be $testBindingMixed.ComponentId
                    $Result.State | Should Be 'Enabled'
                    $Result.CurrentState | Should Be 'Mixed'
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-Binding -Exactly -Times 1
                }
            }

        }

        Describe "MSFT_xNetAdapterBinding\Set-TargetResource" {
            Context 'Adapter exists and set binding to Enabled' {
                Mock -CommandName Get-Binding -MockWith { $mockBindingDisabled }
                Mock -CommandName Enable-NetAdapterBinding
                Mock -CommandName Disable-NetAdapterBinding

                It 'Should not throw an exception' {
                    { Set-TargetResource @testBindingEnabled } | Should Not Throw
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-Binding -Exactly -Times 1
                    Assert-MockCalled -CommandName Enable-NetAdapterBinding -Exactly -Times 1
                    Assert-MockCalled -CommandName Disable-NetAdapterBinding -Exactly -Times 0
                }
            }

            Context 'Adapter exists and set binding to Disabled' {
                Mock -CommandName Get-Binding -MockWith { $mockBindingEnabled }
                Mock -CommandName Enable-NetAdapterBinding
                Mock -CommandName Disable-NetAdapterBinding

                It 'Should not throw an exception' {
                    { Set-TargetResource @testBindingDisabled } | Should Not Throw
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-Binding -Exactly -Times 1
                    Assert-MockCalled -CommandName Enable-NetAdapterBinding -Exactly -Times 0
                    Assert-MockCalled -CommandName Disable-NetAdapterBinding -Exactly -Times 1
                }
            }
        }

        Describe "MSFT_xNetAdapterBinding\Test-TargetResource" {
            Context 'Adapter exists, current binding set to Enabled but want it Disabled' {
                Mock -CommandName Get-Binding -MockWith { $mockBindingEnabled }

                It 'Should return false' {
                    Test-TargetResource @testBindingDisabled | Should Be $False
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-Binding -Exactly -Times 1
                }
            }

            Context 'Adapter exists, current binding set to Disabled but want it Enabled' {
                Mock -CommandName Get-Binding -MockWith { $mockBindingDisabled }

                It 'Should return false' {
                    Test-TargetResource @testBindingEnabled | Should Be $False
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-Binding -Exactly -Times 1
                }
            }

            Context 'Adapter exists, current binding set to Enabled and want it Enabled' {
                Mock -CommandName Get-Binding -MockWith { $mockBindingEnabled }

                It 'Should return true' {
                    Test-TargetResource @testBindingEnabled | Should Be $True
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-Binding -Exactly -Times 1
                }
            }

            Context 'Adapter exists, current binding set to Disabled and want it Disabled' {
                Mock -CommandName Get-Binding -MockWith { $mockBindingDisabled }

                It 'Should return true' {
                    Test-TargetResource @testBindingDisabled | Should Be $True
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-Binding -Exactly -Times 1
                }
            }
        }

        Describe "MSFT_xNetAdapterBinding\Get-Binding" {
            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapter

                It 'Should throw an InterfaceNotAvailable error' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.InterfaceNotAvailableError -f $testBindingEnabled.InterfaceAlias) `
                        -ArgumentName 'Interface'

                    { Get-Binding @testBindingEnabled } | Should Throw $errorRecord
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Adapter exists and binding enabled' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockAdapter }
                Mock -CommandName Get-NetAdapterBinding -MockWith { $mockBindingEnabled }

                It 'Should return the adapter binding' {
                    $Result = Get-Binding @testBindingEnabled
                    $Result.InterfaceAlias | Should Be $mockBindingEnabled.InterfaceAlias
                    $Result.ComponentId    | Should Be $mockBindingEnabled.ComponentId
                    $Result.Enabled        | Should Be $mockBindingEnabled.Enabled
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetAdapterBinding -Exactly -Times 1
                }
            }

            Context 'Adapter exists and binding disabled' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockAdapter }
                Mock -CommandName Get-NetAdapterBinding -MockWith { $mockBindingDisabled }

                It 'Should return the adapter binding' {
                    $Result = Get-Binding @testBindingDisabled
                    $Result.InterfaceAlias | Should Be $mockBindingDisabled.InterfaceAlias
                    $Result.ComponentId    | Should Be $mockBindingDisabled.ComponentId
                    $Result.Enabled        | Should Be $mockBindingDisabled.Enabled
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-NetAdapterBinding -Exactly -Times 1
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
