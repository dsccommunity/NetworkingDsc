$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_NetAdapterState'

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
    #region Pester Tests
    InModuleScope $script:DSCResourceName {

        $netAdapterEnabled = [PSCustomObject]@{
            Name = 'Ethernet'
            AdminStatus = [PSCustomObject]@{
                value__ = 1
            }
        }

        $netAdapterDisabled = [PSCustomObject]@{
            Name = 'Ethernet'
            AdminStatus = [PSCustomObject]@{
                value__ = 2
            }
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {

            $getTargetResource = @{
                Name = 'Ethernet'
            }

            Context 'Adapter exist and is enabled' {

                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterEnabled
                }

                It 'Should return the state of the network adapter' {
                    $result = Get-TargetResource @getTargetResource
                    $result.State | Should -Be 'Enabled'
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Adapter exist and is disabled' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterDisabled
                }

                It 'Should return the state of the network adapter' {
                    $result = Get-TargetResource @getTargetResource
                    $result.State | Should -Be 'Disabled'
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {

            $setTargetResourceEnabled = @{
                Name = 'Ethernet'
                State = 'Enabled'
            }

            $setTargetResourceDisabled = @{
                Name = 'Ethernet'
                State = 'Disabled'
            }

            Context 'Adapter exist and is enabled, desired state is enabled, no action required' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterEnabled
                }
                Mock -CommandName Disable-NetAdapter

                It 'Should not throw an exception' {
                    { Set-TargetResource @setTargetResourceEnabled } | Should -Not -Throw
                }

                It 'Should not call Disable-NetAdapter' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Disable-NetAdapter -Exactly -Times 0
                }
            }

            Context 'Adapter exist and is enabled, desired state is disabled, should be disabled' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterEnabled
                }
                Mock -CommandName Disable-NetAdapter

                It 'Should not throw an exception' {
                    { Set-TargetResource @setTargetResourceDisabled } | Should -Not -Throw
                }

                It 'Should call Disable-NetAdapter' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Disable-NetAdapter -Exactly -Times 1 -ParameterFilter {
                        $Name -eq $setTargetResourceEnabled.Name
                    }
                }
            }

            Context 'Adapter exist and is disabled, desired state is disabled, no action required' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterDisabled
                }
                Mock -CommandName Enable-NetAdapter
                Mock -CommandName Disable-NetAdapter

                It 'Should not throw an exception' {
                    { Set-TargetResource @setTargetResourceDisabled } | Should -Not -Throw
                }

                It 'Should not call Enable-NetAdapter' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Enable-NetAdapter -Exactly -Times 0
                }
            }

            Context 'Adapter exist and is disabled, desired state is enabled, should be enabled' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterDisabled
                }
                Mock -CommandName Enable-NetAdapter

                It 'Should not throw an exception' {
                    { Set-TargetResource @setTargetResourceEnabled } | Should -Not -Throw
                }

                It 'Should call Enable-NetAdapter' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Enable-NetAdapter -Exactly -Times 1 -ParameterFilter {
                        $Name -eq $setTargetResourceEnabled.Name
                    }
                }
            }

            Context 'Adapter exist and is disabled, desired state is enabled, set failed' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterDisabled
                }

                Mock -CommandName Enable-NetAdapter -MockWith {
                    Throw "Throwing from Enable-NetAdapter"
                }

                $errorText = "Set-TargetResource: Failed to set network adapter 'Ethernet' to state 'Enabled'. Error: 'Throwing from Enable-NetAdapter'."
                It 'Should raise a non terminating error' {
                    $netAdapterError = Set-TargetResource @setTargetResourceEnabled 2>&1
                    $netAdapterError.Exception.Message | Should Be $errorText
                }
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {

            $testTargetResourceEnabled = @{
                Name = 'Ethernet'
                State = 'Enabled'
            }

            $testTargetResourceDisabled = @{
                Name = 'Ethernet'
                State = 'Disabled'
            }

            Context 'Adapter exist and is enabled, desired state is enabled, test true' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterEnabled
                }

                It 'Should return true' {
                    Test-TargetResource @testTargetResourceEnabled | Should -Be $true
                }
            }

            Context 'Adapter exist and is enabled, desired state is disabled, test false' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterEnabled
                }

                It 'Should return false' {
                    Test-TargetResource @testTargetResourceDisabled | Should -Be $false
                }
            }

            Context 'Adapter exist and is disabled, desired state is disabled, test true' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterDisabled
                }

                It 'Should return true' {
                    Test-TargetResource @testTargetResourceDisabled | Should -Be $true
                }
            }

            Context 'Adapter exist and is disabled, desired state is enabled, test false' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterDisabled
                }

                It 'Should return false' {
                    Test-TargetResource @testTargetResourceEnabled | Should -Be $false
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
