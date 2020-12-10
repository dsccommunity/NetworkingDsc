#region HEADER
$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            { $false
            })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)/$($script:subModuleName).psm1"

Import-Module $script:subModuleFile -Force -ErrorAction Stop
#endregion HEADER

InModuleScope $script:subModuleName {
    Describe 'NetworkingDsc.Common\Convert-CIDRToSubhetMask' {
        Context 'Subnet Mask Notation Used "192.168.0.0/255.255.0.0"' {
            It 'Should Return "192.168.0.0/255.255.0.0"' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.0/255.255.0.0') | Should -Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'Subnet Mask Notation Used "192.168.0.10/255.255.0.0" resulting in source bits masked' {
            It 'Should Return "192.168.0.0/255.255.0.0" with source bits masked' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.10/255.255.0.0') | Should -Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'CIDR Notation Used "192.168.0.0/16"' {
            It 'Should Return "192.168.0.0/255.255.0.0"' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.0/16') | Should -Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'CIDR Notation Used "192.168.0.10/16" resulting in source bits masked' {
            It 'Should Return "192.168.0.0/255.255.0.0" with source bits masked' {
                Convert-CIDRToSubhetMask -Address @('192.168.0.10/16') | Should -Be '192.168.0.0/255.255.0.0'
            }
        }
        Context 'Multiple Notations Used "192.168.0.0/16,10.0.0.24/255.255.255.0"' {
            $Result = Convert-CIDRToSubhetMask -Address @('192.168.0.0/16', '10.0.0.24/255.255.255.0')
            It 'Should Return "192.168.0.0/255.255.0.0,10.0.0.0/255.255.255.0"' {
                $Result[0] | Should -Be '192.168.0.0/255.255.0.0'
                $Result[1] | Should -Be '10.0.0.0/255.255.255.0'
            }
        }
        Context 'Range Used "192.168.1.0-192.168.1.128"' {
            It 'Should Return "192.168.1.0-192.168.1.128"' {
                Convert-CIDRToSubhetMask -Address @('192.168.1.0-192.168.1.128') | Should -Be '192.168.1.0-192.168.1.128'
            }
        }
        Context 'IPv6 Used "fe80::/112"' {
            It 'Should Return "fe80::/112"' {
                Convert-CIDRToSubhetMask -Address @('fe80::/112') | Should -Be 'fe80::/112'
            }
        }
    }

    <#
        InModuleScope has to be used to enable the Get-NetAdapter Mock
        This is because forcing the ModuleName in the Mock command throws
        an exception because the GetAdapter module has no manifest
    #>
    Describe 'NetworkingDsc.Common\Find-NetworkAdapter' {

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
                { $script:result = Find-NetworkAdapter -Name $adapterName -Verbose } | Should -Not -Throw
            }

            It 'Should return expected adapter' {
                $script:result.Name | Should -Be $adapterName
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
                -Message ($script:localizedData.NetAdapterNotFoundError)

            It 'Should throw the correct exception' {
                { $script:result = Find-NetworkAdapter -Name 'NOMATCH' -Verbose } | Should -Throw $errorRecord
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
                { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -Verbose } | Should -Not -Throw
            }

            It 'Should return expected adapter' {
                $script:result.Name | Should -Be $adapterName
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
                -Message ($script:localizedData.NetAdapterNotFoundError)

            It 'Should throw the correct exception' {
                { $script:result = Find-NetworkAdapter -PhysicalMediaType 'NOMATCH' -Verbose } | Should -Throw $errorRecord
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
                { $script:result = Find-NetworkAdapter -Status $adapterStatus -Verbose } | Should -Not -Throw
            }

            It 'Should return expected adapter' {
                $script:result.Name | Should -Be $adapterName
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
                -Message ($script:localizedData.NetAdapterNotFoundError)

            It 'Should throw the correct exception' {
                { $script:result = Find-NetworkAdapter -Status 'Disabled' -Verbose } | Should -Throw $errorRecord
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
                { $script:result = Find-NetworkAdapter -MacAddress $adapterMacAddress -Verbose } | Should -Not -Throw
            }

            It 'Should return expected adapter' {
                $script:result.Name | Should -Be $adapterName
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
                -Message ($script:localizedData.NetAdapterNotFoundError)

            It 'Should throw the correct exception' {
                { $script:result = Find-NetworkAdapter -MacAddress '00-00-00-00-00-00' -Verbose } | Should -Throw $errorRecord
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
                { $script:result = Find-NetworkAdapter -InterfaceDescription $adapterInterfaceDescription -Verbose } | Should -Not -Throw
            }

            It 'Should return expected adapter' {
                $script:result.Name | Should -Be $adapterName
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
                -Message ($script:localizedData.NetAdapterNotFoundError)

            It 'Should throw the correct exception' {
                { $script:result = Find-NetworkAdapter -InterfaceDescription 'NOMATCH' -Verbose } | Should -Throw $errorRecord
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
                { $script:result = Find-NetworkAdapter -InterfaceIndex $adapterInterfaceIndex -Verbose } | Should -Not -Throw
            }

            It 'Should return expected adapter' {
                $script:result.Name | Should -Be $adapterName
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
                -Message ($script:localizedData.NetAdapterNotFoundError)

            It 'Should throw the correct exception' {
                { $script:result = Find-NetworkAdapter -InterfaceIndex 99 -Verbose } | Should -Throw $errorRecord
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
                { $script:result = Find-NetworkAdapter -InterfaceGuid $adapterInterfaceGuid -Verbose } | Should -Not -Throw
            }

            It 'Should return expected adapter' {
                $script:result.Name | Should -Be $adapterName
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
                -Message ($script:localizedData.NetAdapterNotFoundError)

            It 'Should throw the correct exception' {
                { $script:result = Find-NetworkAdapter -InterfaceGuid 'NOMATCH' -Verbose } | Should -Throw $errorRecord
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
                { $script:result = Find-NetworkAdapter -DriverDescription $adapterDriverDescription -Verbose } | Should -Not -Throw
            }

            It 'Should return expected adapter' {
                $script:result.Name | Should -Be $adapterName
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
                -Message ($script:localizedData.NetAdapterNotFoundError)

            It 'Should throw the correct exception' {
                { $script:result = Find-NetworkAdapter -DriverDescription 'NOMATCH' -Verbose } | Should -Throw $errorRecord
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
                -Message ($script:localizedData.MultipleMatchingNetAdapterFound -f 2)

            It 'Should throw the correct exception' {
                { $script:result = Find-NetworkAdapter -Verbose } | Should -Throw $errorRecord
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
                { $script:result = Find-NetworkAdapter -IgnoreMultipleMatchingAdapters:$true -InterfaceNumber 2 -Verbose } | Should -Not -Throw
            }

            It 'Should return expected adapter' {
                $script:result.Name | Should -Be $adapterName
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
                -Message ($script:localizedData.MultipleMatchingNetAdapterFound -f 2)

            It 'Should throw the correct exception' {
                { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -Verbose } | Should -Throw $errorRecord
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
                { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -IgnoreMultipleMatchingAdapters:$true -Verbose } | Should -Not -Throw
            }

            It 'Should return expected adapter' {
                $script:result.Name | Should -Be $adapterName
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
                -Message ($script:localizedData.InvalidNetAdapterNumberError -f 2, 3)

            It 'Should throw the correct exception' {
                { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -IgnoreMultipleMatchingAdapters:$true -InterfaceNumber 3 -Verbose } | Should -Throw $errorRecord
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
            }
        }
    }

    <#
        InModuleScope has to be used to enable the Get-NetAdapter Mock
        This is because forcing the ModuleName in the Mock command throws
        an exception because the GetAdapter module has no manifest
    #>
    Describe 'NetworkingDsc.Common\Get-DnsClientServerStaticAddress' {

        # Generate the adapter data to be used for Mocking
        $interfaceAlias = 'Adapter'
        $interfaceGuid = [Guid]::NewGuid().ToString()
        $nomatchAdapter = $null
        $matchAdapter = [PSObject]@{
            InterfaceGuid = $interfaceGuid
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
                -Message ($script:localizedData.InterfaceAliasNotFoundError -f $interfaceAlias)

            It 'Should throw exception' {
                { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should -Throw $errorRecord
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
            }
        }

        Context 'Interface Alias was found in system but IPv4 NameServer is empty' {
            Mock `
                -CommandName Get-NetAdapter `
                -MockWith { $matchAdapter }

            Mock `
                -CommandName Get-ItemProperty `
                -MockWith {
                [psobject] @{
                    NameServer = $noIpv4StaticAddressString
                }
            }

            It 'Should not throw exception' {
                { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
            }
        }

        Context 'Interface Alias was found in system but IPv4 NameServer property does not exist' {
            Mock `
                -CommandName Get-NetAdapter `
                -MockWith { $matchAdapter }

            Mock `
                -CommandName Get-ItemProperty `
                -MockWith {
                [psobject] @{
                    Dummy = ''
                }
            }

            It 'Should not throw exception' {
                { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
            }
        }

        Context 'Interface Alias was found in system but IPv4 NameServer contains one DNS entry' {
            Mock `
                -CommandName Get-NetAdapter `
                -MockWith { $matchAdapter }

            Mock `
                -CommandName Get-ItemProperty `
                -MockWith {
                [psobject] @{
                    NameServer = $oneIpv4StaticAddressString
                }
            }

            It 'Should not throw exception' {
                { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return expected address' {
                $script:result | Should -Be $oneIpv4StaticAddressString
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
            }
        }

        Context 'Interface Alias was found in system but IPv4 NameServer contains two DNS entries' {
            Mock `
                -CommandName Get-NetAdapter `
                -MockWith { $matchAdapter }

            Mock `
                -CommandName Get-ItemProperty `
                -MockWith {
                [psobject] @{
                    NameServer = $twoIpv4StaticAddressString
                }
            }

            It 'Should not throw exception' {
                { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return two expected addresses' {
                $script:result[0] | Should -Be $oneIpv4StaticAddressString
                $script:result[1] | Should -Be $secondIpv4StaticAddressString
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
            }
        }

        Context 'Interface Alias was found in system but IPv6 NameServer is empty' {
            Mock `
                -CommandName Get-NetAdapter `
                -MockWith { $matchAdapter }

            Mock `
                -CommandName Get-ItemProperty `
                -MockWith {
                [psobject] @{
                    NameServer = $noIpv6StaticAddressString
                }
            }

            It 'Should not throw exception' {
                { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
            }
        }

        Context 'Interface Alias was found in system but IPv6 NameServer property does not exist' {
            Mock `
                -CommandName Get-NetAdapter `
                -MockWith { $matchAdapter }

            Mock `
                -CommandName Get-ItemProperty `
                -MockWith {
                [psobject] @{
                    Dummy = ''
                }
            }

            It 'Should not throw exception' {
                { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
            }
        }

        Context 'Interface Alias was found in system but IPv6 NameServer contains one DNS entry' {
            Mock `
                -CommandName Get-NetAdapter `
                -MockWith { $matchAdapter }

            Mock `
                -CommandName Get-ItemProperty `
                -MockWith {
                [psobject] @{
                    NameServer = $oneIpv6StaticAddressString
                }
            }

            It 'Should not throw exception' {
                { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return expected address' {
                $script:result | Should -Be $oneIpv6StaticAddressString
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
            }
        }

        Context 'Interface Alias was found in system but IPv6 NameServer contains two DNS entries' {
            Mock `
                -CommandName Get-NetAdapter `
                -MockWith { $matchAdapter }

            Mock `
                -CommandName Get-ItemProperty `
                -MockWith {
                [psobject] @{
                    NameServer = $twoIpv6StaticAddressString
                }
            }

            It 'Should not throw exception' {
                { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return two expected addresses' {
                $script:result[0] | Should -Be $oneIpv6StaticAddressString
                $script:result[1] | Should -Be $secondIpv6StaticAddressString
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
            }
        }
    }

    Describe 'NetworkingDsc.Common\Get-IPAddressPrefix' {
        Context 'IPv4 CIDR notation provided' {
            it 'Should return the provided IP and prefix as separate properties' {
                $IPaddress = Get-IPAddressPrefix -IPAddress '192.168.10.0/24'

                $IPaddress.IPaddress | Should -Be '192.168.10.0'
                $IPaddress.PrefixLength | Should -Be 24
            }
        }

        Context 'IPv4 Class A address with no CIDR notation' {
            it 'Should return correct prefix when Class A address provided' {
                $IPaddress = Get-IPAddressPrefix -IPAddress '10.1.2.3'

                $IPaddress.IPaddress | Should -Be '10.1.2.3'
                $IPaddress.PrefixLength | Should -Be 8
            }
        }

        Context 'IPv4 Class B address with no CIDR notation' {
            it 'Should return correct prefix when Class B address provided' {
                $IPaddress = Get-IPAddressPrefix -IPAddress '172.16.2.3'

                $IPaddress.IPaddress | Should -Be '172.16.2.3'
                $IPaddress.PrefixLength | Should -Be 16
            }
        }

        Context 'IPv4 Class C address with no CIDR notation' {
            it 'Should return correct prefix when Class C address provided' {
                $IPaddress = Get-IPAddressPrefix -IPAddress '192.168.20.3'

                $IPaddress.IPaddress | Should -Be '192.168.20.3'
                $IPaddress.PrefixLength | Should -Be 24
            }
        }

        Context 'IPv6 CIDR notation provided' {
            it 'Should return provided IP and prefix as separate properties' {
                $IPaddress = Get-IPAddressPrefix -IPAddress 'FF12::12::123/64' -AddressFamily IPv6

                $IPaddress.IPaddress | Should -Be 'FF12::12::123'
                $IPaddress.PrefixLength | Should -Be 64
            }
        }

        Context 'IPv6 with no CIDR notation provided' {
            it 'Should return provided IP and correct IPv6 prefix' {
                $IPaddress = Get-IPAddressPrefix -IPAddress 'FF12::12::123' -AddressFamily IPv6

                $IPaddress.IPaddress | Should -Be 'FF12::12::123'
                $IPaddress.PrefixLength | Should -Be 64
            }
        }
    }

    Describe 'NetworkingDsc.Common\Get-WinsClientServerStaticAddress' {

        # Generate the adapter data to be used for Mocking
        $interfaceAlias = 'Adapter'
        $interfaceGuid = [Guid]::NewGuid().ToString()
        $nomatchAdapter = $null
        $matchAdapter = @{
            InterfaceGuid = $interfaceGuid
        }
        $parameters = @{
            InterfaceAlias = $interfaceAlias
        }
        $noIpStaticAddressString = ''
        $oneIpStaticAddressString = '8.8.8.8'
        $secondIpStaticAddressString = '4.4.4.4'
        $twoIpStaticAddressString = $oneIpStaticAddressString, $secondIpStaticAddressString

        Context 'When interface alias does not match adapter in system' {
            Mock Get-NetAdapter -MockWith { $nomatchAdapter }

            $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.InterfaceAliasNotFoundError -f $interfaceAlias)

            It 'Should throw exception' {
                { $script:result = Get-WinsClientServerStaticAddress @parameters -Verbose } | Should -Throw $errorRecord
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
            }
        }

        Context 'When interface alias was found in system and WINS server is empty' {
            Mock Get-NetAdapter -MockWith { $matchAdapter }
            Mock Get-ItemProperty -MockWith {
                @{
                    NameServer = $noIpStaticAddressString
                }
            }

            It 'Should not throw exception' {
                { $script:result = Get-WinsClientServerStaticAddress @parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
            }
        }

        Context 'When interface alias was found in system and WINS server list contains one entry' {
            Mock Get-NetAdapter -MockWith { $matchAdapter }
            Mock Get-ItemProperty -MockWith {
                @{
                    NameServerList = $oneIpStaticAddressString
                }
            }

            It 'Should not throw exception' {
                { $script:result = Get-WinsClientServerStaticAddress @parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return expected address' {
                $script:result | Should -Be $oneIpStaticAddressString
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
            }
        }

        Context 'When interface alias was found in system and WINS server list contains two entries' {
            Mock Get-NetAdapter -MockWith { $matchAdapter }
            Mock Get-ItemProperty -MockWith {
                @{
                    NameServerList = $twoIpStaticAddressString
                }
            }

            It 'Should not throw exception' {
                { $script:result = Get-WinsClientServerStaticAddress @parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return two expected addresses' {
                $script:result[0] | Should -Be $oneIpStaticAddressString
                $script:result[1] | Should -Be $secondIpStaticAddressString
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
            }
        }
    }

    Describe 'NetworkingDsc.Common\Set-WinsClientServerStaticAddress' {

        # Generate the adapter data to be used for Mocking
        $interfaceAlias = 'Adapter'
        $interfaceGuid = [Guid]::NewGuid().ToString()
        $nomatchAdapter = $null
        $matchAdapter = @{
            InterfaceGuid = $interfaceGuid
        }
        $parameters = @{
            InterfaceAlias = $interfaceAlias
        }
        $noIpStaticAddressString = ''
        $oneIpStaticAddressString = '8.8.8.8'
        $secondIpStaticAddressString = '4.4.4.4'
        $twoIpStaticAddressString = $oneIpStaticAddressString, $secondIpStaticAddressString

        Context 'When interface alias does not match adapter in system' {
            Mock Get-NetAdapter -MockWith { $nomatchAdapter }

            $parameters.Address = @()

            $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.InterfaceAliasNotFoundError -f $interfaceAlias)

            It 'Should throw exception' {
                { $script:result = Set-WinsClientServerStaticAddress @parameters -Verbose } | Should -Throw $errorRecord
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
            }
        }

        Context 'When interface alias was found in system and WINS server address is set to $null' {
            Mock Get-NetAdapter -MockWith { $matchAdapter }
            Mock Set-ItemProperty -MockWith { }

            $parameters.Address = @()

            It 'Should not throw exception' {
                { $script:result = Set-WinsClientServerStaticAddress @parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
            }
        }

        Context 'When interface alias was found in system and WINS server address is set to a single entry' {
            Mock Get-NetAdapter -MockWith { $matchAdapter }
            Mock Set-ItemProperty -MockWith { }

            $parameters.Address = $oneIpStaticAddressString

            It 'Should not throw exception' {
                { $script:result = Set-WinsClientServerStaticAddress @parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
            }
        }

        Context 'When interface alias was found in system and WINS server address is set to two enties' {
            Mock Get-NetAdapter -MockWith { $matchAdapter }
            Mock Set-ItemProperty -MockWith { }

            $parameters.Address = $twoIpStaticAddressString

            It 'Should not throw exception' {
                { $script:result = Set-WinsClientServerStaticAddress @parameters -Verbose } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
            }
        }
    }

    Describe 'NetworkingDsc.Common\Format-Win32NetworkADapterFilterByNetConnectionID' {
        Context 'When interface alias has an ''*''' {
            $interfaceAlias = 'Ether*'

            It 'Should convert the ''*'' to a ''%''' {
                (Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias).Contains('%') -eq $True -and
                (Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias).Contains('*') -eq $False | Should -Be $True
            }

            It 'Should change the operator to ''LIKE''' {
                (Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias) | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
            }

            It 'Should look like a usable filter' {
                Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
            }
        }

        Context 'When interface alias has a ''%''' {
            $interfaceAlias = 'Ether%'

            It 'Should change the operator to ''LIKE''' {
                (Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias) | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
            }

            It 'Should look like a usable filter' {
                Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
            }
        }

        Context 'When interface alias has no wildcards' {
            $interfaceAlias = 'Ethernet'

            It 'Should look like a usable filter' {
                Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias | Should -BeExactly 'NetConnectionID="Ethernet"'
            }
        }
    }
}
