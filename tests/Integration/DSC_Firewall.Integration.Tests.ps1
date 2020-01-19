$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_Firewall'

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

# Load the parameter List from the data file
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$resourceData = Import-LocalizedData `
    -BaseDirectory (Join-Path -Path $moduleRoot -ChildPath 'Source\DscResources\DSC_DnsClientGlobalSetting') `
    -FileName 'DSC_DnsClientGlobalSetting.data.psd1'

$parameterList = $resourceData.ParameterList | Where-Object -Property IntTest -eq $True

# Begin Testing
try
{
    Describe 'Firewall Integration Tests' {
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

        Describe "$($script:dscResourceName)_Add_Integration" {
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
                # Use the Parameters List to perform these tests
                foreach ($parameter in $parameterList)
                {
                    $parameterName = $parameter.Name

                    if ($parameterName -ne 'Name')
                    {
                        $parameterValue = $Current.$($parameter.Name)

                        $parameterNew = (Get-Variable -Name configData).Value.AllNodes[0].$($parameter.Name)

                        if ($parameter.Type -eq 'Array' -and $parameter.Delimiter)
                        {
                            It "Should have set the '$parameterName' to '$parameterNew'" {
                                $parameterValue | Should -Be $parameterNew
                            }
                        }
                        elseif ($parameter.Type -eq 'ArrayIP')
                        {
                            for ([int] $entry = 0; $entry -lt $parameterNew.Count; $entry++)
                            {
                                It "Should have set the '$parameterName' arry item $entry to '$($parameterNew[$entry])'" {
                                    $parameterValue[$entry] | Should -Be (Convert-CIDRToSubhetMask -Address $parameterNew[$entry])
                                }
                            }
                        }
                        else
                        {
                            It "Should have set the '$parameterName' to '$parameterNew'" {
                                $parameterValue | Should -Be $parameterNew
                            }
                        }
                    }
                }
            }

            Context 'The current firewall rule state' {
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

                # Use the Parameters List to perform these tests
                foreach ($parameter in $parameterList)
                {
                    $parameterName = $parameter.Name

                    if ($parameterName -ne 'Name')
                    {
                        if ($parameter.Property)
                        {
                            $parameterValue = (Get-Variable -Name ($parameter.Variable)).value.$($parameter.Property).$($parameter.Name)
                        }
                        else
                        {
                            $parameterValue = (Get-Variable -Name ($parameter.Variable)).value.$($parameter.Name)
                        }

                        $parameterNew = (Get-Variable -Name configData).Value.AllNodes[0].$($parameter.Name)

                        if ($parameter.Type -eq 'Array' -and $parameter.Delimiter)
                        {
                            $parameterNew = $parameterNew -join $parameter.Delimiter

                            It "Should have set the '$parameterName' to '$parameterNew'" {
                                $parameterValue | Should -Be $parameterNew
                            }
                        }
                        elseif ($parameter.Type -eq 'ArrayIP')
                        {
                            for ([int] $entry = 0; $entry -lt $parameterNew.Count; $entry++)
                            {
                                It "Should have set the '$parameterName' arry item $entry to '$($parameterNew[$entry])'" {
                                    $parameterValue[$entry] | Should -Be (Convert-CIDRToSubhetMask -Address $parameterNew[$entry])
                                }
                            }
                        }
                        else
                        {
                            It "Should have set the '$parameterName' to '$parameterNew'" {
                                $parameterValue | Should -Be $parameterNew
                            }
                        }
                    }
                }
            }
        }

        # Modify the config data object to pass to the Remove Rule Config
        $configData.AllNodes[0].Ensure = 'Absent'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_remove.config.ps1"
        . $configFile

        Describe "$($script:dscResourceName)_Remove_Integration" {
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
}
finally
{
    if (Get-NetFirewallRule -Name $script:ruleNameEscaped -ErrorAction SilentlyContinue)
        {
        Remove-NetFirewallRule -Name $script:ruleNameEscaped
    }

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
