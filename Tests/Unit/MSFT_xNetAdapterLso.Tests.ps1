$script:DSCModuleName   = 'xNetworking'
$script:DSCResourceName = 'MSFT_xNetAdapterLso'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
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

        $TestV1IPv4LsoEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'V1IPv4'
            State    = $true
        }

        $TestV1IPv4LsoDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'V1IPv4'
            State    = $false
        }

        $TestIPv4LsoEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv4'
            State    = $true
        }

        $TestIPv4LsoDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv4'
            State    = $false
        }

        $TestIPv6LsoEnabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv6'
            State    = $true
        }

        $TestIPv6LsoDisabled = @{
            Name     = 'Ethernet'
            Protocol = 'IPv6'
            State    = $false
        }

        $TestAdapterNotFound = @{
            Name     = 'Eth'
            Protocol = 'IPv4'
            State    = $true
        }


        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            Context 'Adapter exist and LSO for V1IPv4 is enabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith { 
                    @{ V1IPv4Enabled = $TestV1IPv4LsoEnabled.State }
                }
                
                It 'Should return the LSO state of V1IPv4' {
                    $result = Get-TargetResource @TestV1IPv4LsoEnabled
                    $result.V1IPv4Enabled | Should Be $TestV1IPv4LsoEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly 1
                }
            }

            Context 'Adapter exist and LSO for V1IPv4 is disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith { 
                    @{ V1IPv4Enabled = $TestV1IPv4LsoDisabled.State }
                }

                It 'Should return the LSO state of V1IPv4' {
                    $result = Get-TargetResource @TestV1IPv4LsoDisabled
                    $result.V1IPv4Enabled | Should Be $TestV1IPv4LsoDisabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly 1
                }
            }

            Context 'Adapter exist and LSO for IPv4 is enabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith { 
                    @{ IPv4Enabled = $TestIPv4LsoEnabled.State }
                }

                It 'Should return the LSO state of IPv4' {
                    $result = Get-TargetResource @TestIPv4LsoEnabled
                    $result.IPv4Enabled | Should Be $TestIPv4LsoEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly 1
                }
            }

            Context 'Adapter exist and LSO for IPv4 is disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith { 
                    @{ IPv4Enabled = $TestIPv4LsoDisabled.State }
                }

                It 'Should return the LSO state of IPv4' {
                    $result = Get-TargetResource @TestIPv4LsoDisabled
                    $result.IPv4Enabled | Should Be $TestIPv4LsoDisabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly 1
                }
            }

            Context 'Adapter exist and LSO for IPv6 is enabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith { 
                    @{ IPv6Enabled = $TestIPv6LsoEnabled.State }
                }

                It 'Should return the LSO state of IPv6' {
                    $result = Get-TargetResource @TestIPv6LsoEnabled
                    $result.IPv6Enabled | Should Be $TestIPv6LsoEnabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly 1
                }
            }

            Context 'Adapter exist and LSO for IPv6 is disabled' {
                Mock -CommandName Get-NetAdapterLso -MockWith { 
                    @{ IPv6Enabled = $TestIPv6LsoDisabled.State }
                }

                It 'Should return the LSO state of IPv6' {
                    $result = Get-TargetResource @TestIPv6LsoDisabled
                    $result.IPv6Enabled | Should Be $TestIPv6LsoDisabled.State
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly 1
                }
            }

            Context 'Adapter does not exist' {
                Mock -CommandName Get-NetAdapterLso -MockWith { throw 'Network adapter not found' }

                It 'Should throw error' {
                    { Get-TargetResource @TestAdapterNotFound } | Should throw
                }

                It 'Should call all mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterLso -Exactly 1 
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {

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
