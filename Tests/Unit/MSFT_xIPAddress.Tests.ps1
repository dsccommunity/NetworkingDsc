$script:DSCModuleName      = 'xNetworking'
$script:DSCResourceName    = 'MSFT_xIPAddress'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {

        Describe "MSFT_xIPAddress\Get-TargetResource" -Tag 'Get' {

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
                        IPAddress = '192.168.0.1/24'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    $Result = Get-TargetResource @Splat
                    $Result.IPAddress | Should Be $Splat.IPAddress
                }
            }

            Context 'Prefix Length' {
                It 'should fail if passed a negative number' {
                    $Splat = @{
                        IPAddress = '192.168.0.1/-16'
                        InterfaceAlias = 'Ethernet'
                    }

                    { Get-TargetResource @Splat } `
                        | Should Throw 'Value was either too large or too small for a UInt32.'
                }
            }

            #region Mocks
            Mock Get-NetIPAddress -MockWith {
                @('192.168.0.1', '192.168.0.2') | foreach-object {
                    [PSCustomObject]@{
                        IPAddress = $_
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        PrefixLength = [byte]24
                        AddressFamily = 'IPv4'
                    }
                }
            }
            #endregion

            Context 'invoking with multiple IP addresses' {
                It 'should return existing IP details' {
                    $Splat = @{
                        IPAddress = @('192.168.0.1/24', '192.168.0.2/24')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    $Result = Get-TargetResource @Splat
                    $Result.IPAddress | Should Be $Splat.IPAddress
                }
            }
        }

        Describe "MSFT_xIPAddress\Set-TargetResource" -Tag 'Set' {

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

                It 'should return $null' {
                    $Splat = @{
                        IPAddress = '10.0.0.2/24'
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

            Context 'invoking with multiple valid IP Address' {

                It 'should return $null' {
                    $Splat = @{
                        IPAddress = @('10.0.0.2/24', '10.0.0.3/24')
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
                    Assert-MockCalled -commandName New-NetIPAddress -Exactly 2
                }
            }

            #region Mocks
            Mock Get-NetIPAddress -MockWith {
                [PSCustomObject]@{
                    IPAddress = 'fe80::15'
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength = [byte]64
                    AddressFamily = 'IPv6'
                }
            }

            Mock New-NetIPAddress

            Mock Get-NetRoute {
                [PSCustomObject]@{
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    AddressFamily = 'IPv6'
                    NextHop = 'fe80::16'
                    DestinationPrefix = '::/0'
                }
            }

            Mock Remove-NetIPAddress

            Mock Remove-NetRoute
            #endregion

            Context 'invoking with valid IPv6 Address' {

                It 'should return $null' {
                    $Splat = @{
                        IPAddress = 'fe80::17/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
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

            Context 'invoking with multiple valid IPv6 Addresses' {

                It 'should return $null' {
                    $Splat = @{
                        IPAddress = @('fe80::17/64', 'fe80::18/64')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }
                    { $Result = Set-TargetResource @Splat } | Should Not Throw
                    $Result | Should BeNullOrEmpty
                }

                It 'should call all the mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                    Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                    Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
                    Assert-MockCalled -commandName Remove-NetIPAddress -Exactly 1
                    Assert-MockCalled -commandName New-NetIPAddress -Exactly 2
                }
            }

            #region mocks
            Mock Get-NetIPAddress -MockWith {
                $CurrentIPs = @(([PSCustomObject]@{
                        IPAddress = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        PrefixLength = [byte]24
                        AddressFamily = 'IPv4'
                    }),([PSCustomObject]@{
                        IPAddress = '172.16.4.19'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        PrefixLength = [byte]16
                        AddressFamily = 'IPv4'
                    }))
                    Return $CurrentIPs
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

            Context "Invoking with different prefixes" {
                it "should return null" {
                    $Splat = @{
                        IPAddress = '10.0.0.2/24','172.16.4.19/16'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    { $Result = Set-TargetResource @Splat} | Should not Throw
                    $Result | Should BeNullOrEmpty
                }

                it "should call all mocks" {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                    Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                    Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
                    Assert-MockCalled -commandName Remove-NetIPAddress -Exactly 1
                    Assert-MockCalled -commandName New-NetIPAddress -Exactly 2
                }
            }

            Context "Invoking with existing IP with different prefix" {
                it "should return null" {
                    $Splat = @{
                        IPAddress = '172.16.4.19/24'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    { $Result = Set-TargetResource @Splat} | Should not Throw
                    $Result | Should BeNullOrEmpty
                }

                it "should call all mocks" {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                    Assert-MockCalled -commandName Get-NetRoute -Exactly 1
                    Assert-MockCalled -commandName Remove-NetRoute -Exactly 1
                    Assert-MockCalled -commandName Remove-NetIPAddress -Exactly 2
                    Assert-MockCalled -commandName New-NetIPAddress -Exactly 1
                }
            }
            
        }

        Describe "MSFT_xIPAddress\Test-TargetResource" -Tag 'Test' {


            #region Mocks
            Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }

            Mock Get-NetIPAddress -MockWith {

                [PSCustomObject]@{
                    IPAddress = '192.168.0.15'
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength = [byte]16
                    AddressFamily = 'IPv4'
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
                        IPAddress = '192.168.0.1/16'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $false
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }

            Context 'invoking with the same IPv4 Address' {

                It 'should be $true' {
                    $Splat = @{
                        IPAddress = '192.168.0.15/16'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $true
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }

            Context 'invoking with the same IPv4 Address but different prefix length' {

                It 'should be $true' {
                    $Splat = @{
                        IPAddress = '192.168.0.15/24'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $false
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }

            Mock Get-NetIPAddress -MockWith {

                [PSCustomObject]@{
                    IPAddress = @('192.168.0.15', '192.168.0.16')
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength = [byte]16
                    AddressFamily = 'IPv4'
                }
            }
            Context 'invoking with multiple different IPv4 Addresses' {

                It 'should be $false' {
                    $Splat = @{
                        IPAddress = @('192.168.0.1/16', '192.168.0.2/16')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $false
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }
            Context 'invoking with a single different IPv4 Address' {

                It 'should be $false' {
                    $Splat = @{
                        IPAddress = '192.168.0.1/16'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $false
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }

            Context 'invoking with the same IPv4 Addresses' {

                It 'should be $true' {
                    $Splat = @{
                        IPAddress = @('192.168.0.15/16', '192.168.0.16/16')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $true
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }

            Context 'invoking with the combination of same and different IPv4 Addresses' {

                It 'should be $false' {
                    $Splat = @{
                        IPAddress = @('192.168.0.1/16', '192.168.0.16/16')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $false
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }

            Mock Get-NetIPAddress -MockWith {

                [PSCustomObject]@{
                    IPAddress = 'fe80::15'
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
                        IPAddress = 'fe80::1/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $false
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }

            Context 'invoking with the same IPv6 Address' {

                It 'should be $true' {
                    $Splat = @{
                        IPAddress = 'fe80::15/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $true
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }

            Mock Get-NetIPAddress -MockWith {

                [PSCustomObject]@{
                    IPAddress = @('fe80::15', 'fe80::16')
                    InterfaceAlias = 'Ethernet'
                    InterfaceIndex = 1
                    PrefixLength = [byte]64
                    AddressFamily = 'IPv6'
                }
            }

            Context 'invoking with multiple different IPv6 Addresses' {

                It 'should be $false' {
                    $Splat = @{
                        IPAddress = @('fe80::1/64', 'fe80::2/64')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $false
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }

            Context 'invoking with a single different IPv6 Address' {

                It 'should be $false' {
                    $Splat = @{
                        IPAddress = 'fe80::1/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $false
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }

            Context 'invoking with the same IPv6 Addresses' {

                It 'should be $true' {
                    $Splat = @{
                        IPAddress = @('fe80::15/64', 'fe80::16/64')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $true
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }
            Context 'invoking with a mix of the same and different IPv6 Addresses' {

                It 'should be $true' {
                    $Splat = @{
                        IPAddress = @('fe80::1/64', 'fe80::16/64')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }
                    $Result = Test-TargetResource @Splat
                    $Result | Should Be $false
                }
                It 'should call appropriate mocks' {
                    Assert-MockCalled -commandName Get-NetIPAddress -Exactly 1
                }
            }
        }

        Describe "MSFT_xIPAddress\Assert-ResourceProperty" {

            Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }

            Context 'invoking with bad interface alias' {

                It 'should throw an InterfaceNotAvailable error' {
                    $Splat = @{
                        IPAddress = '192.168.0.1/16'
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

                    { Assert-ResourceProperty @Splat } | Should Throw $errorRecord
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

                    { Assert-ResourceProperty @Splat } | Should Throw $errorRecord
                }
            }

            Context 'invoking with IPv4 Address and IPv6 family mismatch' {

                It 'should throw an AddressMismatchError error' {
                    $Splat = @{
                        IPAddress = '192.168.0.1/16'
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

                    { Assert-ResourceProperty @Splat } | Should Throw $errorRecord
                }
            }

             Context 'invoking with IPv6 Address and IPv4 family mismatch' {

                It 'should throw an AddressMismatchError error' {
                    $Splat = @{
                        IPAddress = 'fe80::15'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    $errorId = 'AddressMismatchError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($LocalizedData.AddressIPv6MismatchError) -f $Splat.IPAddress,$Splat.AddressFamily
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Assert-ResourceProperty @Splat } | Should Throw $errorRecord
                }
            }

            Context 'invoking with valid IPv4 Address' {

                It 'should not throw an error' {
                    $Splat = @{
                        IPAddress = '192.168.0.1/16'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    { Assert-ResourceProperty @Splat } | Should Not Throw
                }
            }

            Context 'invoking with multiple valid IPv4 Addresses' {

                It 'should not throw an error' {
                    $Splat = @{
                        IPAddress = @('192.168.0.1/24', '192.168.0.2/24')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    { Assert-ResourceProperty @Splat } | Should Not Throw
                }
            }

            Context 'invoking with valid IPv6 Address' {

                It 'should not throw an error' {
                    $Splat = @{
                        IPAddress = 'fe80:ab04:30F5:002b::1/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }
                    { Assert-ResourceProperty @Splat } | Should Not Throw
                }
            }

            Context 'invoking with invalid IPv4 prefix length' {

                It 'should throw a PrefixLengthError when greater than 32' {
                    $Splat = @{
                        IPAddress = '192.168.0.1/33'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    $errorId = 'PrefixLengthError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($LocalizedData.PrefixLengthError) -f $Splat.PrefixLength,$Splat.AddressFamily
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Assert-ResourceProperty @Splat } | Should Throw $errorRecord
                }
                It 'should throw an Argument error when less than 0' {
                    $Splat = @{
                        IPAddress = '192.168.0.1/-1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv4'
                    }
                    { Assert-ResourceProperty @Splat } `
                        | Should Throw 'Value was either too large or too small for a UInt32.'
                }
            }

            Context 'invoking with invalid IPv6 prefix length' {

                It 'should throw a PrefixLengthError error when greater than 128' {
                    $Splat = @{
                        IPAddress = 'fe80::1/129'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }

                    $errorId = 'PrefixLengthError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($LocalizedData.PrefixLengthError) -f $Splat.PrefixLength,$Splat.AddressFamily
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Assert-ResourceProperty @Splat } | Should Throw $errorRecord
                }
                It 'should throw an Argument error when less than 0' {
                    $Splat = @{
                        IPAddress = 'fe80::1/-1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }

                    { Assert-ResourceProperty @Splat } `
                        | Should Throw 'Value was either too large or too small for a UInt32.'
                }
            }

            Context 'invoking with valid string IPv6 prefix length' {

                It 'should not throw an error' {
                    $Splat = @{
                        IPAddress = 'fe80::1/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily = 'IPv6'
                    }
                    { Assert-ResourceProperty @Splat } | Should Not Throw
                }
            }
        }
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
