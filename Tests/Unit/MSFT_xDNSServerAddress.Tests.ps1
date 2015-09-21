$DSCResourceName = 'MSFT_xDNSServerAddress'
$DSCModuleName   = 'xNetworking'

$Splat = @{
    Path = $PSScriptRoot
    ChildPath = "..\..\DSCResources\$DSCResourceName\$DSCResourceName.psm1"
    Resolve = $true
    ErrorAction = 'Stop'
}

$DSCResourceModuleFile = Get-Item -Path (Join-Path @Splat)

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

if (Get-Module -Name $DSCResourceName)
{
    Remove-Module -Name $DSCResourceName
}

Import-Module -Name $DSCResourceModuleFile.FullName -Force

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

    Describe 'Test-Properties' {
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
                $Result = Test-Properties @Splat
                $Result | Should Be $false
            }

            It 'should be $true' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = Test-Properties @Splat
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
                $Result = Test-Properties @Splat -Apply
                $Result | Should BeNullOrEmpty
            }

            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress
                Assert-MockCalled -commandName Set-DnsClientServerAddress
            }
        }
    }
}
