$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_IPAddress'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        Describe 'MSFT_IPAddress\Get-TargetResource' -Tag 'Get' {
            Context 'Invoked with a single IP address' {
                Mock -CommandName Get-NetIPAddress -MockWith {
                    [PSCustomObject] @{
                        IPAddress      = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        PrefixLength   = [System.Byte] 24
                        AddressFamily  = 'IPv4'
                    }
                }

                It 'Should return existing IP details' {
                    $getTargetResourceParameters = @{
                        IPAddress      = '192.168.0.1/24'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.IPAddress | Should -Be $getTargetResourceParameters.IPAddress
                }
            }

            Context 'Invoked with multiple IP addresses' {
                Mock -CommandName Get-NetIPAddress -MockWith {
                    @('192.168.0.1', '192.168.0.2') | foreach-object {
                        [PSCustomObject]@{
                            IPAddress      = $_
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 24
                            AddressFamily  = 'IPv4'
                        }
                    }
                }

                It 'Should return existing IP details' {
                    $getTargetResourceParameters = @{
                        IPAddress      = @('192.168.0.1/24', '192.168.0.2/24')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.IPAddress | Should -Be $getTargetResourceParameters.IPAddress
                }
            }
        }

        Describe 'MSFT_IPAddress\Set-TargetResource' -Tag 'Set' {
            Context 'A single IPv4 address is currently set on the adapter' {
                BeforeEach {
                    Mock -CommandName Get-NetIPAddress -MockWith {
                        [PSCustomObject] @{
                            IPAddress      = '192.168.0.1'
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 16
                            AddressFamily  = 'IPv4'
                        }
                    }

                    Mock -CommandName New-NetIPAddress

                    Mock -CommandName Get-NetRoute {
                        [PSCustomObject] @{
                            InterfaceAlias    = 'Ethernet'
                            InterfaceIndex    = 1
                            AddressFamily     = 'IPv4'
                            NextHop           = '192.168.0.254'
                            DestinationPrefix = '0.0.0.0/0'
                        }
                    }

                    Mock -CommandName Remove-NetIPAddress

                    Mock -CommandName Remove-NetRoute
                }

                Context 'Invoked with valid IP address' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = '10.0.0.2/24'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }
                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with multiple valid IP Address' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = @('10.0.0.2/24', '10.0.0.3/24')
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }
                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 2
                    }
                }

                Context 'Invoked with multiple valid IP Addresses with one currently set' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = @('192.168.0.1/16', '10.0.0.3/24')
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        Mock -CommandName New-NetIPAddress -MockWith {
                            throw [Microsoft.Management.Infrastructure.CimException] 'InvalidOperation'
                        } -ParameterFilter { $IPaddress -eq '192.168.0.1' }

                        Mock -CommandName Get-NetIPAddress -MockWith {
                            [PSCustomObject] @{
                                IPAddress      = '192.168.0.1'
                                InterfaceAlias = 'Ethernet'
                                PrefixLength   = [System.Byte] 16
                                AddressFamily  = 'IPv4'
                            }
                        } -ParameterFilter { $IPaddress -eq '192.168.0.1' }

                        Mock -CommandName Write-Error

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 2
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 0
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 2
                        Assert-MockCalled -CommandName Write-Error -Exactly -Times 0
                    }
                }

                Context 'Invoked with multiple valid IP Addresses with one currently set on another adapter' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = @('192.168.0.1/16', '10.0.0.3/24')
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        Mock -CommandName New-NetIPAddress -MockWith {
                            throw [Microsoft.Management.Infrastructure.CimException] 'InvalidOperation'
                        } -ParameterFilter { $IPaddress -eq '192.168.0.1' }

                        Mock -CommandName Get-NetIPAddress -MockWith {
                            [PSCustomObject] @{
                                IPAddress      = '192.168.0.1'
                                InterfaceAlias = 'Ethernet2'
                                PrefixLength   = [System.Byte] 16
                                AddressFamily  = 'IPv4'
                            }
                        } -ParameterFilter { $IPaddress -eq '192.168.0.1' }

                        Mock -CommandName Write-Error

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty

                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 2
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 0
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 2
                        Assert-MockCalled -CommandName Write-Error -Exactly -Times 1
                    }
                }

                Context 'Invoked IPv4 Class A with no prefix' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = '10.11.12.13'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 1 -ParameterFilter {
                            $PrefixLength -eq 8
                        }

                    }
                }

                Context 'Invoked IPv4 Class B with no prefix' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = '172.16.4.19'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 1 -ParameterFilter {
                            $PrefixLength -eq 16
                        }
                    }
                }

                Context 'Invoked IPv4 Class C with no prefix' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = '192.168.10.19'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 1 -ParameterFilter {
                            $PrefixLength -eq 24
                        }
                    }
                }

                Context 'Invoked with parameter "KeepExistingAddress"' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress           = '10.0.0.2/24'
                            InterfaceAlias      = 'Ethernet'
                            AddressFamily       = 'IPv4'
                            KeepExistingAddress = $true
                        }
                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 0
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 1
                    }
                }
            }

            Context 'A single IPv6 address is currently set on the adapter' {
                BeforeEach {
                    Mock -CommandName Get-NetIPAddress -MockWith {
                        [PSCustomObject] @{
                            IPAddress      = 'fe80::15'
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 64
                            AddressFamily  = 'IPv6'
                        }
                    }

                    Mock -CommandName New-NetIPAddress

                    Mock -CommandName Get-NetRoute {
                        [PSCustomObject] @{
                            InterfaceAlias    = 'Ethernet'
                            InterfaceIndex    = 1
                            AddressFamily     = 'IPv6'
                            NextHop           = 'fe80::16'
                            DestinationPrefix = '::/0'
                        }
                    }

                    Mock -CommandName Remove-NetIPAddress

                    Mock -CommandName Remove-NetRoute
                }

                Context 'Invoked with valid IPv6 Address' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = 'fe80::17/64'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with multiple valid IPv6 Addresses' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = @('fe80::17/64', 'fe80::18/64')
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 2
                    }
                }

                Context 'Invoked IPv6 with no prefix' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = 'fe80::17'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with parameter "KeepExistingAddress"' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress           = 'fe80::17/64'
                            InterfaceAlias      = 'Ethernet'
                            AddressFamily       = 'IPv6'
                            KeepExistingAddress = $true
                        }

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 0
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 1
                    }
                }
            }

            Context 'Multiple IPv4 addresses are currently set on the adapter' {
                BeforeEach {
                    Mock -CommandName Get-NetIPAddress -MockWith {
                        $CurrentIPs = @(([PSCustomObject] @{
                                    IPAddress      = '192.168.0.1'
                                    InterfaceAlias = 'Ethernet'
                                    InterfaceIndex = 1
                                    PrefixLength   = [System.Byte] 24
                                    AddressFamily  = 'IPv4'
                                }), ([PSCustomObject] @{
                                    IPAddress      = '172.16.4.19'
                                    InterfaceAlias = 'Ethernet'
                                    InterfaceIndex = 1
                                    PrefixLength   = [System.Byte] 16
                                    AddressFamily  = 'IPv4'
                                }))
                        Return $CurrentIPs
                    }

                    Mock -CommandName New-NetIPAddress

                    Mock -CommandName Get-NetRoute {
                        [PSCustomObject] @{
                            InterfaceAlias    = 'Ethernet'
                            InterfaceIndex    = 1
                            AddressFamily     = 'IPv4'
                            NextHop           = '192.168.0.254'
                            DestinationPrefix = '0.0.0.0/0'
                        }
                    }

                    Mock -CommandName Remove-NetIPAddress

                    Mock -CommandName Remove-NetRoute
                }

                Context 'Invoked with different prefixes' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = '10.0.0.2/24', '172.16.4.19/16'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 2
                    }
                }

                Context 'Invoked with existing IP with different prefix' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = '172.16.4.19/24'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 2
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with parameter "KeepExistingAddress" and different prefixes' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = '10.0.0.2/24', '172.16.4.19/16'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            KeepExistingAddress = $true
                        }

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 0
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 2
                    }
                }

                Context 'Invoked with parameter "KeepExistingAddress" and existing IP with different prefix' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress      = '172.16.4.19/24'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            KeepExistingAddress = $true
                        }

                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetRoute -Exactly -Times 1
                        Assert-MockCalled -CommandName Remove-NetIPAddress -Exactly -Times 1
                        Assert-MockCalled -CommandName New-NetIPAddress -Exactly -Times 1
                    }
                }
            }
        }

        Describe 'MSFT_IPAddress\Test-TargetResource' -Tag 'Test' {
            Context 'A single IPv4 address is currently set on the adapter' {
                BeforeEach {
                    Mock -CommandName Get-NetAdapter -MockWith {
                        [PSObject] @{
                            Name = 'Ethernet'
                        }
                    }

                    Mock -CommandName Get-NetIPAddress -MockWith {
                        [PSCustomObject] @{
                            IPAddress      = '192.168.0.15'
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 16
                            AddressFamily  = 'IPv4'
                        }
                    }
                }

                Context 'Invoked with invalid IPv4 Address' {
                    It 'Should throw an AddressFormatError error' {
                        $testGetResourceParameters = @{
                            IPAddress      = 'BadAddress'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $errorRecord = Get-InvalidArgumentRecord `
                            -Message ($script:localizedData.AddressFormatError -f $testGetResourceParameters.IPAddress) `
                            -ArgumentName 'IPAddress'

                        { $result = Test-TargetResource @testGetResourceParameters } | Should -Throw $errorRecord
                    }
                }

                Context 'Invoked with different IPv4 Address' {
                    It 'Should return $false'  {
                        $testGetResourceParameters = @{
                            IPAddress      = '192.168.0.1/16'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with the same IPv4 Address' {
                    It 'Should return $true'  {
                        $testGetResourceParameters = @{
                            IPAddress      = '192.168.0.15/16'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $true
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with the same IPv4 Address but different prefix length' {
                    It 'Should return $false'  {
                        $testGetResourceParameters = @{
                            IPAddress      = '192.168.0.15/24'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }
            }

            Context 'Multiple IPv4 addresses are currently set on the adapter' {
                BeforeEach {
                    Mock -CommandName Get-NetAdapter -MockWith {
                        [PSObject] @{
                            Name = 'Ethernet'
                        }
                    }

                    Mock -CommandName Get-NetIPAddress -MockWith {
                        [PSCustomObject] @{
                            IPAddress      = @('192.168.0.15', '192.168.0.16')
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 16
                            AddressFamily  = 'IPv4'
                        }
                    }
                }

                Context 'Invoked with multiple different IPv4 Addresses' {
                    It 'Should return $false' {
                        $testGetResourceParameters = @{
                            IPAddress      = @('192.168.0.1/16', '192.168.0.2/16')
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with a single different IPv4 Address' {
                    It 'Should return $false' {
                        $testGetResourceParameters = @{
                            IPAddress      = '192.168.0.1/16'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with the same IPv4 Addresses' {
                    It 'Should return $true' {
                        $testGetResourceParameters = @{
                            IPAddress      = @('192.168.0.15/16', '192.168.0.16/16')
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $true
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with the combination of same and different IPv4 Addresses' {
                    It 'Should return $false' {
                        $testGetResourceParameters = @{
                            IPAddress      = @('192.168.0.1/16', '192.168.0.16/16')
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with a single different Class A IPv4 Address with no prefix' {
                    It 'Should return $false' {
                        $testGetResourceParameters = @{
                            IPAddress      = '10.1.0.1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with a single different Class B IPv4 Address with no prefix' {
                    It 'Should return $false' {
                        $testGetResourceParameters = @{
                            IPAddress      = '172.16.0.1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }
                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with a single different Class C IPv4 Address with no prefix' {
                    It 'Should return $false' {
                        $testGetResourceParameters = @{
                            IPAddress      = '192.168.0.1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }
            }

            Context 'A single IPv4 address with 8 bit prefix is currently set on the adapter' {
                BeforeEach {
                    Mock -CommandName Get-NetAdapter -MockWith {
                        [PSObject] @{
                            Name = 'Ethernet'
                        }
                    }

                    Mock -CommandName Get-NetIPAddress -MockWith {
                        [PSCustomObject] @{
                            IPAddress      = @('10.1.0.1')
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 8
                            AddressFamily  = 'IPv4'
                        }
                    }
                }

                Context 'Invoked with the same Class A IPv4 Address with no prefix' {
                    It 'Should return $true' {
                        $testGetResourceParameters = @{
                            IPAddress      = '10.1.0.1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $true
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }
            }

            Context 'A single IPv4 address with 16 bit prefix is currently set on the adapter' {
                BeforeEach {
                    Mock -CommandName Get-NetAdapter -MockWith {
                        [PSObject] @{
                            Name = 'Ethernet'
                        }
                    }

                    Mock -CommandName Get-NetIPAddress -MockWith {
                        [PSCustomObject] @{
                            IPAddress      = @('172.16.0.1')
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 16
                            AddressFamily  = 'IPv4'
                        }
                    }
                }

                Context 'Invoked with the same Class B IPv4 Address with no prefix' {
                    It 'Should return $true' {
                        $testGetResourceParameters = @{
                            IPAddress      = '172.16.0.1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $true
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }
            }

            Context 'A single IPv4 address with 24 bit prefix is currently set on the adapter' {
                BeforeEach {
                    Mock -CommandName Get-NetAdapter -MockWith {
                        [PSObject] @{
                            Name = 'Ethernet'
                        }
                    }

                    Mock -CommandName Get-NetIPAddress -MockWith {
                        [PSCustomObject] @{
                            IPAddress      = @('192.168.0.1')
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 24
                            AddressFamily  = 'IPv4'
                        }
                    }
                }

                Context 'Invoked with the same Class C IPv4 Address with no prefix' {
                    It 'Should return $true' {
                        $testGetResourceParameters = @{
                            IPAddress      = '192.168.0.1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $true
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }
            }

            Context 'A single IPv6 address with 64 bit prefix is currently set on the adapter' {
                BeforeEach {
                    Mock -CommandName Get-NetAdapter -MockWith {
                        [PSObject] @{
                            Name = 'Ethernet'
                        }
                    }

                    Mock -CommandName Get-NetIPAddress -MockWith {
                        [PSCustomObject] @{
                            IPAddress      = 'fe80::15'
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 64
                            AddressFamily  = 'IPv6'
                        }
                    }
                }

                Context 'Invoked with invalid IPv6 Address' {
                    It 'Should throw an AddressFormatError error' {
                        $testGetResourceParameters = @{
                            IPAddress      = 'BadAddress'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }

                        $errorRecord = Get-InvalidArgumentRecord `
                            -Message ($script:localizedData.AddressFormatError -f $testGetResourceParameters.IPAddress) `
                            -ArgumentName 'IPAddress'

                        { $result = Test-TargetResource @testGetResourceParameters } | Should -Throw $errorRecord
                    }
                }

                Context 'Invoked with different IPv6 Address' {
                    It 'Should return $false' {
                        $testGetResourceParameters = @{
                            IPAddress      = 'fe80::1/64'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with the same IPv6 Address' {
                    It 'Should return $true' {
                        $testGetResourceParameters = @{
                            IPAddress      = 'fe80::15/64'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }
                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $true
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with the same IPv6 Address with no prefix' {
                    It 'testGetResourceParameters return $true' {
                        $testGetResourceParameters = @{
                            IPAddress      = 'fe80::15'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $true
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }
            }

            Context 'Multiple IPv6 addresses with 64 bit prefix are currently set on the adapter' {
                BeforeEach {
                    Mock -CommandName Get-NetAdapter -MockWith {
                        [PSObject] @{
                            Name = 'Ethernet'
                        }
                    }

                    Mock -CommandName Get-NetIPAddress -MockWith {
                        [PSCustomObject]@{
                            IPAddress      = @('fe80::15', 'fe80::16')
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 64
                            AddressFamily  = 'IPv6'
                        }
                    }
                }

                Context 'Invoked with multiple different IPv6 Addresses' {
                    It 'Should return $false' {
                        $testGetResourceParameters = @{
                            IPAddress      = @('fe80::1/64', 'fe80::2/64')
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with a single different IPv6 Address' {
                    It 'Should return $false' {
                        $testGetResourceParameters = @{
                            IPAddress      = 'fe80::1/64'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with the same IPv6 Addresses' {
                    It 'Should return $true' {
                        $testGetResourceParameters = @{
                            IPAddress      = @('fe80::15/64', 'fe80::16/64')
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $true
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with a mix of the same and different IPv6 Addresses' {
                    It 'Should return $true' {
                        $testGetResourceParameters = @{
                            IPAddress      = @('fe80::1/64', 'fe80::16/64')
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }

                Context 'Invoked with a single different IPv6 Address with no prefix' {
                    It 'Should return $false' {
                        $testGetResourceParameters = @{
                            IPAddress      = 'fe80::1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $false
                    }

                    It 'Should call appropriate mocks' {
                        Assert-MockCalled -CommandName Get-NetIPAddress -Exactly -Times 1
                    }
                }
            }
        }

        Describe 'MSFT_IPAddress\Assert-ResourceProperty' {
            BeforeEach {
                Mock -CommandName Get-NetAdapter -MockWith {
                    [PSObject] @{
                        Name = 'Ethernet'
                    }
                }
            }

            Context 'Invoked with bad interface alias' {
                It 'Should throw an InterfaceNotAvailable error' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = '192.168.0.1/16'
                        InterfaceAlias = 'NotReal'
                        AddressFamily  = 'IPv4'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.InterfaceNotAvailableError -f $assertResourcePropertyParameters.InterfaceAlias) `
                        -ArgumentName 'Interface'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $errorRecord
                }
            }

            Context 'Invoked with invalid IP Address' {
                It 'Should throw an AddressFormatError error' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = 'NotReal'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressFormatError -f $assertResourcePropertyParameters.IPAddress) `
                        -ArgumentName 'IPAddress'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $errorRecord
                }
            }

            Context 'Invoked with IPv4 Address and IPv6 family mismatch' {
                It 'Should throw an AddressMismatchError error' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = '192.168.0.1/16'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv4MismatchError -f $assertResourcePropertyParameters.IPAddress, $assertResourcePropertyParameters.AddressFamily) `
                        -ArgumentName 'IPAddress'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $errorRecord
                }
            }

            Context 'Invoked with IPv6 Address and IPv4 family mismatch' {
                It 'Should throw an AddressMismatchError error' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = 'fe80::15'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv6MismatchError -f $assertResourcePropertyParameters.IPAddress, $assertResourcePropertyParameters.AddressFamily) `
                        -ArgumentName 'IPAddress'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $errorRecord
                }
            }

            Context 'Invoked with valid IPv4 Address' {
                It 'Should Not Throw an error' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = '192.168.0.1/16'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
                }
            }

            Context 'Invoked with multiple valid IPv4 Addresses' {
                It 'Should Not Throw an error' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = @('192.168.0.1/24', '192.168.0.2/24')
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
                }
            }

            Context 'Invoked with valid IPv6 Address' {
                It 'Should Not Throw an error' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = 'fe80:ab04:30F5:002b::1/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
                }
            }

            Context 'Invoked with invalid IPv4 prefix length' {
                It 'Should throw a PrefixLengthError when greater than 32' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = '192.168.0.1/33'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }

                    $prefixLength = ($assertResourcePropertyParameters.IPAddress -split '/')[-1]

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.PrefixLengthError -f $prefixLength, $assertResourcePropertyParameters.AddressFamily) `
                        -ArgumentName 'IPAddress'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $errorRecord
                }

                It 'Should throw an Argument error when less than 0' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = '192.168.0.1/-1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                    }
                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw 'Value was either too large or too small for a UInt32.'
                }
            }

            Context 'Invoked with invalid IPv6 prefix length' {
                It 'Should throw a PrefixLengthError error when greater than 128' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = 'fe80::1/129'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    $prefixLength = ($assertResourcePropertyParameters.IPAddress -split '/')[-1]

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.PrefixLengthError -f $prefixLength, $assertResourcePropertyParameters.AddressFamily) `
                        -ArgumentName 'IPAddress'

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw $errorRecord
                }

                It 'Should throw an Argument error when less than 0' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = 'fe80::1/-1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Throw 'Value was either too large or too small for a UInt32.'
                }
            }

            Context 'Invoked with valid string IPv6 prefix length' {
                It 'Should Not Throw an error' {
                    $assertResourcePropertyParameters = @{
                        IPAddress      = 'fe80::1/64'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                    }

                    { Assert-ResourceProperty @assertResourcePropertyParameters } | Should -Not -Throw
                }
            }
        }
    } #end InModuleScope $DSCResourceName
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
