$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'DSC_DefaultGatewayAddress'

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
        $getNetRouteIpv4_Mock = {
            [PSCustomObject] @{
                NextHop           = '192.168.0.1'
                DestinationPrefix = '0.0.0.0/0'
                InterfaceAlias    = 'Ethernet'
                InterfaceIndex    = 1
                AddressFamily     = 'IPv4'
            }
        }

        Describe 'DSC_DefaultGatewayAddress\Get-TargetResource' -Tag 'Get' {
            Context 'When interface has a default gateway set' {
                Mock -CommandName Get-NetRoute -MockWith $getNetRouteIpv4_Mock

                It 'Should return current default gateway' {
                    $getTargetResourceParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.Address | Should -Be '192.168.0.1'
                }
            }

            Context 'When interface has no default gateway set' {
                Mock -CommandName Get-NetRoute

                It 'Should return no default gateway' {
                    $getTargetResourceParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.Address | Should -BeNullOrEmpty
                }
            }
        }

        Describe 'DSC_DefaultGatewayAddress\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Get-NetRoute -MockWith $getNetRouteIpv4_Mock
                Mock -CommandName Remove-NetRoute
                Mock -CommandName New-NetRoute
            }

            Context 'When invoking with no Default Gateway Address' {
                It 'Should return $null' {
                    $setTargetResourceParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
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

            Context 'When invoking with valid Default Gateway Address' {
                It 'Should return $null' {
                    $setTargetResourceParameters = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    {
                        $result = Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw

                    $result | Should -BeNullOrEmpty
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                    Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
                    Assert-MockCalled -commandName New-NetRoute -Exactly 1
                }
            }
        }

        Describe 'DSC_DefaultGatewayAddress\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith {
                    [PSObject] @{
                        Name = 'Ethernet'
                    }
                }
            }

            Context 'When checking return with default gateway that matches currently set one' {
                Mock -CommandName Get-NetRoute -MockWith $getNetRouteIpv4_Mock

                It 'Should return true' {
                    $testTargetResourceParameters = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true
                }
            }

            Context 'Checking return with no gateway but one is currently set' {
                Mock -CommandName Get-NetRoute -MockWith $getNetRouteIpv4_Mock

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $False
                }
            }

            Context 'Checking return with default gateway but none are currently set' {
                Mock -CommandName Get-NetRoute

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $False
                }
            }

            Context 'Checking return with no gateway and none are currently set' {
                Mock -CommandName Get-NetRoute

                It 'Should return true' {
                    $testTargetResourceParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true
                }
            }
        }

        Describe 'DSC_DefaultGatewayAddress\Assert-ResourceProperty' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith {
                    [PSObject] @{
                        Name = 'Ethernet'
                    }
                }
            }

            Context 'When invoking with bad interface alias' {
                It 'Should throw an InterfaceNotAvailable error' {
                    $assertResourcePropertyParameters = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'NotReal'
                        AddressFamily  = 'IPv4'
                    }

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.InterfaceNotAvailableError -f $assertResourcePropertyParameters.InterfaceAlias)

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $ErrorRecord
                }
            }

            Context 'When invoking with invalid IP Address' {
                It 'Should throw an AddressFormatError error' {
                    $assertResourcePropertyParameters = @{
                        Address        = 'NotReal'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressFormatError -f $assertResourcePropertyParameters.Address) `
                        -ArgumentName 'Address'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $ErrorRecord
                }
            }

            Context 'When invoking with IPv4 Address and family mismatch' {
                It 'Should throw an AddressMismatchError error' {
                    $assertResourcePropertyParameters = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv4MismatchError -f $assertResourcePropertyParameters.Address, $assertResourcePropertyParameters.AddressFamily) `
                        -ArgumentName 'AddressFamily'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $ErrorRecord
                }
            }

            Context 'When invoking with IPv6 Address and family mismatch' {
                It 'Should throw an AddressMismatchError error' {
                    $assertResourcePropertyParameters = @{
                        Address        = 'fe80::'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv6MismatchError -f $assertResourcePropertyParameters.Address, $assertResourcePropertyParameters.AddressFamily) `
                        -ArgumentName 'AddressFamily'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $ErrorRecord
                }
            }

            Context 'When invoking with valid IPv4 Address' {
                It 'Should not throw an error' {
                    $assertResourcePropertyParameters = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
                }
            }

            Context 'When invoking with valid IPv6 Address' {
                It 'Should not throw an error' {
                    $assertResourcePropertyParameters = @{
                        Address        = 'fe80:ab04:30F5:002b::1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
                }
            }
        }

        Describe 'DSC_DefaultGatewayAddress\Get-NetDefaultGatewayDestinationPrefix' {
            Context 'When the AddressFamily is IPv4' {
                It 'Should return current default gateway' {
                    Get-NetDefaultGatewayDestinationPrefix -AddressFamily 'IPv4' | Should -Be '0.0.0.0/0'
                }
            }

            Context 'When the AddressFamily is IPv6' {
                It 'Should return current default gateway' {
                    Get-NetDefaultGatewayDestinationPrefix -AddressFamily 'IPv6' | Should -Be '::/0'
                }
            }
        }

        Describe 'DSC_DefaultGatewayAddress\Get-NetDefaultRoute' {
            Context 'When interface has a default gateway set' {
                Mock -CommandName Get-NetRoute -MockWith {
                    [PSCustomObject] @{
                        NextHop           = '192.168.0.1'
                        DestinationPrefix = '0.0.0.0/0'
                        InterfaceAlias    = 'Ethernet'
                        InterfaceIndex    = 1
                        AddressFamily     = 'IPv4'
                    }
                }

                It 'Should return current default gateway' {
                    $GetNetDefaultRouteParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Get-NetDefaultRoute @GetNetDefaultRouteParameters

                    $result.NextHop | Should -Be '192.168.0.1'
                }
            }

            Context 'When interface has no default gateway set' {
                Mock -CommandName Get-NetRoute

                It 'Should return no default gateway' {
                    $GetNetDefaultRouteParameters = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Get-NetDefaultRoute @GetNetDefaultRouteParameters

                    $result | Should -BeNullOrEmpty
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
