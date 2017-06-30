$script:DSCModuleName      = 'xNetworking'
$script:DSCResourceName    = 'MSFT_xDefaultGatewayAddress'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
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
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        Describe 'MSFT_xDefaultGatewayAddress\Get-TargetResource' {
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

            Context 'Checking return with default gateway' {
                It 'Should return current default gateway' {
                    $splat = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    $result = Get-TargetResource @splat

                    $result.Address | Should Be '192.168.0.1'
                }
            }

            #region Mocks
            Mock Get-NetRoute -MockWith {}
            #endregion

            Context 'Checking return with no default gateway' {
                It 'Should return no default gateway' {
                    $splat = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    $result = Get-TargetResource @splat

                    $result.Address | Should BeNullOrEmpty
                }
            }
        }

        Describe 'MSFT_xDefaultGatewayAddress\Set-TargetResource' {
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

            Context 'Invoking with no Default Gateway Address' {
                It 'Should return $null' {
                    $splat = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    { $result = Set-TargetResource @splat } | Should Not Throw

                    $result | Should BeNullOrEmpty
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                    Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
                    Assert-MockCalled -commandName New-NetRoute -Exactly 0
                }
            }

            Context 'Invoking with valid Default Gateway Address' {
                It 'Should return $null' {
                    $splat = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    { $result = Set-TargetResource @splat } | Should Not Throw

                    $result | Should BeNullOrEmpty
                }

                It 'Should call all the mocks' {
                    Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                    Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
                    Assert-MockCalled -commandName New-NetRoute -Exactly 1
                }
            }
        }

        Describe 'MSFT_xDefaultGatewayAddress\Test-TargetResource' {
            #region Mocks
            Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }

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

            Context 'Checking return with default gateway that matches currently set one' {
                It 'Should return true' {
                    $splat = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    Test-TargetResource @splat | Should Be $True
                }
            }

            Context 'Checking return with no gateway but one is currently set' {
                It 'Should return false' {
                    $splat = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    Test-TargetResource @splat | Should Be $False
                }
            }

            #region Mocks
            Mock Get-NetRoute -MockWith {}
            #endregion

            Context 'Checking return with default gateway but none are currently set' {
                It 'Should return false' {
                    $splat = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    Test-TargetResource @splat | Should Be $False
                }
            }

            Context 'Checking return with no gateway and none are currently set' {
                It 'Should return true' {
                    $splat = @{
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    Test-TargetResource @splat | Should Be $True
                }
            }
        }

        Describe 'MSFT_xDefaultGatewayAddress\Assert-ResourceProperty' {

            Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }

            Context 'Invoking with bad interface alias' {
                It 'Should throw an InterfaceNotAvailable error' {
                    $splat = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'NotReal'
                        AddressFamily = 'IPv4'
                    }

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.InterfaceNotAvailableError -f $splat.InterfaceAlias)

                    { Assert-ResourceProperty @splat } | Should Throw $ErrorRecord
                }
            }

            Context 'Invoking with invalid IP Address' {
                It 'Should throw an AddressFormatError error' {
                    $splat = @{
                        Address = 'NotReal'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.AddressFormatError -f $splat.Address) `
                        -ArgumentName 'Address'

                    { Assert-ResourceProperty @splat } | Should Throw $ErrorRecord
                }
            }

            Context 'Invoking with IPv4 Address and family mismatch' {
                It 'Should throw an AddressMismatchError error' {
                    $splat = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.AddressIPv4MismatchError -f $splat.Address,$splat.AddressFamily) `
                        -ArgumentName 'AddressFamily'

                    { Assert-ResourceProperty @splat } | Should Throw $ErrorRecord
                }
            }

            Context 'Invoking with IPv6 Address and family mismatch' {
                It 'Should throw an AddressMismatchError error' {
                    $splat = @{
                        Address = 'fe80::'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.AddressIPv6MismatchError -f $splat.Address,$splat.AddressFamily) `
                        -ArgumentName 'AddressFamily'

                    { Assert-ResourceProperty @splat } | Should Throw $ErrorRecord
                }
            }

            Context 'Invoking with valid IPv4 Address' {
                It 'Should not throw an error' {
                    $splat = @{
                        Address = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }

                    { Assert-ResourceProperty @splat } | Should Not Throw
                }
            }

            Context 'Invoking with valid IPv6 Address' {
                It 'Should not throw an error' {
                    $splat = @{
                        Address = 'fe80:ab04:30F5:002b::1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }

                    { Assert-ResourceProperty @splat } | Should Not Throw
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
