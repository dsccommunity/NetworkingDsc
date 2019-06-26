$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_Route'

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
            Name = 'Ethernet'
        }

        $testRoute = [PSObject]@{
            InterfaceAlias    = $mockNetAdapter.Name
            AddressFamily     = 'IPv4'
            DestinationPrefix = '10.0.0.1/8'
            NextHop           = '10.0.0.2'
            Ensure            = 'Present'
            RouteMetric       = 200
            Publish           = 'Age'
            PreferredLifetime = 50000
        }

        $testRouteKeys = [PSObject]@{
            InterfaceAlias    = $mockNetAdapter.Name
            AddressFamily     = $testRoute.AddressFamily
            DestinationPrefix = $testRoute.DestinationPrefix
            NextHop           = $testRoute.NextHop
        }

        $mockRoute = [PSObject]@{
            InterfaceAlias    = $mockNetAdapter.Name
            AddressFamily     = $testRoute.AddressFamily
            DestinationPrefix = $testRoute.DestinationPrefix
            NextHop           = $testRoute.NextHop
            Ensure            = $testRoute.Ensure
            RouteMetric       = $testRoute.RouteMetric
            Publish           = $testRoute.Publish
            PreferredLifetime = ([Timespan]::FromSeconds($testRoute.PreferredLifetime))
        }

        Describe 'MSFT_Route\Get-TargetResource' -Tag 'Get' {
            Context 'Route does not exist' {
                Mock -CommandName Get-NetRoute

                It 'Should return absent Route' {
                    $result = Get-TargetResource @testRouteKeys
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                }
            }

            Context 'Route does exist' {
                Mock -CommandName Get-NetRoute -MockWith { $mockRoute }

                It 'Should return correct Route' {
                    $result = Get-TargetResource @testRouteKeys
                    $result.Ensure            | Should -Be 'Present'
                    $result.InterfaceAlias    | Should -Be $testRoute.InterfaceAlias
                    $result.AddressFamily     | Should -Be $testRoute.AddressFamily
                    $result.DestinationPrefix | Should -Be $testRoute.DestinationPrefix
                    $result.NextHop           | Should -Be $testRoute.NextHop
                    $result.RouteMetric       | Should -Be $testRoute.RouteMetric
                    $result.Publish           | Should -Be $testRoute.Publish
                    $result.PreferredLifetime | Should -Be $testRoute.PreferredLifetime
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_Route\Set-TargetResource' -Tag 'Set' {
            Context 'Route does not exist but should' {
                Mock -CommandName Get-NetRoute
                Mock -CommandName New-NetRoute
                Mock -CommandName Set-NetRoute
                Mock -CommandName Remove-NetRoute

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $testRoute.Clone()
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetRoute -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetRoute -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 0
                }
            }

            Context 'Route exists and should but has a different RouteMetric' {
                Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
                Mock -CommandName New-NetRoute
                Mock -CommandName Set-NetRoute
                Mock -CommandName Remove-NetRoute

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $testRoute.Clone()
                        $setTargetResourceParameters.RouteMetric = $setTargetResourceParameters.RouteMetric + 10
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetRoute -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetRoute -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 0
                }
            }

            Context 'Route exists and should but has a different Publish' {
                Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
                Mock -CommandName New-NetRoute
                Mock -CommandName Set-NetRoute
                Mock -CommandName Remove-NetRoute

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $testRoute.Clone()
                        $setTargetResourceParameters.Publish = 'No'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetRoute -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetRoute -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 0
                }
            }

            Context 'Route exists and should but has a different PreferredLifetime' {
                Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
                Mock -CommandName New-NetRoute
                Mock -CommandName Set-NetRoute
                Mock -CommandName Remove-NetRoute

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $testRoute.Clone()
                        $setTargetResourceParameters.PreferredLifetime = $testRoute.PreferredLifetime + 1000
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetRoute -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetRoute -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 0
                }
            }

            Context 'Route exists and but should not' {
                Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
                Mock -CommandName New-NetRoute
                Mock -CommandName Set-NetRoute
                Mock -CommandName Remove-NetRoute `
                    -ParameterFilter {
                    ($InterfaceAlias -eq $testRoute.InterfaceAlias) -and `
                    ($AddressFamily -eq $testRoute.AddressFamily) -and `
                    ($DestinationPrefix -eq $testRoute.DestinationPrefix) -and `
                    ($NextHop -eq $testRoute.NextHop) -and `
                    ($RouteMetric -eq $testRoute.RouteMetric)
                }

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $testRoute.Clone()
                        $setTargetResourceParameters.Ensure = 'Absent'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks and parameters' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetRoute -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetRoute -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-NetRoute `
                        -ParameterFilter {
                            ($InterfaceAlias -eq $testRoute.InterfaceAlias) -and `
                            ($AddressFamily -eq $testRoute.AddressFamily) -and `
                            ($DestinationPrefix -eq $testRoute.DestinationPrefix) -and `
                            ($NextHop -eq $testRoute.NextHop) -and `
                            ($RouteMetric -eq $testRoute.RouteMetric)
                        } `
                        -Exactly -Times 1
                }
            }

            Context 'Route does not exist and should not' {
                Mock -CommandName Get-NetRoute
                Mock -CommandName New-NetRoute
                Mock -CommandName Set-NetRoute
                Mock -CommandName Remove-NetRoute

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $testRoute.Clone()
                        $setTargetResourceParameters.Ensure = 'Absent'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                    Assert-MockCalled -CommandName New-NetRoute -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-NetRoute -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 0
                }
            }
        }

        Describe 'MSFT_Route\Test-TargetResource' -Tag 'Test' {
            Context 'Route does not exist but should' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
                Mock -CommandName Get-NetRoute

                It 'Should return false' {
                    $testTargetResourceParameters = $testRoute.Clone()
                    Test-TargetResource @testTargetResourceParameters | Should -Be $False

                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                }
            }

            Context 'Route exists and should but has a different RouteMetric' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
                Mock -CommandName Get-NetRoute -MockWith { $mockRoute }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $testRoute.Clone()
                        $testTargetResourceParameters.RouteMetric = $testTargetResourceParameters.RouteMetric + 5
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                }
            }

            Context 'Route exists and should but has a different Publish' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
                Mock -CommandName Get-NetRoute -MockWith { $mockRoute }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $testRoute.Clone()
                        $testTargetResourceParameters.Publish = 'Yes'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                }
            }

            Context 'Route exists and should but has a different PreferredLifetime' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
                Mock -CommandName Get-NetRoute -MockWith { $mockRoute }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $testRoute.Clone()
                        $testTargetResourceParameters.PreferredLifetime = $Splat.PreferredLifetime + 5000
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                }
            }

            Context 'Route exists and should and all parameters match' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
                Mock -CommandName Get-NetRoute -MockWith { $mockRoute }

                It 'Should return true' {
                    {
                        $testTargetResourceParameters = $testRoute.Clone()
                        Test-TargetResource @testTargetResourceParameters | Should -Be $True
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                }
            }

            Context 'Route exists but should not' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
                Mock -CommandName Get-NetRoute -MockWith { $mockRoute }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $testRoute.Clone()
                        $testTargetResourceParameters.Ensure = 'Absent'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $False
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                }
            }

            Context 'Route does not exist and should not' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
                Mock -CommandName Get-NetRoute

                It 'Should return true' {
                    {
                        $testTargetResourceParameters = $testRoute.Clone()
                        $testTargetResourceParameters.Ensure = 'Absent'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $True
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_Route\Assert-ResourceProperty' {
            Context 'Invoking with bad interface alias' {
                Mock -CommandName Get-NetAdapter

                It 'Should throw an InterfaceNotAvailable error' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.InterfaceNotAvailableError -f $testRoute.InterfaceAlias) `
                        -ArgumentName 'Interface'

                    { Assert-ResourceProperty @testRoute } | Should -Throw $errorRecord
                }
            }

            Context 'Invoking with bad IPv4 DestinationPrefix address' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }

                It 'Should throw an AddressFormatError error' {
                    $Splat = $testRoute.Clone()
                    $Splat.DestinationPrefix = '10.0.300.0/24'
                    $Splat.NextHop = '10.0.1.0'
                    $Splat.AddressFamily = 'IPv4'

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressFormatError -f '10.0.300.0') `
                        -ArgumentName 'DestinationPrefix'

                    { Assert-ResourceProperty @Splat } | Should -Throw $errorRecord
                }
            }

            Context 'Invoking with bad IPv6 DestinationPrefix address' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }

                It 'Should throw an AddressFormatError error' {
                    $Splat = $testRoute.Clone()
                    $Splat.DestinationPrefix = 'fe8x::/64'
                    $Splat.NextHop = 'fe90::'
                    $Splat.AddressFamily = 'IPv6'

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressFormatError -f 'fe8x::') `
                        -ArgumentName 'DestinationPrefix'

                    { Assert-ResourceProperty @Splat } | Should -Throw $errorRecord
                }
            }

            Context 'Invoking with IPv4 DestinationPrefix mismatch' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }

                It 'Should throw an AddressIPv6MismatchError error' {
                    $Splat = $testRoute.Clone()
                    $Splat.DestinationPrefix = 'fe80::/64'
                    $Splat.NextHop = '10.0.1.0'
                    $Splat.AddressFamily = 'IPv4'

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv6MismatchError -f 'fe80::', 'IPv4') `
                        -ArgumentName 'DestinationPrefix'

                    { Assert-ResourceProperty @Splat } | Should -Throw $errorRecord
                }
            }

            Context 'Invoking with IPv6 DestinationPrefix mismatch' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }

                It 'Should throw an AddressIPv4MismatchError error' {
                    $Splat = $testRoute.Clone()
                    $Splat.DestinationPrefix = '10.0.0.0/24'
                    $Splat.NextHop = 'fe81::'
                    $Splat.AddressFamily = 'IPv6'

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv4MismatchError -f '10.0.0.0', 'IPv6') `
                        -ArgumentName 'DestinationPrefix'

                    { Assert-ResourceProperty @Splat } | Should -Throw $errorRecord
                }
            }

            Context 'Invoking with bad IPv4 NextHop address' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }

                It 'Should throw an AddressFormatError error' {
                    $Splat = $testRoute.Clone()
                    $Splat.DestinationPrefix = '10.0.0.0/24'
                    $Splat.NextHop = '10.0.300.0'
                    $Splat.AddressFamily = 'IPv4'

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressFormatError -f '10.0.300.0') `
                        -ArgumentName 'NextHop'

                    { Assert-ResourceProperty @Splat } | Should -Throw $errorRecord
                }
            }

            Context 'Invoking with bad IPv6 NextHop address' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }

                It 'Should throw an AddressFormatError error' {
                    $Splat = $testRoute.Clone()
                    $Splat.DestinationPrefix = 'fe80::/64'
                    $Splat.NextHop = 'fe9x::'
                    $Splat.AddressFamily = 'IPv6'

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressFormatError -f 'fe9x::') `
                        -ArgumentName 'NextHop'

                    { Assert-ResourceProperty @Splat } | Should -Throw $errorRecord
                }
            }

            Context 'Invoking with IPv4 NextHop mismatch' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }

                It 'Should throw an AddressIPv6MismatchError error' {
                    $Splat = $testRoute.Clone()
                    $Splat.DestinationPrefix = '10.0.0.0/24'
                    $Splat.NextHop = 'fe90::'
                    $Splat.AddressFamily = 'IPv4'

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv6MismatchError -f 'fe90::', 'IPv4') `
                        -ArgumentName 'NextHop'

                    { Assert-ResourceProperty @Splat } | Should -Throw $errorRecord
                }
            }

            Context 'Invoking with IPv6 NextHop mismatch' {
                Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }

                It 'Should throw an AddressIPv4MismatchError error' {
                    $Splat = $testRoute.Clone()
                    $Splat.DestinationPrefix = 'fe80::/64'
                    $Splat.NextHop = '10.0.1.0'
                    $Splat.AddressFamily = 'IPv6'

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv4MismatchError -f '10.0.1.0', 'IPv6') `
                        -ArgumentName 'NextHop'

                    { Assert-ResourceProperty @Splat } | Should -Throw $errorRecord
                }
            }
        }
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
