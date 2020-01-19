$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_NetConnectionProfile'

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
            InterfaceAlias = $mockNetAdapter.Name
        }

        $testNetworkCategoryMatches = [PSObject] @{
            InterfaceAlias  = $mockNetAdapter.Name
            NetworkCategory = 'Public'
        }

        $testNetworkCategoryNoMatches = [PSObject] @{
            InterfaceAlias  = $mockNetAdapter.Name
            NetworkCategory = 'Private'
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

        Describe 'DSC_NetConnectionProfile\Get-TargetResource' -Tag 'Get' {
            Mock -CommandName Get-NetConnectionProfile {
                return $mockNetConnnectionProfileAll
            }

            $result = Get-TargetResource -InterfaceAlias $mockNetAdapter.Name

            It 'Should return the correct values' {
                $result.InterfaceAlias | Should -Be $mockNetConnnectionProfileAll.InterfaceAlias
                $result.NetworkCategory | Should -Be $mockNetConnnectionProfileAll.NetworkCategory
                $result.IPv4Connectivity | Should -Be $mockNetConnnectionProfileAll.IPv4Connectivity
                $result.IPv6Connectivity | Should -Be $mockNetConnnectionProfileAll.IPv6Connectivity
            }
        }

        Describe 'DSC_NetConnectionProfile\Test-TargetResource' -Tag 'Test' {
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

        Describe 'DSC_NetConnectionProfile\Set-TargetResource' -Tag 'Set' {
            It 'Should call all the mocks' {
                Mock -CommandName Set-NetConnectionProfile
                Mock -CommandName Assert-ResourceProperty

                Set-TargetResource @testNetworkCategoryMatches

                Assert-MockCalled -CommandName Set-NetConnectionProfile
            }
        }

        Describe 'DSC_NetConnectionProfile\Assert-ResourceProperty' {
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
    Invoke-TestCleanup
}
