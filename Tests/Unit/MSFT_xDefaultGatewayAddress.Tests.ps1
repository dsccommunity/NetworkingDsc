$DSCResourceName = 'MSFT_xDefaultGatewayAddress'
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
            It 'should return $null' {
                $Splat = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { $Result = Set-TargetResource @Splat } | Should Not Throw
                $Result | Should BeNullOrEmpty
            }

            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
                Assert-MockCalled -commandName New-NetRoute -Exactly 0
            }
        }

        Context 'invoking with valid Default Gateway Address' {
            It 'should return $null' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { $Result = Set-TargetResource @Splat } | Should Not Throw
                $Result | Should BeNullOrEmpty
            }

            It 'should call all the mocks' {
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

            It 'should throw an InterfaceNotAvailable error' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'NotReal'
                    AddressFamily = 'IPv4'
                }
                $errorId = 'InterfaceNotAvailable'
                $errorCategory = [System.Management.Automation.ErrorCategory]::DeviceError
                $errorMessage = $($LocalizedData.InterfaceNotAvailableError) -f $Splat.InterfaceAlias
                $exception = New-Object -TypeName System.InvalidOperationException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                { Test-ResourceProperty @Splat } | Should Throw $ErrorRecord
            }
        }

        Context 'invoking with invalid IP Address' {

            It 'should throw an AddressFormatError error' {
                $Splat = @{
                    Address = 'NotReal'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $errorId = 'AddressFormatError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                $errorMessage = $($LocalizedData.AddressFormatError) -f $Splat.Address
                $exception = New-Object -TypeName System.InvalidOperationException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                { Test-ResourceProperty @Splat } | Should Throw $ErrorRecord
            }
        }

        Context 'invoking with IPv4 Address and family mismatch' {

            It 'should throw an AddressMismatchError error' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                $errorId = 'AddressMismatchError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                $errorMessage = $($LocalizedData.AddressIPv4MismatchError) -f $Splat.Address,$Splat.AddressFamily
                $exception = New-Object -TypeName System.InvalidOperationException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                { Test-ResourceProperty @Splat } | Should Throw $ErrorRecord
            }
        }

        Context 'invoking with IPv6 Address and family mismatch' {

            It 'should throw an AddressMismatchError error' {
                $Splat = @{
                    Address = 'fe80::'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $errorId = 'AddressMismatchError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                $errorMessage = $($LocalizedData.AddressIPv6MismatchError) -f $Splat.Address,$Splat.AddressFamily
                $exception = New-Object -TypeName System.InvalidOperationException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                { Test-ResourceProperty @Splat } | Should Throw $ErrorRecord
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

# Clean up after the test completes.
Remove-Item -Path $moduleRoot -Recurse -Force

# Restore previous versions, if it exists.
if ($tempLocation)
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
    $script:Destination = "${env:ProgramFiles}\WindowsPowerShell\Modules"
    Copy-Item -Path $tempLocation -Destination $script:Destination -Recurse -Force
    Remove-Item -Path $tempLocation -Recurse -Force
}
