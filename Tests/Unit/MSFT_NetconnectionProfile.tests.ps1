$script:DSCModuleName      = 'NetworkingDsc'
$script:DSCResourceName    = 'MSFT_NetConnectionProfile'

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
        # Create the Mock Objects that will be used for running tests
        $mockNetAdapter = [PSCustomObject] @{
            Name = 'TestAdapter'
        }

        $mockNetConnnectionProfileAll = [PSObject] @{
            InterfaceAlias   = $mockNetAdapter.Name
            NetworkCategory  = 'Public'
            IPv4Connectivity = 'Internet'
            IPv6Connectivity = 'Internet'
        }

        $testValidInterfaceAliasOnlyPassed = [PSObject] @{
            InterfaceAlias   = $mockNetAdapter.Name
        }

        $testNetworkCategoryMatches = [PSObject] @{
            InterfaceAlias   = $mockNetAdapter.Name
            NetworkCategory  = 'Public'
        }

        $testNetworkCategoryNoMatches = [PSObject] @{
            InterfaceAlias   = $mockNetAdapter.Name
            NetworkCategory  = 'Private'
        }

        $testIPv4ConnectivityMatches = [PSObject] @{
            InterfaceAlias   = $mockNetAdapter.Name
            IPv4Connectivity = 'Internet'
        }

        $testIPv4ConnectivityNoMatches = [PSObject] @{
            InterfaceAlias   = $mockNetAdapter.Name
            IPv4Connectivity = 'Disconnected'
        }

        $testIPv6ConnectivityMatches = [PSObject] @{
            InterfaceAlias   = $mockNetAdapter.Name
            IPv6Connectivity = 'Internet'
        }

        $testIPv6ConnectivityNoMatches = [PSObject] @{
            InterfaceAlias   = $mockNetAdapter.Name
            IPv6Connectivity = 'Disconnected'
        }

        Describe 'MSFT_NetConnectionProfile\Get-TargetResource' -Tag 'Get' {
            Mock -CommandName Get-NetConnectionProfile {
                return $mockNetConnnectionProfileAll
            }

            $result = Get-TargetResource -InterfaceAlias $mockNetAdapter.Name

            It 'Should return the correct values' {
                $result.InterfaceAlias   | Should -Be $mockNetConnnectionProfileAll.InterfaceAlias
                $result.NetworkCategory  | Should -Be $mockNetConnnectionProfileAll.NetworkCategory
                $result.IPv4Connectivity | Should -Be $mockNetConnnectionProfileAll.IPv4Connectivity
                $result.IPv6Connectivity | Should -Be $mockNetConnnectionProfileAll.IPv6Connectivity
            }
        }

        Describe 'MSFT_NetConnectionProfile\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Get-TargetResource -MockWith {
                    return $mockNetConnnectionProfileAll
                }

                Mock -CommandName Assert-ResourceProperty
            }

            Context 'NetworkCategory matches' {
                It 'Should return false' {
                    Test-TargetResource @testNetworkCategoryMatches | should -be $true
                }
            }

            Context 'NetworkCategory does not match' {
                It 'Should return false' {
                    Test-TargetResource @testNetworkCategoryNoMatches | should -be $false
                }
            }

            Context 'IPv4Connectivity matches' {
                It 'Should return false' {
                    Test-TargetResource @testIPv4ConnectivityMatches | should -be $true
                }
            }

            Context 'IPv4Connectivity does not match' {
                It 'Should return false' {
                    Test-TargetResource @testIPv4ConnectivityNoMatches | should -be $false
                }
            }

            Context 'IPv6Connectivity matches' {
                It 'Should return false' {
                    Test-TargetResource @testIPv6ConnectivityMatches | should -be $true
                }
            }

            Context 'IPv6Connectivity does not match' {
                It 'Should return false' {
                    Test-TargetResource @testIPv6ConnectivityNoMatches | should -be $false
                }
            }
        }

        Describe 'MSFT_NetConnectionProfile\Set-TargetResource' -Tag 'Set' {
            It 'Should call all the mocks' {
                Mock -CommandName Set-NetConnectionProfile
                Mock -CommandName Assert-ResourceProperty

                Set-TargetResource @testNetworkCategoryMatches

                Assert-MockCalled -CommandName Set-NetConnectionProfile
            }
        }

        Describe 'MSFT_NetConnectionProfile\Assert-ResourceProperty' {
            Context 'Invoking with bad interface alias' {
                Mock -CommandName Get-NetAdapter

                It 'Should throw testValidInterfaceAliasOnlyPassed exception' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.InterfaceNotAvailableError -f $testValidInterfaceAliasOnlyPassed.InterfaceAlias)

                    { Assert-ResourceProperty @testValidInterfaceAliasOnlyPassed } | Should -Throw $errorRecord
                }
            }

            Context 'Invoking with valid interface alias but all empty parameters' {
                Mock -CommandName Get-NetAdapter -MockWith { return $mockNetAdapter }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.ParameterCombinationError)

                It 'Should not ParameterCombinationError exception' {
                    { Assert-ResourceProperty @testValidInterfaceAliasOnlyPassed } | Should -Throw $errorRecord
                }
            }

            Context 'Invoking with valid interface alias and one NetworkCategory' {
                Mock -CommandName Get-NetAdapter -MockWith { return $mockNetAdapter }

                It 'Should not throw an exception' {
                    { Assert-ResourceProperty @testNetworkCategoryMatches } | Should -Not -Throw
                }
            }

            Context 'Invoking with valid interface alias and one IPv4Connectivity' {
                Mock -CommandName Get-NetAdapter -MockWith { return $mockNetAdapter }

                It 'Should not throw an exception' {
                    { Assert-ResourceProperty @testIPv4ConnectivityMatches } | Should -Not -Throw
                }
            }

            Context 'Invoking with valid interface alias and one IPv6Connectivity' {
                Mock -CommandName Get-NetAdapter -MockWith { return $mockNetAdapter }

                It 'Should not throw an exception' {
                    { Assert-ResourceProperty @testIPv6ConnectivityMatches } | Should -Not -Throw
                }
            }
        }
    } #end InModuleScope $DSCResourceName
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
