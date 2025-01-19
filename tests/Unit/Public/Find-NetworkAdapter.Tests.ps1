[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'NetworkingDsc'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Public\Find-NetworkAdapter' {
    BeforeAll {
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

        $script:adapterArray = @( $nomatchAdapter, $matchAdapter )
        $script:multipleMatchingAdapterArray = @( $matchAdapter, $matchAdapter )

        InModuleScope -Parameters @{
            adapterName                 = $adapterName
            adapterPhysicalMediaType    = $adapterPhysicalMediaType
            adapterStatus               = $adapterStatus
            adapterMacAddress           = $adapterMacAddress
            adapterInterfaceDescription = $adapterInterfaceDescription
            adapterInterfaceIndex       = $adapterInterfaceIndex
            adapterInterfaceGuid        = $adapterInterfaceGuid
            adapterDriverDescription    = $adapterDriverDescription
        } -ScriptBlock {
            Set-StrictMode -Version 1.0
            $script:adapterName = $adapterName
            $script:adapterPhysicalMediaType = $adapterPhysicalMediaType
            $script:adapterStatus = $adapterStatus
            $script:adapterMacAddress = $adapterMacAddress
            $script:adapterInterfaceDescription = $adapterInterfaceDescription
            $script:adapterInterfaceIndex = $adapterInterfaceIndex
            $script:adapterInterfaceGuid = $adapterInterfaceGuid
            $script:adapterDriverDescription = $adapterDriverDescription
        }
    }

    Context 'Name is passed and one adapter matches' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Find-NetworkAdapter -Name $adapterName } | Should -Not -Throw
            }
        }

        It 'Should return expected adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Name | Should -Be $adapterName
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Name is passed and no adapters match' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.NetAdapterNotFoundError)

                { $script:result = Find-NetworkAdapter -Name 'NOMATCH' } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'PhysicalMediaType is passed and one adapter matches' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType } | Should -Not -Throw
            }
        }

        It 'Should return expected adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Name | Should -Be $adapterName
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'PhysicalMediaType is passed and no adapters match' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.NetAdapterNotFoundError)

                { $script:result = Find-NetworkAdapter -PhysicalMediaType 'NOMATCH' } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Status is passed and one adapter matches' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Find-NetworkAdapter -Status $adapterStatus } | Should -Not -Throw
            }
        }

        It 'Should return expected adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Name | Should -Be $adapterName
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Status is passed and no adapters match' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }


        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.NetAdapterNotFoundError)

                { $script:result = Find-NetworkAdapter -Status 'Disabled' } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'MacAddress is passed and one adapter matches' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Find-NetworkAdapter -MacAddress $adapterMacAddress } | Should -Not -Throw
            }
        }

        It 'Should return expected adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Name | Should -Be $adapterName
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'MacAddress is passed and no adapters match' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }


        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.NetAdapterNotFoundError)

                { $script:result = Find-NetworkAdapter -MacAddress '00-00-00-00-00-00' } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'InterfaceDescription is passed and one adapter matches' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Find-NetworkAdapter -InterfaceDescription $adapterInterfaceDescription } | Should -Not -Throw
            }
        }

        It 'Should return expected adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Name | Should -Be $adapterName
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'InterfaceDescription is passed and no adapters match' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.NetAdapterNotFoundError)

                { $script:result = Find-NetworkAdapter -InterfaceDescription 'NOMATCH' } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'InterfaceIndex is passed and one adapter matches' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Find-NetworkAdapter -InterfaceIndex $adapterInterfaceIndex } | Should -Not -Throw
            }
        }

        It 'Should return expected adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Name | Should -Be $adapterName
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'InterfaceIndex is passed and no adapters match' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.NetAdapterNotFoundError)

                { $script:result = Find-NetworkAdapter -InterfaceIndex 99 } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'InterfaceGuid is passed and one adapter matches' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Find-NetworkAdapter -InterfaceGuid $adapterInterfaceGuid } | Should -Not -Throw
            }
        }

        It 'Should return expected adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Name | Should -Be $adapterName
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'InterfaceGuid is passed and no adapters match' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.NetAdapterNotFoundError)

                { $script:result = Find-NetworkAdapter -InterfaceGuid 'NOMATCH' } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'DriverDescription is passed and one adapter matches' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Find-NetworkAdapter -DriverDescription $adapterDriverDescription } | Should -Not -Throw
            }
        }

        It 'Should return expected adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Name | Should -Be $adapterName
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'DriverDescription is passed and no adapters match' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.NetAdapterNotFoundError)

                { $script:result = Find-NetworkAdapter -DriverDescription 'NOMATCH' } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'No parameters are passed and multiple Adapters adapters match but IgnoreMultipleMatchingAdapters is not set' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.MultipleMatchingNetAdapterFound -f 2)

                { $script:result = Find-NetworkAdapter } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'No parameters are passed and multiple Adapters adapters match and IgnoreMultipleMatchingAdapters is set and interface number is 2' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:adapterArray }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Find-NetworkAdapter -IgnoreMultipleMatchingAdapters:$true -InterfaceNumber 2 } | Should -Not -Throw
            }
        }

        It 'Should return expected adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Name | Should -Be $adapterName
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Multiple Adapters adapters match but IgnoreMultipleMatchingAdapters is not set' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:multipleMatchingAdapterArray }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.MultipleMatchingNetAdapterFound -f 2)

                { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Multiple Adapters adapters match and IgnoreMultipleMatchingAdapters is set' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:multipleMatchingAdapterArray }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -IgnoreMultipleMatchingAdapters:$true } | Should -Not -Throw
            }
        }

        It 'Should return expected adapter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Name | Should -Be $adapterName
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Multiple Adapters adapters match and IgnoreMultipleMatchingAdapters is set and InterfaceNumber is greater than matching adapters' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:multipleMatchingAdapterArray }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.InvalidNetAdapterNumberError -f 2, 3)

                { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -IgnoreMultipleMatchingAdapters:$true -InterfaceNumber 3 } | Should -Throw $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }
}
