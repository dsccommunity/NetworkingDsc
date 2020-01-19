$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetAdapterState'

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
        # Import the NetAdapter module to load the required NET_IF_ADMIN_STATUS enums
        Import-Module -Name NetAdapter

        $netAdapterEnabled = [PSCustomObject]@{
            Name        = 'Ethernet'
            AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Up
        }

        $netAdapterDisabled = [PSCustomObject]@{
            Name        = 'Ethernet'
            AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Down
        }

        $netAdapterUnsupported = [PSCustomObject]@{
            Name        = 'Ethernet'
            AdminStatus = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetAdapter.NET_IF_ADMIN_STATUS]::Testing
        }

        Describe 'DSC_NetAdapterState\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                $getTargetResource = @{
                    Name    = 'Ethernet'
                    State   = 'Enabled'
                    Verbose = $true
                }
            }

            Context 'When adapter exists and is enabled' {
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

            Context 'When adapter exists and is in unsupported state' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterUnsupported
                }

                It 'Should return the state of the network adapter' {
                    $result = Get-TargetResource @getTargetResource
                    $result.State | Should -Be 'Unsupported'
                }
            }

            Context 'When adapter exists and is disabled' {
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

            Context 'When Get-NetAdapter returns error' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    Throw 'Throwing from Get-NetAdapter'
                }

                It 'Should display warning when network adapter cannot be found' {
                    $warning = Get-TargetResource @getTargetResource 3>&1
                    $warning.Message | Should -Be "Get-TargetResource: Network adapter 'Ethernet' not found."
                }
            }
        }

        Describe 'DSC_NetAdapterState\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                $setTargetResourceEnabled = @{
                    Name    = 'Ethernet'
                    State   = 'Enabled'
                    Verbose = $true
                }

                $setTargetResourceDisabled = @{
                    Name    = 'Ethernet'
                    State   = 'Disabled'
                    Verbose = $true
                }
            }

            Context 'When adapter exists and is enabled, desired state is enabled, no action required' {
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

            Context 'When adapter exists and is enabled, desired state is disabled, should be disabled' {
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

            Context 'When adapter exists and is disabled, desired state is disabled, no action required' {
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

            Context 'When adapter exists and is disabled, desired state is enabled, should be enabled' {
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

            Context 'When adapter exists and is disabled, desired state is enabled, set failed' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterDisabled
                }

                Mock -CommandName Enable-NetAdapter -MockWith {
                    Throw 'Throwing from Enable-NetAdapter'
                }

                $errorText = "Set-TargetResource: Failed to set network adapter 'Ethernet' to state 'Enabled'. Error: 'Throwing from Enable-NetAdapter'."

                It 'Should raise a non terminating error' {
                    $netAdapterError = Set-TargetResource @setTargetResourceEnabled -ErrorAction Continue 2>&1
                    $netAdapterError.Exception.Message | Should -Be $errorText
                }
            }

            Context 'When adapter does not exist and desired state is enabled' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    throw 'Throwing from Get-NetAdapter'
                }

                $errorText = "Set-TargetResource: Network adapter 'Ethernet' not found."

                It 'Should raise a non terminating error' {
                    $netAdapterError = Set-TargetResource @setTargetResourceEnabled -ErrorAction Continue 2>&1
                    $netAdapterError.Exception.Message | Should -Be $errorText
                }
            }
        }

        Describe 'DSC_NetAdapterState\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                $testTargetResourceEnabled = @{
                    Name    = 'Ethernet'
                    State   = 'Enabled'
                    Verbose = $true
                }

                $testTargetResourceDisabled = @{
                    Name    = 'Ethernet'
                    State   = 'Disabled'
                    Verbose = $true
                }
            }

            Context 'When adapter exists and is enabled, desired state is enabled, test true' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterEnabled
                }

                It 'Should return true' {
                    Test-TargetResource @testTargetResourceEnabled | Should -Be $true
                }
            }

            Context 'When adapter exists and is enabled, desired state is disabled, test false' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterEnabled
                }

                It 'Should return false' {
                    Test-TargetResource @testTargetResourceDisabled | Should -Be $false
                }
            }

            Context 'When adapter exists and is disabled, desired state is disabled, test true' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterDisabled
                }

                It 'Should return true' {
                    Test-TargetResource @testTargetResourceDisabled | Should -Be $true
                }
            }

            Context 'When adapter exists and is disabled, desired state is enabled, test false' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterDisabled
                }

                It 'Should return false' {
                    Test-TargetResource @testTargetResourceEnabled | Should -Be $false
                }
            }

            Context 'When adapter exists and is in Unsupported state, desired state is enabled, test false' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $netAdapterUnsupported
                }

                It 'Should return false' {
                    Test-TargetResource @testTargetResourceEnabled | Should -Be $false
                }
            }

            Context 'When adapter does not exist, desired state is enabled, test false' {
                Mock -CommandName Get-NetAdapter -MockWith {
                    $null
                }

                It 'Should return false' {
                    Test-TargetResource @testTargetResourceEnabled | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
