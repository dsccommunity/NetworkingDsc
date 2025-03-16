[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'Firewall'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceFriendlyName = 'Firewall'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $script:subModuleName = 'NetworkingDsc.Common'
    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'
}

AfterAll {
    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe 'Firewall Integration Tests' {
    BeforeAll {
        # Create a config data object to pass to the Add Rule Config
        $script:ruleNameGuid = [Guid]::NewGuid().ToString()
        $script:ruleName = $script:ruleNameGuid + '[]*'
        $script:ruleNameEscaped = $script:ruleNameGuid + '`[`]`*'
        $configData = @{
            AllNodes = @(
                @{
                    NodeName            = 'localhost'
                    RuleName            = $script:ruleName
                    Ensure              = 'Present'
                    DisplayName         = 'Test Rule'
                    Group               = 'Test Group'
                    DisplayGroup        = 'Test Group'
                    Enabled             = 'False'
                    Profile             = @('Domain', 'Private')
                    Action              = 'Allow'
                    Description         = 'DSC_Firewall Test Firewall Rule'
                    Direction           = 'Inbound'
                    RemotePort          = @('8080', '8081')
                    LocalPort           = @('9080', '9081')
                    Protocol            = 'TCP'
                    Program             = 'c:\windows\system32\notepad.exe'
                    Service             = 'WinRM'
                    Authentication      = 'NotRequired'
                    Encryption          = 'NotRequired'
                    InterfaceAlias      = (Get-NetAdapter -Physical | Select-Object -First 1).Name
                    InterfaceType       = 'Wired'
                    LocalAddress        = @('192.168.2.0-192.168.2.128', '192.168.1.0/255.255.255.0', '10.0.240.1/8')
                    LocalUser           = 'Any'
                    Package             = 'S-1-15-2-3676279713-3632409675-756843784-3388909659-2454753834-4233625902-1413163418'
                    Platform            = @('6.1')
                    RemoteAddress       = @('192.168.2.0-192.168.2.128', '192.168.1.0/255.255.255.0')
                    RemoteMachine       = 'Any'
                    RemoteUser          = 'Any'
                    DynamicTransport    = 'Any'
                    EdgeTraversalPolicy = 'Allow'
                    LocalOnlyMapping    = $false
                    LooseSourceMapping  = $false
                    OverrideBlockRules  = $false
                    Owner               = (Get-CimInstance win32_useraccount | Select-Object -First 1).Sid
                    IcmpType            = 'Any'
                }
            )
        }

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_add.config.ps1"
        . $configFile
    }

    AfterAll {
        if (Get-NetFirewallRule -Name $script:ruleNameEscaped -ErrorAction SilentlyContinue)
        {
            Remove-NetFirewallRule -Name $script:ruleNameEscaped
        }
    }

    Describe "$($script:dscResourceName)_Add_Integration" {
        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Add_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration `
                    -Path $TestDrive `
                    -ComputerName localhost `
                    -Wait `
                    -Verbose `
                    -Force `
                    -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { $script:current = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'DSC resource state' {
            BeforeDiscovery {
                $arrayTestCases = @(
                    @{ Name = 'Profile'; Variable = 'FirewallRule'; Type = 'Array'; Delimiter = ', ' }
                    @{ Name = 'RemotePort'; Variable = 'properties'; Property = 'PortFilters'; Type = 'Array' }
                    @{ Name = 'LocalPort'; Variable = 'properties'; Property = 'PortFilters'; Type = 'Array' }
                    @{ Name = 'InterfaceAlias'; Variable = 'properties'; Property = 'InterfaceFilters'; Type = 'Array' }
                    @{ Name = 'Platform'; Variable = 'FirewallRule'; Type = 'Array' }
                    @{ Name = 'IcmpType'; Variable = 'properties'; Property = 'PortFilters'; Type = 'Array' }
                )

                $arrayIpTestCases = @(
                    @{ Name = 'LocalAddress'; Variable = 'properties'; Property = 'AddressFilters'; Type = 'ArrayIP' }
                    @{ Name = 'RemoteAddress'; Variable = 'properties'; Property = 'AddressFilters'; Type = 'ArrayIP' }
                )

                $remainingTestCases = @(
                    @{ Name = 'DisplayName'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'Group'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'DisplayGroup'; Variable = 'FirewallRule'; Type = '' }
                    @{ Name = 'Enabled'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'Action'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'Direction'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'Description'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'Protocol'; Variable = 'properties'; Property = 'PortFilters'; Type = 'String' }
                    @{ Name = 'Program'; Variable = 'properties'; Property = 'ApplicationFilters'; Type = 'String' }
                    @{ Name = 'Service'; Variable = 'properties'; Property = 'ServiceFilters'; Type = 'String' }
                    @{ Name = 'Authentication'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'String' }
                    @{ Name = 'Encryption'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'String' }
                    @{ Name = 'InterfaceType'; Variable = 'properties'; Property = 'InterfaceTypeFilters'; Type = 'String' }
                    @{ Name = 'LocalUser'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'String' }
                    @{ Name = 'Package'; Variable = 'properties'; Property = 'ApplicationFilters'; Type = 'String' }
                    @{ Name = 'RemoteMachine'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'String' }
                    @{ Name = 'RemoteUser'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'String' }
                    @{ Name = 'DynamicTransport'; Variable = 'properties'; Property = 'PortFilters'; Type = 'String' }
                    @{ Name = 'EdgeTraversalPolicy'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'LocalOnlyMapping'; Variable = 'FirewallRule'; Type = 'Boolean' }
                    @{ Name = 'LooseSourceMapping'; Variable = 'FirewallRule'; Type = 'Boolean' }
                    @{ Name = 'OverrideBlockRules'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'Boolean' }
                    @{ Name = 'Owner'; Variable = 'FirewallRule'; Type = 'String' }
                )
            }

            # Array
            It 'Should have set the parameter ''<Name>''' -ForEach $arrayTestCases {
                $parameterValue = $Current.$Name

                $parameterNew = (Get-Variable -Name configData).Value.AllNodes[0].$Name

                $parameterValue | Should -Be $parameterNew
            }

            # ArrayIP
            It "Should have set the '<Name>' array item correctly" -ForEach $arrayIpTestCases {
                $parameterValue = $Current.$Name

                $parameterNew = (Get-Variable -Name configData).Value.AllNodes[0].$Name

                for ([int] $entry = 0; $entry -lt $parameterNew.Count; $entry++)
                {
                    $parameterValue[$entry] | Should -Be (Convert-CIDRToSubnetMask -Address $parameterNew[$entry])
                }
            }

            # Other
            It 'Should have set the parameter ''<Name>''' -ForEach $remainingTestCases {
                $parameterValue = $Current.$Name

                $parameterNew = (Get-Variable -Name configData).Value.AllNodes[0].$Name

                $parameterValue | Should -Be $parameterNew
            }
        }

        Context 'The current firewall rule state' {
            BeforeDiscovery {
                $arrayTestCases = @(
                    @{ Name = 'Profile'; Variable = 'FirewallRule'; Type = 'Array'; Delimiter = ', ' }
                    @{ Name = 'RemotePort'; Variable = 'properties'; Property = 'PortFilters'; Type = 'Array' }
                    @{ Name = 'LocalPort'; Variable = 'properties'; Property = 'PortFilters'; Type = 'Array' }
                    @{ Name = 'InterfaceAlias'; Variable = 'properties'; Property = 'InterfaceFilters'; Type = 'Array' }
                    @{ Name = 'Platform'; Variable = 'FirewallRule'; Type = 'Array' }
                    @{ Name = 'IcmpType'; Variable = 'properties'; Property = 'PortFilters'; Type = 'Array' }
                )

                $arrayIpTestCases = @(
                    @{ Name = 'LocalAddress'; Variable = 'properties'; Property = 'AddressFilters'; Type = 'ArrayIP' }
                    @{ Name = 'RemoteAddress'; Variable = 'properties'; Property = 'AddressFilters'; Type = 'ArrayIP' }
                )

                $remainingTestCases = @(
                    @{ Name = 'DisplayName'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'Group'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'DisplayGroup'; Variable = 'FirewallRule'; Type = '' }
                    @{ Name = 'Enabled'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'Action'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'Direction'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'Description'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'Protocol'; Variable = 'properties'; Property = 'PortFilters'; Type = 'String' }
                    @{ Name = 'Program'; Variable = 'properties'; Property = 'ApplicationFilters'; Type = 'String' }
                    @{ Name = 'Service'; Variable = 'properties'; Property = 'ServiceFilters'; Type = 'String' }
                    @{ Name = 'Authentication'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'String' }
                    @{ Name = 'Encryption'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'String' }
                    @{ Name = 'InterfaceType'; Variable = 'properties'; Property = 'InterfaceTypeFilters'; Type = 'String' }
                    @{ Name = 'LocalUser'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'String' }
                    @{ Name = 'Package'; Variable = 'properties'; Property = 'ApplicationFilters'; Type = 'String' }
                    @{ Name = 'RemoteMachine'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'String' }
                    @{ Name = 'RemoteUser'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'String' }
                    @{ Name = 'DynamicTransport'; Variable = 'properties'; Property = 'PortFilters'; Type = 'String' }
                    @{ Name = 'EdgeTraversalPolicy'; Variable = 'FirewallRule'; Type = 'String' }
                    @{ Name = 'LocalOnlyMapping'; Variable = 'FirewallRule'; Type = 'Boolean' }
                    @{ Name = 'LooseSourceMapping'; Variable = 'FirewallRule'; Type = 'Boolean' }
                    @{ Name = 'OverrideBlockRules'; Variable = 'properties'; Property = 'SecurityFilters'; Type = 'Boolean' }
                    @{ Name = 'Owner'; Variable = 'FirewallRule'; Type = 'String' }
                )
            }

            BeforeAll {
                # Get the Rule details
                $firewallRule = Get-NetFireWallRule -Name $script:ruleNameEscaped

                $properties = @{
                    AddressFilters       = @(Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $FirewallRule)
                    ApplicationFilters   = @(Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $FirewallRule)
                    InterfaceFilters     = @(Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $FirewallRule)
                    InterfaceTypeFilters = @(Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $FirewallRule)
                    PortFilters          = @(Get-NetFirewallPortFilter -AssociatedNetFirewallRule $FirewallRule)
                    Profile              = @(Get-NetFirewallProfile -AssociatedNetFirewallRule $FirewallRule)
                    SecurityFilters      = @(Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $FirewallRule)
                    ServiceFilters       = @(Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $FirewallRule)
                }
            }

            # Array Test
            It "Should have set the '<Name>' property correctly" -ForEach $arrayTestCases {
                if ($Property)
                {
                    $parameterValue = (Get-Variable -Name $Variable).value.$Property.$Name
                }
                else
                {
                    $parameterValue = (Get-Variable -Name $Variable).value.$Name
                }

                $parameterNew = (Get-Variable -Name configData).Value.AllNodes[0].$Name

                if ($Delimiter)
                {
                    $parameterNew = $parameterNew -join $Delimiter
                }

                $parameterValue | Should -Be $parameterNew
            }

            # ArrayIP
            It "Should have set the '<Name>' property correctly" -ForEach $arrayIpTestCases {
                if ($Property)
                {
                    $parameterValue = (Get-Variable -Name $Variable).value.$Property.$Name
                }
                else
                {
                    $parameterValue = (Get-Variable -Name $Variable).value.$Name
                }

                $parameterNew = (Get-Variable -Name configData).Value.AllNodes[0].$Name

                for ([int] $entry = 0; $entry -lt $parameterNew.Count; $entry++)
                {
                    $parameterValue[$entry] | Should -Be (Convert-CIDRToSubnetMask -Address $parameterNew[$entry])
                }
            }

            # Other
            It "Should have set the '<Name>' property correctly" -ForEach $remainingTestCases {
                if ($Property)
                {
                    $parameterValue = (Get-Variable -Name $Variable).value.$Property.$Name
                }
                else
                {
                    $parameterValue = (Get-Variable -Name $Variable).value.$Name
                }

                $parameterNew = (Get-Variable -Name configData).Value.AllNodes[0].$Name

                $parameterValue | Should -Be $parameterNew
            }
        }
    }

    Describe "$($script:dscResourceName)_Remove_Integration" {
        BeforeAll {
            # Modify the config data object to pass to the Remove Rule Config
            $configData.AllNodes[0].Ensure = 'Absent'

            $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_remove.config.ps1"
            . $configFile
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Remove_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration `
                    -Path $TestDrive `
                    -ComputerName localhost `
                    -Wait `
                    -Verbose `
                    -Force `
                    -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { $script:current = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        Context 'DSC resource state' {
            It 'Should return the expected values' {
                $script:current.Ensure | Should -Be 'Absent'
            }
        }

        Context 'The current firewall rule state' {
            It 'Should have deleted the rule' {
                # Get the Rule details
                $firewallRule = Get-NetFireWallRule -Name $script:ruleNameEscaped -ErrorAction SilentlyContinue
                $firewallRule | Should -BeNullOrEmpty
            }
        }
    }
}
