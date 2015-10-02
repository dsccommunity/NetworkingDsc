$DSCResourceName = 'MSFT_xIPAddress'
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

InModuleScope MSFT_xIPAddress {

    #######################################################################################

    Describe 'Get-TargetResource' {

        #region Mocks
        Mock Get-NetIPAddress -MockWith {
            [PSCustomObject]@{
                IPAddress = '192.168.0.1'
                InterfaceAlias = 'Ethernet'
                InterfaceIndex = 1
                PrefixLength = [byte]24
                AddressFamily = 'IPv4'
            }
        }
        #endregion

        Context 'invoking' {
            It 'should return existing IP details' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = Get-TargetResource @Splat
                $Result.IPAddress | Should Be $Splat.IPAddress
                $Result.SubnetMask | Should Be 24
            }
        }

        Context 'Subnet Mask' {
            It 'should fail if passed a negative number' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    Subnet = -16
                }

                { Get-TargetResource @Splat } `
                    | Should Throw 'Value was either too large or too small for a UInt32.'
            }
        }
    }

    #######################################################################################

    Describe 'Set-TargetResource' {

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

        Mock New-NetIPAddress

        Mock Get-NetRoute {
            [PSCustomObject]@{
                InterfaceAlias = 'Ethernet'
                InterfaceIndex = 1
                AddressFamily = 'IPv4'
                NextHop = '192.168.0.254'
                DestinationPrefix = '0.0.0.0/0'
            }
        }

        Mock Remove-NetIPAddress

        Mock Remove-NetRoute
        #endregion

        Context 'invoking with valid IP Address' {

            It 'should rerturn $null' {
                $Splat = @{
                    IPAddress = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { $Result = Set-TargetResource @Splat } | Should Not Throw
                $Result | Should BeNullOrEmpty
            }

            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
                Assert-MockCalled -commandName Remove-NetIPAddress -Exactly 1
                Assert-MockCalled -commandName New-NetIPAddress -Exactly 1
            }
        }
    }

    #######################################################################################

    Describe 'Test-TargetResource' {


        #region Mocks
        Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }

        Mock Get-NetIPAddress -MockWith {

            [PSCustomObject]@{
                IPAddress = '192.168.0.1'
                InterfaceAlias = 'Ethernet'
                InterfaceIndex = 1
                PrefixLength = [byte]16
                AddressFamily = 'IPv4'
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
        #endregion

        Context 'invoking with invalid IPv4 Address' {

            It 'should throw an AddressFormatError error' {
                $Splat = @{
                    IPAddress = 'BadAddress'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $errorId = 'AddressFormatError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                $errorMessage = $($LocalizedData.AddressFormatError) -f $Splat.IPAddress
                $exception = New-Object -TypeName System.InvalidOperationException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                { $Result = Test-TargetResource @Splat } | Should Throw $errorRecord
            }
        }

        Context 'invoking with different IPv4 Address' {

            It 'should be $false' {
                $Splat = @{
                    IPAddress = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = Test-TargetResource @Splat
                $Result | Should Be $false
            }
            It 'should call appropriate mocks' {
                Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                Assert-MockCalled -commandName Get-NetIPInterface -Exactly 1
            }
        }
         
        Context 'invoking with the same IPv4 Address' {

            It 'should be $true' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $Result = Test-TargetResource @Splat
                $Result | Should Be $true
            }
            It 'should call appropriate mocks' {
                Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                Assert-MockCalled -commandName Get-NetIPInterface -Exactly 1
            }
        }

        Mock Get-NetIPAddress -MockWith {

            [PSCustomObject]@{
                IPAddress = 'fe80::1'
                InterfaceAlias = 'Ethernet'
                InterfaceIndex = 1
                PrefixLength = [byte]64
                AddressFamily = 'IPv6'
            }
        }
        Context 'invoking with invalid IPv6 Address' {

            It 'should throw an AddressFormatError error' {
                $Splat = @{
                    IPAddress = 'BadAddress'
                    InterfaceAlias = 'Ethernet'
                    SubnetMask = 64
                    AddressFamily = 'IPv6'
                }
                $errorId = 'AddressFormatError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                $errorMessage = $($LocalizedData.AddressFormatError) -f $Splat.IPAddress
                $exception = New-Object -TypeName System.InvalidOperationException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                { $Result = Test-TargetResource @Splat } | Should Throw $errorRecord
            }
        }

        Context 'invoking with different IPv6 Address' {

            It 'should be $false' {
                $Splat = @{
                    IPAddress = 'fe80::2'
                    InterfaceAlias = 'Ethernet'
                    SubnetMask = 64
                    AddressFamily = 'IPv6'
                }
                $Result = Test-TargetResource @Splat
                $Result | Should Be $false
            }
            It 'should call appropriate mocks' {
                Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                Assert-MockCalled -commandName Get-NetIPInterface -Exactly 1
            }
        }
         
        Context 'invoking with the same IPv6 Address' {

            It 'should be $true' {
                $Splat = @{
                    IPAddress = 'fe80::1'
                    InterfaceAlias = 'Ethernet'
                    SubnetMask = 64
                    AddressFamily = 'IPv6'
                }
                $Result = Test-TargetResource @Splat
                $Result | Should Be $true
            }
            It 'should call appropriate mocks' {
                Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                Assert-MockCalled -commandName Get-NetIPInterface -Exactly 1
            }
        }
    }

    #######################################################################################

    Describe 'Test-ResourceProperty' {

        Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }

        Context 'invoking with bad interface alias' {

            It 'should throw an InterfaceNotAvailable error' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
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

                { Test-ResourceProperty @Splat } | Should Throw $errorRecord
            }
        }

        Context 'invoking with invalid IP Address' {

            It 'should throw an AddressFormatError error' {
                $Splat = @{
                    IPAddress = 'NotReal'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                $errorId = 'AddressFormatError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                $errorMessage = $($LocalizedData.AddressFormatError) -f $Splat.IPAddress
                $exception = New-Object -TypeName System.InvalidOperationException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                { Test-ResourceProperty @Splat } | Should Throw $errorRecord
            }
        }

        Context 'invoking with IP Address and family mismatch' {

            It 'should throw an AddressMismatchError error' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                $errorId = 'AddressMismatchError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                $errorMessage = $($LocalizedData.AddressIPv4MismatchError) -f $Splat.IPAddress,$Splat.AddressFamily
                $exception = New-Object -TypeName System.InvalidOperationException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                { Test-ResourceProperty @Splat } | Should Throw $errorRecord
            }
        }

        Context 'invoking with valid IPv4 Address' {

            It 'should not throw an error' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { Test-ResourceProperty @Splat } | Should Not Throw
            }
        }

        Context 'invoking with valid IPv6 Address' {

            It 'should not throw an error' {
                $Splat = @{
                    IPAddress = 'fe80:ab04:30F5:002b::1'
                    InterfaceAlias = 'Ethernet'
                    SubnetMask = 64
                    AddressFamily = 'IPv6'
                }
                { Test-ResourceProperty @Splat } | Should Not Throw
            }
        }

        Context 'invoking with invalid IPv4 subnet mask' {

            It 'should throw a SubnetMaskError when greater than 32' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    SubnetMask = 33
                    AddressFamily = 'IPv4'
                }
                $errorId = 'SubnetMaskError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                $errorMessage = $($LocalizedData.SubnetMaskError) -f $Splat.SubnetMask,$Splat.AddressFamily
                $exception = New-Object -TypeName System.InvalidOperationException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                { Test-ResourceProperty @Splat } | Should Throw $errorRecord
            }
            It 'should throw an Argument error when less than 0' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    SubnetMask = -1
                    AddressFamily = 'IPv4'
                }
                { Test-ResourceProperty @Splat } `
                    | Should Throw 'Value was either too large or too small for a UInt32.'
            }
        }

        Context 'invoking with invalid IPv6 subnet mask' {

            It 'should throw a SubnetMaskError error when greater than 128' {
                $Splat = @{
                    IPAddress = 'fe80::1'
                    InterfaceAlias = 'Ethernet'
                    SubnetMask = 129
                    AddressFamily = 'IPv6'
                }

                $errorId = 'SubnetMaskError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                $errorMessage = $($LocalizedData.SubnetMaskError) -f $Splat.SubnetMask,$Splat.AddressFamily
                $exception = New-Object -TypeName System.InvalidOperationException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                { Test-ResourceProperty @Splat } | Should Throw $errorRecord
            }
            It 'should throw an Argument error when less than 0' {
                $Splat = @{
                    IPAddress = 'fe80::1'
                    InterfaceAlias = 'Ethernet'
                    SubnetMask = -1
                    AddressFamily = 'IPv6'
                }

                { Test-ResourceProperty @Splat } `
                    | Should Throw 'Value was either too large or too small for a UInt32.'
            }
        }

        Context 'invoking with valid string IPv6 subnet mask' {

            It 'should not throw an error' {
                $Splat = @{
                    IPAddress = 'fe80::1'
                    InterfaceAlias = 'Ethernet'
                    SubnetMask = '64'
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
