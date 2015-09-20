$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (Get-Module MSFT_xDNSServerAddress -All)
{
    Get-Module MSFT_xDNSServerAddress -All | Remove-Module
}

Import-Module -Name $PSScriptRoot\..\DSCResources\MSFT_xDNSServerAddress -Force -DisableNameChecking

InModuleScope MSFT_xDNSServerAddress {

#######################################################################################

    Describe 'Get-TargetResource' {

        #region Mocks
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = '192.168.0.1'
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv4'
            }
        }
        #endregion

        Context 'comparing IPAddress' {
            It 'should return true' {

                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = Get-TargetResource @Splat
                $Result.IPAddress | Should Be $Splat.IPAddress
            }
        }
    }

#######################################################################################

    Describe 'Set-TargetResource' {

        #region Mocks
        Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = @('192.168.0.1')
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv4'
            }
        }
        Mock Set-DnsClientServerAddress
        #endregion

        Context 'invoking with single Server Address that is the same as current' {
            It 'should not throw an exception' {

                $Splat = @{
                    Address = @('192.168.0.1')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { Set-TargetResource @Splat } | Should Not Throw
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0
            }
        }
        Context 'invoking with single Server Address that is different to current' {
            It 'should not throw an exception' {

                $Splat = @{
                    Address = @('192.168.0.2')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { Set-TargetResource @Splat } | Should Not Throw
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1
            }
        }
        Context 'invoking with multiple Server Addresses that are different to current' {
            It 'should not throw an exception' {

                $Splat = @{
                    Address = @('192.168.0.2','192.168.0.3')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { Set-TargetResource @Splat } | Should Not Throw
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1
            }
        }
    }

#######################################################################################

    Describe 'Test-TargetResource' {

        #region Mocks
        Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = @('192.168.0.1')
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv4'
            }
        }
        #endregion

        Context 'invoking with single Server Address that is the same as current' {
            It 'should return true' {

                $Splat = @{
                    Address = @('192.168.0.1')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                Test-TargetResource @Splat | Should Be $True
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
            }
        }
        Context 'invoking with single Server Address that is different to current' {
            It 'should return false' {

                $Splat = @{
                    Address = @('192.168.0.2')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                Test-TargetResource @Splat | Should Be $False
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
            }
        }
        Context 'invoking with multiple Server Addresses that are different to current' {
            It 'should return false' {

                $Splat = @{
                    Address = @('192.168.0.2','192.168.0.3')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                Test-TargetResource @Splat | Should Be $False
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
            }
        }
    }

#######################################################################################

    Describe 'Validate-DNSServerAddress' {

        Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }

        Context 'invoking with bad interface alias' {

            It 'should throw an error' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'NotReal'
                    AddressFamily = 'IPv4'
                }
                { Validate-DNSServerAddress @Splat } | Should Throw
            }
        }

        Context 'invoking with invalid IP Address' {

            It 'should throw an error' {
                $Splat = @{
                    Address = 'NotReal'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { Validate-DNSServerAddress @Splat } | Should Throw
            }
        }

        Context 'invoking with invalid IP Address' {

            It 'should throw an error' {
                $Splat = @{
                    Address = 'NotReal'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { Validate-DNSServerAddress @Splat } | Should Throw
            }
        }

        Context 'invoking with IP Address and family mismatch' {

            It 'should throw an error' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                { Validate-DNSServerAddress @Splat } | Should Throw
            }
        }

        Context 'invoking with valid IPv4 Addresses' {

            It 'should not throw an error' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { Validate-DNSServerAddress @Splat } | Should Not Throw
            }
        }

        Context 'invoking with valid IPv6 Addresses' {

            It 'should not throw an error' {
                $Splat = @{
                    Address = 'fe80:ab04:30F5:002b::1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                { Validate-DNSServerAddress @Splat } | Should Not Throw
            }
        }
    }
}

#######################################################################################
