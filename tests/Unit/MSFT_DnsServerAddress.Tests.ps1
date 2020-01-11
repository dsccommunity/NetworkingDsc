$script:DSCModuleName      = 'NetworkingDsc'
$script:DSCResourceName    = 'MSFT_DnsServerAddress'

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
        Describe 'MSFT_DnsServerAddress\Get-TargetResource' -Tag 'Get' {
            Context 'Test IPv4' {
                Context 'Invoking with an IPv4 address and one address is currently set' {
                    Mock Get-DnsClientServerStaticAddress -MockWith { '192.168.0.1' }

                    It 'Should return true' {
                        $getTargetResourceSplat = @{
                            Address        = '192.168.0.1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        $Result = Get-TargetResource @getTargetResourceSplat
                        $Result.Address | Should -Be '192.168.0.1'
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }
            }

            Context 'Test IPv6' {
                Context 'Invoking with an IPv6 address and one address is currently set' {
                    Mock Get-DnsClientServerStaticAddress -MockWith { 'fe80:ab04:30F5:002b::1' }

                    It 'Should return true' {
                        $getTargetResourceSplat = @{
                            Address        = 'fe80:ab04:30F5:002b::1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Verbose        = $true
                        }

                        $Result = Get-TargetResource @getTargetResourceSplat
                        $Result.Address | Should -Be 'fe80:ab04:30F5:002b::1'
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }
            }

            Context 'Test DHCP' {
                Context 'Invoking with an IPv4 address and DHCP is currently set' {
                    Mock Get-DnsClientServerStaticAddress -MockWith { $null }

                    It 'Should return true' {
                        $getTargetResourceSplat = @{
                            Address        = '192.168.0.1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        $Result = Get-TargetResource @getTargetResourceSplat
                        $Result.Address | Should -BeNullOrEmpty
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }
            }
        }

        Describe 'MSFT_DnsServerAddress\Set-TargetResource' -Tag 'Set' {
            Context 'Test IPv4' {
                BeforeEach {
                    Mock Get-DnsClientServerStaticAddress -MockWith { '192.168.0.1' }
                    Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $true }
                    Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $false }
                    Mock Set-DnsClientServerAddress -ParameterFilter { $ResetServerAddresses -eq $true }
                }

                Context 'Invoking with single IPv4 server address that is the same as current' {
                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            Address        = '192.168.0.1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }

                Context 'Invoking with single IPv4 server address that is different to current' {
                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            Address        = '192.168.0.99'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }

                Context 'Invoking with single IPv4 server address that is different to current and validate true' {
                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            Address        = '192.168.0.99'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Validate       = $true
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }

                Context 'Invoking with multiple IPv4 server addresses that are different to current' {
                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            Address        = @( '192.168.0.99','192.168.0.100' )
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }

                Context 'Invoking with IPv4 server addresses set to DHCP but one address is currently assigned' {
                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }

                Context 'Invoking with multiple IPv4 server addresses when there are different ones currently assigned' {
                    Mock -commandName Get-DnsClientServerStaticAddress -MockWith { @( '192.168.0.1','192.168.0.2' ) }

                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            Address        = @( '192.168.0.3','192.168.0.4' )
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }

                Context 'Invoking with multiple IPv4 server addresses when DHCP is currently set' {
                    Mock -commandName Get-DnsClientServerStaticAddress -MockWith { $null }

                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            Address        = @( '192.168.0.2','192.168.0.3' )
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }
            }

            Context 'Test IPv6' {
                BeforeEach {
                    Mock Get-DnsClientServerStaticAddress -MockWith { 'fe80:ab04:30F5:002b::1' }
                    Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $true }
                    Mock Set-DnsClientServerAddress -ParameterFilter { $Validate -eq $false }
                    Mock Set-DnsClientServerAddress -ParameterFilter { $ResetServerAddresses -eq $true }
                }

                Context 'Invoking with single IPv6 server address that is the same as current' {
                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            Address        = 'fe80:ab04:30F5:002b::1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }

                Context 'Invoking with single IPv6 server address that is different to current' {
                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            Address        = 'fe80:ab04:30F5:002b::2'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }

                Context 'Invoking with single IPv6 server address that is different to current and validate true' {
                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            Address        = 'fe80:ab04:30F5:002b::2'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Validate       = $true
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }

                Context 'Invoking with multiple IPv6 server addresses that are different to current' {
                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            Address        = @( 'fe80:ab04:30F5:002b::1','fe80:ab04:30F5:002b::2' )
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }

                Context 'Invoking with IPv6 server addresses set to DHCP but one address is currently assigned' {
                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }

                Context 'Invoking with multiple IPv6 server addresses when DHCP is currently set' {
                    Mock Get-DnsClientServerStaticAddress -MockWith { $null }

                    It 'Should not throw an exception' {
                        $setTargetResourceSplat = @{
                            Address        = @( 'fe80:ab04:30F5:002b::1','fe80:ab04:30F5:002b::1' )
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Verbose        = $true
                        }

                        { Set-TargetResource @setTargetResourceSplat } | Should -Not -Throw
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $Validate -eq $true }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 1 -ParameterFilter { $Validate -eq $false }
                        Assert-MockCalled -commandName Set-DnsClientServerAddress -Exactly 0 -ParameterFilter { $ResetServerAddresses -eq $true }
                    }
                }
            }
        }

        Describe 'MSFT_DnsServerAddress\Test-TargetResource' -Tag 'Test' {
            Context 'Test IPv4' {
                BeforeEach {
                    Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
                    Mock Get-DnsClientServerStaticAddress -MockWith { '192.168.0.1' }
                }

                Context 'Invoking with single IPv4 server address that is the same as current' {
                    It 'Should return true' {
                        $testTargetResourceSplat = @{
                            Address        = '192.168.0.1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $true
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }

                Context 'Invoking with single IPv4 server address that is different to current' {
                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            Address        = '192.168.0.2'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $False
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }

                Context 'Invoking with multiple IPv4 server addresses that are different to current' {
                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            Address        = @( '192.168.0.2','192.168.0.3' )
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $False
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }

                Context 'Invoking with IPv4 server addresses set to DHCP but one address is currently assigned' {
                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $False
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }

                Context 'Invoking with multiple IPv4 server addresses but DHCP is currently enabled' {
                    Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
                    Mock Get-DnsClientServerStaticAddress -MockWith { $null }

                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            Address        = @( '192.168.0.2','192.168.0.3' )
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv4'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $False
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }
            }

            Context 'Test IPv6' {
                BeforeEach {
                    Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
                    Mock Get-DnsClientServerStaticAddress -MockWith { 'fe80:ab04:30F5:002b::1' }
                }

                Context 'Invoking with single IPv6 server address that is the same as current' {
                    It 'Should return true' {
                        $testTargetResourceSplat = @{
                            Address        = 'fe80:ab04:30F5:002b::1'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $true
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }

                Context 'Invoking with single IPv6 server address that is different to current' {
                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            Address        = 'fe80:ab04:30F5:002b::2'
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $False
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }

                Context 'Invoking with multiple IPv6 server addresses that are different to current' {
                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            Address        = @( 'fe80:ab04:30F5:002b::1','fe80:ab04:30F5:002b::2' )
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $False
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }

                Context 'Invoking with IPv6 server addresses set to DHCP but one address is currently assigned' {
                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $False
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }

                Context 'Invoking with multiple IPv6 server addresses but DHCP is currently enabled' {
                    Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
                    Mock Get-DnsClientServerStaticAddress -MockWith { $null }

                    It 'Should return false' {
                        $testTargetResourceSplat = @{
                            Address        = @( 'fe80:ab04:30F5:002b::1','fe80:ab04:30F5:002b::2' )
                            InterfaceAlias = 'Ethernet'
                            AddressFamily  = 'IPv6'
                            Verbose        = $true
                        }

                        Test-TargetResource @testTargetResourceSplat | Should -Be $False
                    }

                    It 'Should call all the mocks' {
                        Assert-MockCalled -commandName Get-DnsClientServerStaticAddress -Exactly 1
                    }
                }
            }
        }

        Describe 'MSFT_DnsServerAddress\Assert-ResourceProperty' {
            BeforeEach {
                Mock Get-NetAdapter -MockWith { [PSObject]@{ Name = 'Ethernet' } }
            }

            Context 'Invoking with bad interface alias' {
                It 'Should throw the expected exception' {
                    $assertResourcePropertySplat = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'NotReal'
                        AddressFamily  = 'IPv4'
                        Verbose        = $true
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.InterfaceNotAvailableError -f $assertResourcePropertySplat.InterfaceAlias) `
                        -ArgumentName 'InterfaceAlias'

                    { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Throw $ErrorRecord
                }
            }

            Context 'Invoking with invalid IP Address' {
                It 'Should throw the expected exception' {
                    $assertResourcePropertySplat = @{
                        Address        = 'NotReal'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                        Verbose        = $true
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressFormatError -f $assertResourcePropertySplat.Address) `
                        -ArgumentName 'Address'

                    { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Throw $ErrorRecord
                }
            }

            Context 'Invoking with IPv4 Address and family mismatch' {
                It 'Should throw the expected exception' {
                    $assertResourcePropertySplat = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                        Verbose        = $true
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv4MismatchError -f $assertResourcePropertySplat.Address,$assertResourcePropertySplat.AddressFamily) `
                        -ArgumentName 'Address'

                    { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Throw $ErrorRecord
                }
            }

            Context 'Invoking with IPv6 Address and family mismatch' {
                It 'Should throw the expected exception' {
                    $assertResourcePropertySplat = @{
                        Address        = 'fe80::'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                        Verbose        = $true
                    }

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv6MismatchError -f $assertResourcePropertySplat.Address,$assertResourcePropertySplat.AddressFamily) `
                        -ArgumentName 'Address'

                    { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Throw $ErrorRecord
                }
            }

            Context 'Invoking with valid IPv4 Addresses' {
                It 'Should not throw an error' {
                    $assertResourcePropertySplat = @{
                        Address        = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv4'
                        Verbose        = $true
                    }

                    { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Not -Throw
                }
            }

            Context 'Invoking with valid IPv6 Addresses' {
                It 'Should not throw an error' {
                    $assertResourcePropertySplat = @{
                        Address        = 'fe80:ab04:30F5:002b::1'
                        InterfaceAlias = 'Ethernet'
                        AddressFamily  = 'IPv6'
                        Verbose        = $true
                    }

                    { Assert-ResourceProperty @assertResourcePropertySplat } | Should -Not -Throw
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
