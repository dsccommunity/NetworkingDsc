$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (Get-Module MSFT_xDNSServerAddress -All)
{
    Get-Module MSFT_xDNSServerAddress -All | Remove-Module
}

Import-Module -Name $PSScriptRoot\..\DSCResources\MSFT_xDNSServerAddress -Force -DisableNameChecking

InModuleScope MSFT_xDNSServerAddress {

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


    Describe 'ValidateProperties' {

        #region Mocks
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = '192.168.0.1'
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv4'
            }
        }

        Mock Set-DnsClientServerAddress -MockWith {}
        #endregion

        Context 'invoking without -Apply switch' {

            It 'should be $false' {
                $Splat = @{
                    Address = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $false
            }

            It 'should be $true' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $true
            }

            It 'should call Get-DnsClientServerAddress once' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress
            }
        }

        Context 'invoking with -Apply switch' {

            It 'should be $null' {
                $Splat = @{
                    Address = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = ValidateProperties @Splat -Apply
                $Result | Should BeNullOrEmpty
            }

            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress
                Assert-MockCalled -commandName Set-DnsClientServerAddress
            }
        }
    }
}
