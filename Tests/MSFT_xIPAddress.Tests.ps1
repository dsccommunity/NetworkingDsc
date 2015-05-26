Remove-Module -Name MSFT_xIPAddress -Force -ErrorAction SilentlyContinue
Import-Module -Name $PSScriptRoot\..\DSCResources\MSFT_xIPAddress -Force -DisableNameChecking

if (! (Get-Module xDSCResourceDesigner))
{
    Import-Module -Name xDSCResourceDesigner -ErrorAction SilentlyContinue
}

InModuleScope MSFT_xIPAddress {

    Describe 'Get-TargetResource' {
    
        #region Mocks
        Mock Get-NetIPAddress {

            [PSCustomObject]@{
                IPAddress = '192.168.0.1'
            }
        }
        #endregion

        Context 'comparing IPAddress' {
            It 'should return true' {

                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                }
                $Result = Get-TargetResource @Splat
                $Result.IPAddress | Should Be $Splat.IPAddress
            }
        }

        Context 'Subnet Mask' {
            It 'should fail if passed a negative number' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    Subnet = -16
                }

                { Get-TargetResource @Splat } | Should throw
            }
        }
    }


    Describe 'ValidateProperties' {

        #region Mocks
        Mock Get-NetIPAddress -MockWith {
            
            [PSCustomObject]@{
                IPAddress = '192.168.0.1'
                InterfaceAlias = 'Ethernet'
            }
        }
        
        Mock New-NetIPAddress -MockWith {}
        
        Mock Get-NetConnectionProfile {
            [PSCustomObject]@{
                Name = 'MSFT'
                InterfaceAlias = 'Ethernet'
                InterfaceIndex = 1
                NetworkCategory = 'Public'
                IPV4Connectivity = 'Internet'
                IPV6Connectivity = 'NoTraffic'
            }
        }
        
        Mock Set-NetConnectionProfile {}
        #endregion
        
        Context 'invoking without -Apply switch' {
            
            It 'should be $false' {
                $Splat = @{
                    IPAddres = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $false
            }
            
            It 'should be $true' {
                $Splat = @{
                    IPAddres = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $true
            }
        }
        
        Context 'invoking with -Apply switch' {
            
            It 'should be $null' {
                $Splat = @{
                    IPAddres = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                }
                $Result = ValidateProperties @Splat -Apply
                $Result | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Schema Validation MSFT_xIPAddress' {
        $result = Test-xDscResource MSFT_xIPAddress
        It 'should pass Test-xDscResource' {
            $result | Should Be $true
        }
    }
}