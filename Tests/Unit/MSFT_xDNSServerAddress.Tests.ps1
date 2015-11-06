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

    #######################################################################################

    Describe 'Get-TargetResource' {

        # Test IPv4

        #region Mocks
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = '192.168.0.1'
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv4'
            }
        }
        #endregion

        Context 'invoking with an IPv4 address' {
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

        # Test IPv6 

        #region Mocks
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = 'fe80:ab04:30F5:002b::1'
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv6'
            }
        }
        #endregion

        Context 'invoking with an IPv6 address' {
            It 'should return true' {

                $Splat = @{
                    Address = 'fe80:ab04:30F5:002b::1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                $Result = Get-TargetResource @Splat
                $Result.IPAddress | Should Be $Splat.IPAddress
            }
        }

    }

    #######################################################################################

    Describe 'Set-TargetResource' {

        # Test IPv4

        #region Mocks
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = @('192.168.0.1')
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv4'
            }
        }
        Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $true }
        Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $false }
        #endregion

        Context 'invoking with single IPv4 Server Address that is the same as current' {
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
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $false }
            }
        }
        Context 'invoking with single IPv4 Server Address that is different to current' {
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
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
            }
        }
        Context 'invoking with single IPv4 Server Address that is different to current and validate true' {
            It 'should not throw an exception' {

                $Splat = @{
                    Address = @('192.168.0.2')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                    Validate = $True
                }
                { Set-TargetResource @Splat } | Should Not Throw
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $true }
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $false }
            }
        }        
        Context 'invoking with multiple IPv4 Server Addresses that are different to current' {
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
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
            }
        }

        #region Mocks
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = @()
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv4'
            }
        }
        #endregion

        Context 'invoking with multiple IPv4 Server Addresses When there are no address assiged' {
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
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
            }
        }

        # Test IPv6 

        #region Mocks
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = @('fe80:ab04:30F5:002b::1')
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv6'
            }
        }
        Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $true }
        Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $false }
        #endregion

        Context 'invoking with single IPv6 Server Address that is the same as current' {
            It 'should not throw an exception' {

                $Splat = @{
                    Address = @('fe80:ab04:30F5:002b::1')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                { Set-TargetResource @Splat } | Should Not Throw
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $false }
            }
        }
        Context 'invoking with single IPv6 Server Address that is different to current' {
            It 'should not throw an exception' {

                $Splat = @{
                    Address = @('fe80:ab04:30F5:002b::2')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                { Set-TargetResource @Splat } | Should Not Throw
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
            }
        }
        Context 'invoking with single IPv6 Server Address that is different to current and validate true' {
            It 'should not throw an exception' {

                $Splat = @{
                    Address = @('fe80:ab04:30F5:002b::2')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                    Validate = $True
                }
                { Set-TargetResource @Splat } | Should Not Throw
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $true }
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $false }
            }
        }
        Context 'invoking with multiple IPv6 Server Addresses that are different to current' {
            It 'should not throw an exception' {

                $Splat = @{
                    Address = @('fe80:ab04:30F5:002b::1','fe80:ab04:30F5:002b::2')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                { Set-TargetResource @Splat } | Should Not Throw
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
            }
        }

        #region Mocks
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = @()
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv6'
            }
        }
        #endregion

        Context 'invoking with multiple IPv6 Server Addresses When there are no address assiged' {
            It 'should not throw an exception' {

                $Splat = @{
                    Address = @('fe80:ab04:30F5:002b::1','fe80:ab04:30F5:002b::1')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                { Set-TargetResource @Splat } | Should Not Throw
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
            }
        }
    }

    #######################################################################################

    Describe 'Test-TargetResource' {

        # Test IPv4 

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

        Context 'invoking with single IPv4 Server Address that is the same as current' {
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
        Context 'invoking with single IPv4 Server Address that is different to current' {
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
        Context 'invoking with multiple IPv4 Server Addresses that are different to current' {
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

        #region Mocks
        Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = @()
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv4'
            }
        }
        #endregion

        Context 'invoking with multiple IPv4 Server Addresses that are no addresses assigned' {
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

        # Test IPv6 

        #region Mocks
        Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = @('fe80:ab04:30F5:002b::1')
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv6'
            }
        }
        #endregion

        Context 'invoking with single IPv6 Server Address that is the same as current' {
            It 'should return true' {

                $Splat = @{
                    Address = @('fe80:ab04:30F5:002b::1')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                Test-TargetResource @Splat | Should Be $True
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
            }
        }
        Context 'invoking with single IPv6 Server Address that is different to current' {
            It 'should return false' {

                $Splat = @{
                    Address = @('fe80:ab04:30F5:002b::2')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                Test-TargetResource @Splat | Should Be $False
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
            }
        }
        Context 'invoking with multiple IPv6 Server Addresses that are different to current' {
            It 'should return false' {

                $Splat = @{
                    Address = @('fe80:ab04:30F5:002b::1','fe80:ab04:30F5:002b::2')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                Test-TargetResource @Splat | Should Be $False
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
            }
        }

        #region Mocks
        Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
        Mock Get-DnsClientServerAddress -MockWith {

            [PSCustomObject]@{
                ServerAddresses = @()
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv6'
            }
        }
        #endregion

        Context 'invoking with multiple IPv6 Server Addresses that are no addresses assigned' {
            It 'should return false' {

                $Splat = @{
                    Address = @('fe80:ab04:30F5:002b::1','fe80:ab04:30F5:002b::2')
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv6'
                }
                Test-TargetResource @Splat | Should Be $False
            }
            It 'should call all the mocks' {
                Assert-MockCalled -commandName Get-DnsClientServerAddress -Exactly 1
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

        Context 'invoking with valid IPv4 Addresses' {

            It 'should not throw an error' {
                $Splat = @{
                    Address = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    AddressFamily = 'IPv4'
                }
                { Test-ResourceProperty @Splat } | Should Not Throw
            }
        }

        Context 'invoking with valid IPv6 Addresses' {

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
