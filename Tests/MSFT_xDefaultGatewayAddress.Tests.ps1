$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (Get-Module MSFT_xDefaultGatewayAddress -All)
{
    Get-Module MSFT_xDefaultGatewayAddress -All | Remove-Module
}

Import-Module -Name $PSScriptRoot\..\DSCResources\MSFT_xDefaultGatewayAddress -Force -DisableNameChecking

InModuleScope MSFT_xDefaultGatewayAddress {

#######################################################################################

    Describe 'Get-TargetResource' {

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

        Context 'checking return with default gateway' {
            It 'should return current default gateway' {

                $Splat = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = Get-TargetResource @Splat
                $Result.Address | Should Be '192.168.0.1'
            }
        }

        #region Mocks
        Mock Get-NetRoute -MockWith {}
        #endregion

        Context 'checking return with no default gateway' {
            It 'should return no default gateway' {

                $Splat = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = Get-TargetResource @Splat
                $Result.Address | Should BeNullOrEmpty
            }
        }
    }

#######################################################################################

    Describe 'Set-TargetResource' {

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

        Mock Remove-NetRoute

        Mock New-NetRoute

        #endregion

        Context 'invoking with no Default Gateway Address' {
            It 'should rerturn $null' {
                $Splat = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { $Result = Set-TargetResource @Splat } | Should Not Throw
                $Result | Should BeNullOrEmpty
            }

            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
            }
        }

        Context 'invoking with valid Default Gateway Address' {
            It 'should rerturn $null' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { $Result = Set-TargetResource @Splat } | Should Not Throw
                $Result | Should BeNullOrEmpty
            }

            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
                Assert-MockCalled -commandName New-NetRoute -Exactly 1
            }
        }
    }

#######################################################################################

    Describe 'Test-TargetResource' {

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

        Context 'checking return with default gateway that matches currently set one' {
            It 'should return true' {

                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                Test-TargetResource @Splat | Should Be $True
            }
        }

        Context 'checking return with no gateway but one is currently set' {
            It 'should return false' {

                $Splat = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                Test-TargetResource @Splat | Should Be $False
            }
        }

        #region Mocks
        Mock Get-NetRoute -MockWith {}
        #endregion

        Context 'checking return with default gateway but none are currently set' {
            It 'should return false' {

                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                Test-TargetResource @Splat | Should Be $False
            }
        }

        Context 'checking return with no gateway and none are currently set' {
            It 'should return true' {

                $Splat = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                Test-TargetResource @Splat | Should Be $True
            }
        }
    }

#######################################################################################

    Describe 'Test-ResourceProperty' {

        Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }

        Context 'invoking with bad interface alias' {

            It 'should throw an error' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'NotReal'
                    AddressFamily = 'IPv4'
                }
                { Test-ResourceProperty @Splat } | Should Throw
            }
        }

        Context 'invoking with invalid IP Address' {

            It 'should throw an error' {
                $Splat = @{
                    Address = 'NotReal'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { Test-ResourceProperty @Splat } | Should Throw
            }
        }

        Context 'invoking with invalid IP Address' {

            It 'should throw an error' {
                $Splat = @{
                    Address = 'NotReal'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { Test-ResourceProperty @Splat } | Should Throw
            }
        }

        Context 'invoking with IP Address and family mismatch' {

            It 'should throw an error' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                { Test-ResourceProperty @Splat } | Should Throw
            }
        }

        Context 'invoking with valid IPv4 Address' {

            It 'should not throw an error' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { Test-ResourceProperty @Splat } | Should Not Throw
            }
        }

        Context 'invoking with valid IPv6 Address' {

            It 'should not throw an error' {
                $Splat = @{
                    Address = 'fe80:ab04:30F5:002b::1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                { Test-ResourceProperty @Splat } | Should Not Throw
            }
        }
    }
}

#######################################################################################
