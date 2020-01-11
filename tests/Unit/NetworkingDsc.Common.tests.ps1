$script:ModuleName = 'NetworkingDsc.Common'

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
Import-Module (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath $script:ModuleName)) -ChildPath "$script:ModuleName.psm1") -Force
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:ModuleName {
        Describe 'NetworkingDsc.Common\Test-IsNanoServer' {
            Context 'When the cmdlet Get-ComputerInfo does not exist' {
                BeforeAll {
                    Mock -CommandName Test-Command -MockWith {
                        return $false
                    }
                }

                Test-IsNanoServer | Should -Be $false
            }

            Context 'When the current computer is a Nano server' {
                BeforeAll {
                    Mock -CommandName Test-Command -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ComputerInfo -MockWith {
                        return @{
                            OsProductType = 'Server'
                            OsServerLevel = 'NanoServer'
                        }
                    }
                }

                Test-IsNanoServer | Should -Be $true
            }

            Context 'When the current computer is not a Nano server' {
                BeforeAll {
                    Mock -CommandName Test-Command -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ComputerInfo -MockWith {
                        return @{
                            OsProductType = 'Server'
                            OsServerLevel = 'FullServer'
                        }
                    }
                }

                Test-IsNanoServer | Should -Be $false
            }
        }

        Describe 'NetworkingDsc.Common\Get-LocalizedData' {
            $mockTestPath = {
                return $mockTestPathReturnValue
            }

            $mockImportLocalizedData = {
                $BaseDirectory | Should -Be $mockExpectedLanguagePath
            }

            BeforeEach {
                Mock -CommandName Test-Path -MockWith $mockTestPath -Verifiable
                Mock -CommandName Import-LocalizedData -MockWith $mockImportLocalizedData -Verifiable
            }

            Context 'When loading localized data for Swedish' {
                $mockExpectedLanguagePath = 'sv-SE'
                $mockTestPathReturnValue = $true

                It 'Should call Import-LocalizedData with sv-SE language' {
                    Mock -CommandName Join-Path -MockWith {
                        return 'sv-SE'
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 3 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $false

                It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                    Mock -CommandName Join-Path -MockWith {
                        return $ChildPath
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 4 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }

                Context 'When $ScriptRoot is set to a path' {
                    $mockExpectedLanguagePath = 'sv-SE'
                    $mockTestPathReturnValue = $true

                    It 'Should call Import-LocalizedData with sv-SE language' {
                        Mock -CommandName Join-Path -MockWith {
                            return 'sv-SE'
                        } -Verifiable

                        { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                        Assert-MockCalled -CommandName Join-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                    }

                    $mockExpectedLanguagePath = 'en-US'
                    $mockTestPathReturnValue = $false

                    It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                        Mock -CommandName Join-Path -MockWith {
                            return $ChildPath
                        } -Verifiable

                        { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                        Assert-MockCalled -CommandName Join-Path -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When loading localized data for English' {
                Mock -CommandName Join-Path -MockWith {
                    return 'en-US'
                } -Verifiable

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $true

                It 'Should call Import-LocalizedData with en-US language' {
                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-InvalidResultException' {
            Context 'When calling with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-InvalidResultException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When calling with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-InvalidResultException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.Exception: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-ObjectNotFoundException' {
            Context 'When calling with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-ObjectNotFoundException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When calling with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-ObjectNotFoundException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.Exception: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-InvalidOperationException' {
            Context 'When calling with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-InvalidOperationException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When calling with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-InvalidOperationException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.InvalidOperationException: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-NotImplementedException' {
            Context 'When called with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-NotImplementedException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When called with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-NotImplementedException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.NotImplementedException: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-InvalidArgumentException' {
            Context 'When calling with both the Message and ArgumentName parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockArgumentName = 'MockArgument'

                    { New-InvalidArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } | Should -Throw ('Parameter name: {0}' -f $mockArgumentName)
                }
            }

            Assert-VerifiableMock
        }

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

        Describe 'NetworkingDsc.Common\Remove-CommonParameter' {
            $removeCommonParameter = @{
                Parameter1          = 'value1'
                Parameter2          = 'value2'
                Verbose             = $true
                Debug               = $true
                ErrorAction         = 'Stop'
                WarningAction       = 'Stop'
                InformationAction   = 'Stop'
                ErrorVariable       = 'errorVariable'
                WarningVariable     = 'warningVariable'
                OutVariable         = 'outVariable'
                OutBuffer           = 'outBuffer'
                PipelineVariable    = 'pipelineVariable'
                InformationVariable = 'informationVariable'
                WhatIf              = $true
                Confirm             = $true
                UseTransaction      = $true
            }

            Context 'Hashtable contains all common parameters' {
                It 'Should not throw exception' {
                    { $script:result = Remove-CommonParameter -Hashtable $removeCommonParameter -Verbose } | Should -Not -Throw
                }

                It 'Should have retained parameters in the hashtable' {
                    $script:result.Contains('Parameter1') | Should -Be $true
                    $script:result.Contains('Parameter2') | Should -Be $true
                }

                It 'Should have removed the common parameters from the hashtable' {
                    $script:result.Contains('Verbose') | Should -Be $false
                    $script:result.Contains('Debug') | Should -Be $false
                    $script:result.Contains('ErrorAction') | Should -Be $false
                    $script:result.Contains('WarningAction') | Should -Be $false
                    $script:result.Contains('InformationAction') | Should -Be $false
                    $script:result.Contains('ErrorVariable') | Should -Be $false
                    $script:result.Contains('WarningVariable') | Should -Be $false
                    $script:result.Contains('OutVariable') | Should -Be $false
                    $script:result.Contains('OutBuffer') | Should -Be $false
                    $script:result.Contains('PipelineVariable') | Should -Be $false
                    $script:result.Contains('InformationVariable') | Should -Be $false
                    $script:result.Contains('WhatIf') | Should -Be $false
                    $script:result.Contains('Confirm') | Should -Be $false
                    $script:result.Contains('UseTransaction') | Should -Be $false
                }
            }
        }

        Describe 'ComputerManagementDsc.Common\Test-DscParameterState' {
            $verbose = $true

            Context 'When testing single values' {
                $currentValues = @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }

                Context 'When all values match' {
                    $desiredValues = [PSObject] @{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When a string is mismatched' {
                    $desiredValues = [PSObject] @{
                        String    = 'different string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When a boolean is mismatched' {
                    $desiredValues = [PSObject] @{
                        String    = 'a string'
                        Bool      = $false
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When an int is mismatched' {
                    $desiredValues = [PSObject] @{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 1
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When a type is mismatched' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = '99'
                        Array  = 'a', 'b', 'c'
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When a type is mismatched but TurnOffTypeChecking is used' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = '99'
                        Array  = 'a', 'b', 'c'
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -TurnOffTypeChecking `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When a value is mismatched but valuesToCheck is used to exclude them' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $false
                        Int    = 1
                        Array  = @( 'a', 'b' )
                    }

                    $valuesToCheck = @(
                        'String'
                    )

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -ValuesToCheck $valuesToCheck `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }
            }

            Context 'When testing array values' {
                BeforeAll {
                    $currentValues = @{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c', 1
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }
                }

                Context 'When array is missing a value' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 1
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When array has an additional value' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 1
                        Array  = 'a', 'b', 'c', 1, 2
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When array has a different value' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 1
                        Array  = 'a', 'x', 'c', 1
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When array has different order' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 1
                        Array  = 'c', 'b', 'a', 1
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When array has different order but SortArrayValues is used' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 1
                        Array  = 'c', 'b', 'a', 1
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -SortArrayValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }


                Context 'When array has a value with a different type' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 99
                        Array  = 'a', 'b', 'c', '1'
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When array has a value with a different type but TurnOffTypeChecking is used' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 99
                        Array  = 'a', 'b', 'c', '1'
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -TurnOffTypeChecking `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When both arrays are empty' {
                    $currentValues = @{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = @()
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = @()
                        }
                    }

                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = @()
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = @()
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }
            }

            Context 'When testing hashtables' {
                $currentValues = @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }
                }

                Context 'When hashtable is missing a value' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When hashtable has an additional value' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99, 100
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When hashtable has a different value' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'xx', 'v2', 'v3', 99
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When an array in hashtable has different order' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v3', 'v2', 'v1', 99
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When an array in hashtable has different order but SortArrayValues is used' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v3', 'v2', 'v1', 99
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -SortArrayValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }


                Context 'When hashtable has a value with a different type' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', '99'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When hashtable has a value with a different type but TurnOffTypeChecking is used' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -TurnOffTypeChecking `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }
            }

            Context 'When testing CimInstances / hashtables' {
                $currentValues = @{
                    String       = 'a string'
                    Bool         = $true
                    Int          = 99
                    Array        = 'a', 'b', 'c'
                    Hashtable    = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }
                    CimInstances = [CimInstance[]](ConvertTo-CimInstance -Hashtable @{
                            String = 'a string'
                            Bool   = $true
                            Int    = 99
                            Array  = 'a, b, c'
                        })
                }

                Context 'When everything matches' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = [CimInstance[]](ConvertTo-CimInstance -Hashtable @{
                                String = 'a string'
                                Bool   = $true
                                Int    = 99
                                Array  = 'a, b, c'
                            })
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When CimInstances missing a value in the desired state (not recognized)' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'a string'
                            Bool   = $true
                            Array  = 'a, b, c'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When CimInstances missing a value in the desired state (recognized using ReverseCheck)' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'a string'
                            Bool   = $true
                            Array  = 'a, b, c'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -ReverseCheck `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When CimInstances have an additional value' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'a string'
                            Bool   = $true
                            Int    = 99
                            Array  = 'a, b, c'
                            Test   = 'Some string'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When CimInstances have a different value' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'some other string'
                            Bool   = $true
                            Int    = 99
                            Array  = 'a, b, c'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When CimInstances have a value with a different type' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'a string'
                            Bool   = $true
                            Int    = '99'
                            Array  = 'a, b, c'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When CimInstances have a value with a different type but TurnOffTypeChecking is used' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'a string'
                            Bool   = $true
                            Int    = '99'
                            Array  = 'a, b, c'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -TurnOffTypeChecking `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }
            }

            Context 'When reverse checking' {
                $currentValues = @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c', 1
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }

                Context 'When even if missing property in the desired state' {
                    $desiredValues = [PSObject] @{
                        Array     = 'a', 'b', 'c', 1
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When missing property in the desired state' {
                    $currentValues = @{
                        String = 'a string'
                        Bool   = $true
                    }

                    $desiredValues = [PSObject] @{
                        String = 'a string'
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -ReverseCheck `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }
            }

            Context 'When testing parameter types' {
                Context 'When desired value is of the wrong type' {
                    $currentValues = @{
                        String = 'a string'
                    }

                    $desiredValues = 1, 2, 3

                    It 'Should throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Throw
                    }
                }

                Context 'When current value is of the wrong type' {
                    $currentValues = 1, 2, 3

                    $desiredValues = @{
                        String = 'a string'
                    }

                    It 'Should throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Throw
                    }
                }
            }
        }

        Describe 'NetworkingDsc.Common\Test-DscObjectHasProperty' {
            # Use the Get-Verb cmdlet to just get a simple object fast
            $testDscObject = (Get-Verb)[0]

            Context 'When the object contains the expected property' {
                It 'Should not throw exception' {
                    { $script:result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Verb' -Verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -Be $true
                }
            }

            Context 'When the object does not contain the expected property' {
                It 'Should not throw exception' {
                    { $script:result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Missing' -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }
        }

        Describe 'NetworkingDsc.Common\ConvertTo-CimInstance' {
            $hashtable = @{
                k1 = 'v1'
                k2 = 100
                k3 = 1, 2, 3
            }

            Context 'When the array contains the expected record count' {
                It 'Should not throw exception' {
                    { $script:result = [CimInstance[]]($hashtable | ConvertTo-CimInstance) } | Should -Not -Throw
                }

                It "Should record count should be $($hashTable.Count)" {
                    $script:result.Count | Should -Be $hashtable.Count
                }

                It 'Should return result of type CimInstance[]' {
                    $script:result.GetType().Name | Should -Be 'CimInstance[]'
                }

                It 'Should return value "k1" in the CimInstance array should be "v1"' {
                    ($script:result | Where-Object Key -eq k1).Value | Should -Be 'v1'
                }

                It 'Should return value "k2" in the CimInstance array should be "100"' {
                    ($script:result | Where-Object Key -eq k2).Value | Should -Be 100
                }

                It 'Should return value "k3" in the CimInstance array should be "1,2,3"' {
                    ($script:result | Where-Object Key -eq k3).Value | Should -Be '1,2,3'
                }
            }
        }

        Describe 'NetworkingDsc.Common\ConvertTo-HashTable' {
            [CimInstance[]]$cimInstances = ConvertTo-CimInstance -Hashtable @{
                k1 = 'v1'
                k2 = 100
                k3 = 1, 2, 3
            }

            Context 'When the array contains the expected record count' {
                It 'Should not throw exception' {
                    { $script:result = $cimInstances | ConvertTo-HashTable } | Should -Not -Throw
                }

                It "Should return record count of $($cimInstances.Count)" {
                    $script:result.Count | Should -Be $cimInstances.Count
                }

                It 'Should return result of type [System.Collections.Hashtable]' {
                    $script:result | Should -BeOfType [System.Collections.Hashtable]
                }

                It 'Should return value "k1" in the hashtable should be "v1"' {
                    $script:result.k1 | Should -Be 'v1'
                }

                It 'Should return value "k2" in the hashtable should be "100"' {
                    $script:result.k2 | Should -Be 100
                }

                It 'Should return value "k3" in the hashtable should be "1,2,3"' {
                    $script:result.k3 | Should -Be '1,2,3'
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

        Describe 'NetworkingDsc.Common\Format-Win32NetworkADapterFilterByNetConnectionID'{
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
}
finally
{
    #region FOOTER
    #endregion
}
