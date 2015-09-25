$DSCResourceName = 'MSFT_xIPAddress'
$DSCModuleName   = 'xNetworking'

$Splat = @{
    Path = $PSScriptRoot
    ChildPath = "..\..\DSCResources\$DSCResourceName\$DSCResourceName.psm1"
    Resolve = $true
    ErrorAction = 'Stop'
}

$DSCResourceModuleFile = Get-Item -Path (Join-Path @Splat)

if (Get-Module -Name $DSCResourceName)
{
    Remove-Module -Name $DSCResourceName
}

Import-Module -Name $DSCResourceModuleFile.FullName -Force

$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

if(-not (Test-Path -Path $moduleRoot))
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
}
else
{
    # Copy the existing folder out to the temp directory to hold until the end of the run
    # Delete the folder to remove the old files.
    $tempLocation = Join-Path -Path $env:Temp -ChildPath $DSCModuleName
    Copy-Item -Path $moduleRoot -Destination $tempLocation -Recurse -Force
    Remove-Item -Path $moduleRoot -Recurse -Force
    $null = New-Item -Path $moduleRoot -ItemType Directory
}

Copy-Item -Path $PSScriptRoot\..\..\* -Destination $moduleRoot -Recurse -Force -Exclude '.git'

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
            It 'should return correct IP' {

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

                 { Get-TargetResource @Splat } |
                    Should Throw "Value was either too large or too small for a UInt32."
            }
        }
    }


    Describe 'Test-Properties' {

        #region Mocks
        Mock Get-NetIPAddress -MockWith {
            [PSCustomObject]@{
                IPAddress = '192.168.0.1'
                InterfaceAlias = 'Ethernet'
                InterfaceIndex = 1
                PrefixLength = [byte]16
                AddressFamily = 'IPv4'
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

        Mock Get-NetRoute {
            [PSCustomObject]@{
                InterfaceAlias = 'Ethernet'
                InterfaceIndex = 1
                AddressFamily = 'IPv4'
                NextHop = '192.168.0.254'
                DestinationPrefix = '0.0.0.0/0'
            }
        }

        Mock Get-NetIPInterface {
            [PSCustomObject]@{
                InterfaceAlias = 'Ethernet'
                InterfaceIndex = 1
                AddressFamily = 'IPv4'
                Dhcp = 'Disabled'
            }
        }

        Mock Set-NetConnectionProfile {}

        Mock Remove-NetIPAddress {}

        Mock Remove-NetRoute {}
        #endregion

        Context 'invoking with invalid IPAddress' {

            It 'should throw an error' {
                $Splat = @{
                    IPAddress = 'NotReal'
                    InterfaceAlias = 'Ethernet'
                }
                { Test-Properties @Splat } | Should Throw
            }
        }

        Context 'invoking with IPAddress mismatch' {

            It 'should be throw an error' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                { Test-Properties @Splat } | Should Throw
            }
        }

        Context 'invoking without -Apply switch' {
            It 'should be $false' {
                $Splat = @{
                    IPAddress = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                }
                $Result = Test-Properties @Splat
                $Result | Should Be $false
            }

            It 'should be $true' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                }
                $Result = Test-Properties @Splat
                $Result | Should Be $true
            }

            It 'should call Get-NetIPAddress once' {
                Assert-MockCalled -CommandName Get-NetIPAddress
            }

            It 'should not call Get-NetRoute' {
                Assert-MockCalled -commandName Get-NetRoute -Exactly 0
            }

            It 'should call Get-NetIPInterface once' {
                Assert-MockCalled -CommandName Get-NetIPInterface
            }
        }

        Context 'invoking with -Apply switch' {

            It 'should be $null' {
                $Splat = @{
                    IPAddress = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                }
                $Result = Test-Properties @Splat -Apply
                $Result | Should BeNullOrEmpty
            }

            It 'should call all the mocks' {
                Assert-MockCalled -CommandName Get-NetIPAddress
                Assert-MockCalled -CommandName Get-NetConnectionProfile
                Assert-MockCalled -CommandName Get-NetRoute
                Assert-MockCalled -CommandName Get-NetIPInterface
                Assert-MockCalled -CommandName Remove-NetRoute
                Assert-MockCalled -CommandName Remove-NetIPAddress
                Assert-MockCalled -CommandName New-NetIPAddress
                Assert-MockCalled -CommandName Set-NetConnectionProfile
            }
        }
    }
}

# Cleanup after the test
Remove-Item -Path $moduleRoot -Recurse -Force

# Restore previous versions, if it exists.
if ($tempLocation)
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
    $script:Destination = "${env:ProgramFiles}\WindowsPowerShell\Modules"
    Copy-Item -Path $tempLocation -Destination $script:Destination -Recurse -Force
    Remove-Item -Path $tempLocation -Recurse -Force
}
