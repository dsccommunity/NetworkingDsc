$script:DSCModuleName      = 'xNetworking'
$script:DSCResourceName    = 'MSFT_xFirewall'

#region HEADER
# Integration Test Template Version: 1.1.0
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
    -TestType Integration
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    # Import the Common Networking functions
    Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'Modules\NetworkingDsc.Common\NetworkingDsc.Common.psm1') -Force

    # Load the ParameterList from the data file.
    $resourceDataPath = Join-Path `
        -Path $script:moduleRoot `
        -ChildPath (Join-Path -Path 'DSCResources' -ChildPath $script:DSCResourceName)
    $resourceData = Import-LocalizedData `
        -BaseDirectory $resourceDataPath `
        -FileName "$($script:DSCResourceName).data.psd1"
    $parameterList = $resourceData.ParameterList

    # Create a config data object to pass to the DSC Configs
    $ruleName = [Guid]::NewGuid()
    $configData = @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                RuleName = $ruleName
            }
        )
    }

    #region Integration Tests for Add Firewall Rule
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_add.config.ps1"
    . $configFile

    Describe "$($script:DSCResourceName)_Add_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Add_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration `
                    -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        # Get the Rule details
        $firewallRule = Get-NetFireWallRule -Name $ruleName
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
            if ($parameterName -ne 'Name') {
                $parameterSource = (Invoke-Expression -Command "`$($($parameter.source))")
                $parameterNew = (Invoke-Expression -Command "`$rule.$($parameter.name)")
                if ($parameter.type -eq 'Array' -and $parameter.Delimiter) {
                    $parameterNew = $parameterNew -join $parameter.Delimiter
                    It "Should have set the '$parameterName' to '$parameterNew'" {
                        $parameterSource | Should Be $parameterNew
                    }
                }
                elseif ($parameter.type -eq 'ArrayIP')
                {
                    for ([int] $entry = 0; $entry -lt $parameterNew.Count; $entry++)
                    {
                        It "Should have set the '$parameterName' arry item $entry to '$($parameterNew[$entry])'" {
                            $parameterSource[$entry] | Should Be (Convert-CIDRToSubhetMask -Address $parameterNew[$entry])
                        }
                    }
                }
                else
                {
                    It "Should have set the '$parameterName' to '$parameterNew'" {
                        $parameterSource | Should Be $parameterNew
                    }
                }
            }
        }

    }
    #endregion

    #region Integration Tests for Remove Firewall Rule
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_remove.config.ps1"
    . $configFile

    Describe "$($script:DSCResourceName)_Remove_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Remove_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration `
                    -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'The rule should not exist' {
            # Get the Rule details
            $firewallRule = Get-NetFireWallRule -Name $ruleName -ErrorAction SilentlyContinue
            $firewallRule | Should BeNullOrEmpty
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    if (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue) {
        Remove-NetFirewallRule -Name $ruleName
    }

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
