$script:DSCModuleName   = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_FirewallProfile'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Integration Test Template Version: 1.1.1
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
    -TestType Integration
#endregion

# Configure Loopback Adapter
. (Join-Path -Path (Split-Path -Parent $Script:MyInvocation.MyCommand.Path) -ChildPath 'IntegrationHelper.ps1')

# Backup the existing settings
$firewallProfileName = 'Public'
$currentFirewallProfile = Get-NetFirewallProfile -Name $firewallProfileName

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

    # Create a Loopback adapter to use to test disabling interface aliases
    $adapterName = 'NetworkingDscLBA'
    New-IntegrationLoopbackAdapter -AdapterName $adapterName
    $adapter = Get-NetAdapter -Name $adapterName
    $interfaceAlias = $adapter.InterfaceAlias

    # Set the Firewall Profile to known values
    Set-NetFirewallProfile `
        -Name $firewallProfileName `
        -Enabled 'False' `
        -DefaultInboundAction 'Allow' `
        -DefaultOutboundAction 'Allow' `
        -AllowInboundRules 'True' `
        -AllowLocalFirewallRules 'True' `
        -AllowLocalIPsecRules 'True' `
        -AllowUserApps 'True' `
        -AllowUserPorts 'True' `
        -AllowUnicastResponseToMulticast 'True' `
        -NotifyOnListen 'True' `
        -EnableStealthModeForIPsec 'True' `
        -LogFileName '%systemroot%\system32\LogFiles\Firewall\pfirewalltest.log' `
        -LogMaxSizeKilobytes 16384 `
        -LogAllowed 'True' `
        -LogBlocked 'True' `
        -LogIgnored 'True' `
        -DisabledInterfaceAliases $interfaceAlias

    $configData = @{
        AllNodes = @(
            @{
                NodeName                        = 'localhost'
                Name                            = $firewallProfileName
                Enabled                         = 'False'
                DefaultInboundAction            = 'Block'
                DefaultOutboundAction           = 'Block'
                AllowInboundRules               = 'False'
                AllowLocalFirewallRules         = 'False'
                AllowLocalIPsecRules            = 'False'
                AllowUserApps                   = 'False'
                AllowUserPorts                  = 'False'
                AllowUnicastResponseToMulticast = 'False'
                NotifyOnListen                  = 'False'
                EnableStealthModeForIPsec       = 'False'
                LogFileName                     = '%systemroot%\system32\LogFiles\Firewall\pfirewall.log'
                LogMaxSizeKilobytes             = 32767
                LogAllowed                      = 'False'
                LogBlocked                      = 'False'
                LogIgnored                      = 'False'
                DisabledInterfaceAliases        = $interfaceAlias
            }
        )
    }

    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration `
                    -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }
        #endregion

        # Get the DNS Client Global Settings details
        $firewallProfileNew = Get-NetFirewallProfile -Name $firewallProfileName

        # Use the Parameters List to perform these tests
        foreach ($parameter in $parameterList)
        {
            $parameterName = $parameter.name
            $parameterCurrentValue = (Get-Variable -Name 'firewallProfileNew').value.$($parameter.name)
            $parameterNewValue = (Get-Variable -Name configData).Value.AllNodes[0].$($parameter.Name)

            It "Should have set the '$parameterName' to '$parameterNewValue'" {
                $parameterCurrentValue | Should -Be $parameterNewValue
            }
        }
    }
    #endregion
}
finally
{
    # Clean up
    Set-NetFirewallProfile `
        -Name $firewallProfileName `
        -Enabled $currentFirewallProfile.Enabled `
        -DefaultInboundAction $currentFirewallProfile.DefaultInboundAction `
        -DefaultOutboundAction $currentFirewallProfile.DefaultOutboundAction `
        -AllowInboundRules $currentFirewallProfile.AllowInboundRules `
        -AllowLocalFirewallRules $currentFirewallProfile.AllowLocalFirewallRules `
        -AllowLocalIPsecRules $currentFirewallProfile.AllowLocalIPsecRules `
        -AllowUserApps $currentFirewallProfile.AllowUserApps `
        -AllowUserPorts $currentFirewallProfile.AllowUserPorts `
        -AllowUnicastResponseToMulticast $currentFirewallProfile.AllowUnicastResponseToMulticast `
        -NotifyOnListen $currentFirewallProfile.NotifyOnListen `
        -EnableStealthModeForIPsec $currentFirewallProfile.EnableStealthModeForIPsec `
        -LogFileName $currentFirewallProfile.LogFileName `
        -LogMaxSizeKilobytes $currentFirewallProfile.LogMaxSizeKilobytes `
        -LogAllowed $currentFirewallProfile.LogAllowed `
        -LogBlocked $currentFirewallProfile.LogBlocked `
        -LogIgnored $currentFirewallProfile.LogIgnored `
        -DisabledInterfaceAliases $currentFirewallProfile.DisabledInterfaceAliases

    # Remove Loopback Adapter
    Remove-IntegrationLoopbackAdapter -AdapterName $adapterName

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
