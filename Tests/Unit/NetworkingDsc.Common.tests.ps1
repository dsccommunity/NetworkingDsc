$script:ModuleName = 'NetworkingDsc.Common'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath $script:ModuleName)) -ChildPath "$script:ModuleName.psm1") -Force
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    $LocalizedData = InModuleScope $script:ModuleName {
        $LocalizedData
    }

    #region Function Convert-CIDRToSubhetMask
    Describe "NetworkingDsc.Common\Convert-CIDRToSubhetMask" {
        Context 'Subnet Mask Notation Used "192.168.0.0/255.255.0.0"' {
            It 'Should Return "192.168.0.0/255.255.0.0"' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.0/255.255.0.0') | Should Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'Subnet Mask Notation Used "192.168.0.10/255.255.0.0" resulting in source bits masked' {
            It 'Should Return "192.168.0.0/255.255.0.0" with source bits masked' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.10/255.255.0.0') | Should Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'CIDR Notation Used "192.168.0.0/16"' {
            It 'Should Return "192.168.0.0/255.255.0.0"' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.0/16') | Should Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'CIDR Notation Used "192.168.0.10/16" resulting in source bits masked' {
            It 'Should Return "192.168.0.0/255.255.0.0" with source bits masked' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.10/16') | Should Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'Multiple Notations Used "192.168.0.0/16,10.0.0.24/255.255.255.0"' {
            $Result = Convert-CIDRToSubhetMask -Address @('192.168.0.0/16','10.0.0.24/255.255.255.0')
            It 'Should Return "192.168.0.0/255.255.0.0,10.0.0.0/255.255.255.0"' {
                $Result[0] | Should Be '192.168.0.0/255.255.0.0'
                $Result[1] | Should Be '10.0.0.0/255.255.255.0'
            }
        }
        Context 'Range Used "192.168.1.0-192.168.1.128"' {
            It 'Should Return "192.168.1.0-192.168.1.128"' {
                Convert-CIDRToSubhetMask -Address @('192.168.1.0-192.168.1.128') | Should Be '192.168.1.0-192.168.1.128'
            }
        }
        Context 'IPv6 Used "fe80::/112"' {
            It 'Should Return "fe80::/112"' {
                Convert-CIDRToSubhetMask -Address @('fe80::/112') | Should Be 'fe80::/112'
            }
        }
    }

    #region Function Find-NetworkAdapter
    <#
        InModuleScope has to be used to enable the Get-NetAdapter Mock
        This is because forcing the ModuleName in the Mock command throws
        an exception because the GetAdapter module has no manifest
    #>
    InModuleScope $script:ModuleName {
        Describe "NetworkingDsc.Common\Find-NetworkAdapter" {

            # Generate the adapter data to be used for Mocking
            $adapterName = 'Adapter'
            $adapterPhysicalMediaType = '802.3'
            $adapterStatus = 'Up'
            $adapterMacAddress = '11-22-33-44-55-66'
            $adapterInterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
            $adapterInterfaceIndex = 2
            $adapterInterfaceGuid = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
            $adapterDriverDescription = 'Hyper-V Virtual Ethernet Adapter'
            $nomatchAdapter = [PSObject]@{
                Name                 = 'No Match Adapter'
                PhysicalMediaType    = '802.11'
                Status               = 'Disconnected'
                MacAddress           = '66-55-44-33-22-11'
                InterfaceDescription = 'Some Other Interface #2'
                InterfaceIndex       = 3
                InterfaceGuid        = 'FFFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF'
                DriverDescription    = 'Some Other Interface'
            }
            $matchAdapter = [PSObject]@{
                Name                 = $adapterName
                PhysicalMediaType    = $adapterPhysicalMediaType
                Status               = $adapterStatus
                MacAddress           = $adapterMacAddress
                InterfaceDescription = $adapterInterfaceDescription
                InterfaceIndex       = $adapterInterfaceIndex
                InterfaceGuid        = $adapterInterfaceGuid
                DriverDescription    = $adapterDriverDescription
            }
            $adapterArray = @( $nomatchAdapter, $matchAdapter )
            $multipleMatchingAdapterArray = @( $matchAdapter, $matchAdapter )

            Context 'Name is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -Name $adapterName -Verbose } | Should Not Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Name is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -Name 'NOMATCH' -Verbose } | Should Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'PhysicalMediaType is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -Verbose } | Should Not Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'PhysicalMediaType is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -PhysicalMediaType 'NOMATCH' -Verbose } | Should Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Status is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -Status $adapterStatus -Verbose } | Should Not Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Status is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -Status 'Disabled' -Verbose } | Should Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'MacAddress is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -MacAddress $adapterMacAddress -Verbose } | Should Not Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'MacAddress is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -MacAddress '00-00-00-00-00-00' -Verbose } | Should Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceDescription is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceDescription $adapterInterfaceDescription -Verbose } | Should Not Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceDescription is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceDescription 'NOMATCH' -Verbose } | Should Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceIndex is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceIndex $adapterInterfaceIndex -Verbose } | Should Not Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceIndex is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceIndex 99 -Verbose } | Should Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceGuid is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceGuid $adapterInterfaceGuid -Verbose } | Should Not Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceGuid is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceGuid 'NOMATCH' -Verbose } | Should Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'DriverDescription is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -DriverDescription $adapterDriverDescription -Verbose } | Should Not Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'DriverDescription is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -DriverDescription 'NOMATCH' -Verbose } | Should Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'No parameters are passed and multiple Adapters adapters match but IgnoreMultipleMatchingAdapters is not set' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.MultipleMatchingNetAdapterFound -f 2)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -Verbose } | Should Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'No parameters are passed and multiple Adapters adapters match and IgnoreMultipleMatchingAdapters is set and interface number is 2' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -IgnoreMultipleMatchingAdapters:$true -InterfaceNumber 2 -Verbose } | Should Not Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Multiple Adapters adapters match but IgnoreMultipleMatchingAdapters is not set' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $multipleMatchingAdapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.MultipleMatchingNetAdapterFound -f 2)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -Verbose } | Should Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Multiple Adapters adapters match and IgnoreMultipleMatchingAdapters is set' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $multipleMatchingAdapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -IgnoreMultipleMatchingAdapters:$true -Verbose } | Should Not Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Multiple Adapters adapters match and IgnoreMultipleMatchingAdapters is set and InterfaceNumber is greater than matching adapters' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $multipleMatchingAdapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.InvalidNetAdapterNumberError -f 2,3)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -IgnoreMultipleMatchingAdapters:$true -InterfaceNumber 3 -Verbose } | Should Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }
        }
    }
    #endregion

    #region Function Get-DnsClientServerStaticAddress
    <#
        InModuleScope has to be used to enable the Get-NetAdapter Mock
        This is because forcing the ModuleName in the Mock command throws
        an exception because the GetAdapter module has no manifest
    #>
    InModuleScope $script:ModuleName {
        Describe "NetworkingDsc.Common\Get-DnsClientServerStaticAddress" {

            # Generate the adapter data to be used for Mocking
            $interfaceAlias = 'Adapter'
            $interfaceGuid = [Guid]::NewGuid().ToString()
            $nomatchAdapter = $null
            $matchAdapter = [PSObject]@{
                InterfaceGuid        = $interfaceGuid
            }
            $ipv4Parameters = @{
                InterfaceAlias = $interfaceAlias
                AddressFamily  = 'IPv4'
            }
            $ipv6Parameters = @{
                InterfaceAlias = $interfaceAlias
                AddressFamily  = 'IPv6'
            }
            $noIpv4StaticAddressString = ''
            $oneIpv4StaticAddressString = '8.8.8.8'
            $secondIpv4StaticAddressString = '4.4.4.4'
            $twoIpv4StaticAddressString = "$oneIpv4StaticAddressString,$secondIpv4StaticAddressString"
            $noIpv6StaticAddressString = ''
            $oneIpv6StaticAddressString = '::1'
            $secondIpv6StaticAddressString = '::2'
            $twoIpv6StaticAddressString = "$oneIpv6StaticAddressString,$secondIpv6StaticAddressString"

            Context 'Interface Alias does not match adapter in system' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $nomatchAdapter }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.InterfaceAliasNotFoundError -f $interfaceAlias)

                It 'should throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should Throw $errorRecord
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv4 NameServer is empty' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemPropertyValue `
                    -MockWith { $noIpv4StaticAddressString }

                It 'should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should Not Throw
                }

                It 'should return null' {
                    $script:result | Should BeNullOrEmpty
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemPropertyValue -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv4 NameServer contains one DNS entry' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemPropertyValue `
                    -MockWith { $oneIpv4StaticAddressString }

                It 'should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should Not Throw
                }

                It 'should return expected address' {
                    $script:result | Should Be $oneIpv4StaticAddressString
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemPropertyValue -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv4 NameServer contains two DNS entries' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemPropertyValue `
                    -MockWith { $twoIpv4StaticAddressString }

                It 'should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should Not Throw
                }

                It 'should return two expected addresses' {
                    $script:result[0] | Should Be $oneIpv4StaticAddressString
                    $script:result[1] | Should Be $secondIpv4StaticAddressString
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemPropertyValue -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv6 NameServer is empty' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemPropertyValue `
                    -MockWith { $noIpv6StaticAddressString }

                It 'should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters -Verbose } | Should Not Throw
                }

                It 'should return null' {
                    $script:result | Should BeNullOrEmpty
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemPropertyValue -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv6 NameServer contains one DNS entry' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemPropertyValue `
                    -MockWith { $oneIpv6StaticAddressString }

                It 'should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters -Verbose } | Should Not Throw
                }

                It 'should return expected address' {
                    $script:result | Should Be $oneIpv6StaticAddressString
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemPropertyValue -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv6 NameServer contains two DNS entries' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemPropertyValue `
                    -MockWith { $twoIpv6StaticAddressString }

                It 'should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters -Verbose } | Should Not Throw
                }

                It 'should return two expected addresses' {
                    $script:result[0] | Should Be $oneIpv6StaticAddressString
                    $script:result[1] | Should Be $secondIpv6StaticAddressString
                }

                It 'should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemPropertyValue -Exactly -Times 1
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    #endregion
}
