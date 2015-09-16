$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (Get-Module MSFT_xDefaultGatewayAddress -All)
{
    Get-Module MSFT_xDefaultGatewayAddress -All | Remove-Module
}

Import-Module -Name $PSScriptRoot\..\DSCResources\MSFT_xDefaultGatewayAddress -Force -DisableNameChecking

InModuleScope MSFT_xDefaultGatewayAddress {

    Describe 'Get-TargetResource' {

        #region Mocks
        Mock Get-NetRoute -MockWith {
            [PSCustomObject]@{
                NextHop = '192.168.0.1'
                DestinationPrefix = '0.0.0.0/0'
                InterfaceAlias = 'Ethernet'
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

    Describe 'ValidateProperties' {

        Context 'invoking without -Apply switch and default gateway is set' {

            #region Mocks
            Mock Get-NetRoute -MockWith {
                [PSCustomObject]@{
                    NextHop = '192.168.0.1'
                    DestinationPrefix = '0.0.0.0/0'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
            }
            #endregion

            It 'when default gateway does not match should be $false' {
                $Splat = @{
                    Address = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $false
            }

            It 'when default gateway matches should be $true' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $true
            }

            It 'when default gateway is not passed should be $false' {
                $Splat = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $false
            }

            It 'should call Get-NetRoute three times' {
                Assert-MockCalled -commandName Get-NetRoute -Exactly 3
            }
        }

        Context 'invoking without -Apply switch and default gateway is not set' {

            #region Mocks
            Mock Get-NetRoute -MockWith {
                [PSCustomObject]@{
                    NextHop = '192.168.0.1'
                    DestinationPrefix = '0.0.0.0/0'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
            }
            #endregion

            It 'when default gateway exists should be $false' {
                $Splat = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $false
            }

            #region Mocks
            Mock Get-NetRoute
            #endregion

            It 'when default gateway does not exist should be $true' {
                $Splat = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $true
            }

            It 'should call Get-NetRoute twice' {
                Assert-MockCalled -commandName Get-NetRoute -Exactly 2
            }
        }

        Context 'invoking with -Apply switch and default gateway is set' {

            #region Mocks
            Mock Get-NetRoute -MockWith {
                [PSCustomObject]@{
                    NextHop = '192.168.0.1'
                    DestinationPrefix = '0.0.0.0/0'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
            }
            Mock New-NetRoute
            Mock Remove-NetRoute
            #endregion

            It 'when default gateway does not match should be $true' {
                $Splat = @{
                    Apply = $true
                    Address = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $true
            }

            It 'when default gateway matches should be $true' {
                $Splat = @{
                    Apply = $true
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $true
            }

            It 'when default gateway is not passed should be $true' {
                $Splat = @{
                    Apply = $true
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $true
            }

            It 'should call Get-NetRoute three times' {
                Assert-MockCalled -commandName Get-NetRoute -Exactly 3
            }
            It 'should call Remove-NetRoute two times' {
                Assert-MockCalled -commandName Remove-NetRoute -Exactly 2
            }
            It 'should call New-NetRoute once' {
                Assert-MockCalled -commandName New-NetRoute -Exactly 1
            }
        }

        Context 'invoking with -Apply switch and default gateway is not set' {

            #region Mocks
            Mock Get-NetRoute -MockWith {
                [PSCustomObject]@{
                    NextHop = '192.168.0.1'
                    DestinationPrefix = '0.0.0.0/0'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
            }
            Mock New-NetRoute
            Mock Remove-NetRoute
            #endregion

            It 'when default gateway exists should be $true' {
                $Splat = @{
                    Apply = $True
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $true
            }

            It 'when default gateway does not exist should be $true' {
                $Splat = @{
                    Apply = $True
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $true
            }

            It 'should call Get-NetRoute two times' {
                Assert-MockCalled -commandName Get-NetRoute -Exactly 2
            }
            It 'should call Remove-NetRoute once' {
                Assert-MockCalled -commandName Remove-NetRoute -Exactly 2
            }
            It 'should not call New-NetRoute' {
                Assert-MockCalled -commandName New-NetRoute -Exactly 0
            }
        }
    }
}
