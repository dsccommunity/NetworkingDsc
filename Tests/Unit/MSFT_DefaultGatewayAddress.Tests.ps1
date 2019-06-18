$script:DSCModuleName      = 'NetworkingDsc'
$script:DSCResourceName    = 'MSFT_DefaultGatewayAddress'

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
        Describe 'MSFT_DefaultGatewayAddress\Get-TargetResource' -Tag 'Get' {
            Context 'Checking return with default gateway' {
                #region Mocks
                Mock Get-NetRoute -MockWith {
                    [PSCustomObject]@{
                        NextHop = '192.168.0.1'
                        DestinationPrefix = '0.0.0.0/0'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        AddressFamily = 'IPv4'
                    }
                }
                #endregion

                It 'Should return current default gateway' {
                    $getTargetResourceParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.Address | Should -Be '192.168.0.1'
                }
            }

            Context 'Checking return with no default gateway' {
                #region Mocks
                Mock Get-NetRoute -MockWith {}
                #endregion

                It 'Should return no default gateway' {
                    $getTargetResourceParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.Address | Should -BeNullOrEmpty
                }
            }
        }

        Describe 'MSFT_DefaultGatewayAddress\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                #region Mocks
                Mock Get-NetRoute -MockWith {
                    [PSCustomObject]@{
                        NextHop = '192.168.0.1'
                        DestinationPrefix = '0.0.0.0/0'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        AddressFamily = 'IPv4'
                    }
                }

                Mock Remove-NetRoute

                Mock New-NetRoute
                #endregion
            }

            Context 'Invoking with no Default Gateway Address' {
                It 'Should return $null' {
                    $setTargetResourceParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    $result | Should -BeNullOrEmpty
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                    Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
                    Assert-MockCalled -commandName New-NetRoute -Exactly 0
                }
            }

            Context 'Invoking with valid Default Gateway Address' {
                It 'Should return $null' {
                    $setTargetResourceParameters = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    $result | Should -BeNullOrEmpty
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                    Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
                    Assert-MockCalled -commandName New-NetRoute -Exactly 1
                }
            }
        }

        Describe 'MSFT_DefaultGatewayAddress\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                #region Mocks
                Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
                #endregion
            }

            Context 'Checking return with default gateway that matches currently set one' {
                #region Mocks
                Mock Get-NetRoute -MockWith {
                    [PSCustomObject]@{
                        NextHop = '192.168.0.1'
                        DestinationPrefix = '0.0.0.0/0'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        AddressFamily = 'IPv4'
                    }
                }
                #endregion

                It 'Should return true' {
                    $testTargetResourceParameters = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true
                }
            }

            Context 'Checking return with no gateway but one is currently set' {
                #region Mocks
                Mock Get-NetRoute -MockWith {
                    [PSCustomObject]@{
                        NextHop = '192.168.0.1'
                        DestinationPrefix = '0.0.0.0/0'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        AddressFamily = 'IPv4'
                    }
                }
                #endregion

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $False
                }
            }

            Context 'Checking return with default gateway but none are currently set' {
                #region Mocks
                Mock Get-NetRoute -MockWith {}
                #endregion

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $False
                }
            }

            Context 'Checking return with no gateway and none are currently set' {
                #region Mocks
                Mock Get-NetRoute -MockWith {}
                #endregion

                It 'Should return true' {
                    $testTargetResourceParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true
                }
            }
        }

        Describe 'MSFT_DefaultGatewayAddress\Assert-ResourceProperty' {
            BeforeEach {
                Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
            }

            Context 'Invoking with bad interface alias' {
                It 'Should throw an InterfaceNotAvailable error' {
                    $assertResourcePropertyParameters = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'NotReal'
                        AddressFamily = 'IPv4'
                    }

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.InterfaceNotAvailableError -f $assertResourcePropertyParameters.InterfaceAlias)

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $ErrorRecord
                }
            }

            Context 'Invoking with invalid IP Address' {
                It 'Should throw an AddressFormatError error' {
                    $assertResourcePropertyParameters = @{
                        Address = 'NotReal'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressFormatError -f $assertResourcePropertyParameters.Address) `
                        -ArgumentName 'Address'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $ErrorRecord
                }
            }

            Context 'Invoking with IPv4 Address and family mismatch' {
                It 'Should throw an AddressMismatchError error' {
                    $assertResourcePropertyParameters = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv4MismatchError -f $assertResourcePropertyParameters.Address,$assertResourcePropertyParameters.AddressFamily) `
                        -ArgumentName 'AddressFamily'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $ErrorRecord
                }
            }

            Context 'Invoking with IPv6 Address and family mismatch' {
                It 'Should throw an AddressMismatchError error' {
                    $assertResourcePropertyParameters = @{
                        Address = 'fe80::'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv6MismatchError -f $assertResourcePropertyParameters.Address,$assertResourcePropertyParameters.AddressFamily) `
                        -ArgumentName 'AddressFamily'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $ErrorRecord
                }
            }

            Context 'Invoking with valid IPv4 Address' {
                It 'Should not throw an error' {
                    $assertResourcePropertyParameters = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
                }
            }

            Context 'Invoking with valid IPv6 Address' {
                It 'Should not throw an error' {
                    $assertResourcePropertyParameters = @{
                        Address = 'fe80:ab04:30F5:002b::1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
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
