$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_FirewallProfile'

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
    -BaseDirectory (Join-Path -Path $moduleRoot -ChildPath 'Source\DscResources\DSC_FirewallProfile') `
    -FileName 'DSC_FirewallProfile.data.psd1'

$parameterList = $resourceData.ParameterList | Where-Object -Property IntTest -eq $True

# Begin Testing
try
{
    Describe 'FirewallProfile Integration Tests' {
        # Backup the existing settings
        $script:firewallProfileName = 'Public'
        $script:currentFirewallProfile = Get-NetFirewallProfile -Name $script:firewallProfileName

        # Create a Loopback adapter to use to test disabling interface aliases
        New-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'
        $adapter = Get-NetAdapter -Name 'NetworkingDscLBA'
        $interfaceAlias = $adapter.InterfaceAlias

        # Set the Firewall Profile to known values
        Set-NetFirewallProfile `
            -Name $script:firewallProfileName `
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
                    Name                            = $script:firewallProfileName
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

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        Describe "$($script:dscResourceName)_Integration" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration `
                        -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            # Get the DNS Client Global Settings details
            $firewallProfileNew = Get-NetFirewallProfile -Name $script:firewallProfileName

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
    }
}
finally
{
    # Clean up
    Set-NetFirewallProfile `
        -Name $script:firewallProfileName `
        -Enabled $script:currentFirewallProfile.Enabled `
        -DefaultInboundAction $script:currentFirewallProfile.DefaultInboundAction `
        -DefaultOutboundAction $script:currentFirewallProfile.DefaultOutboundAction `
        -AllowInboundRules $script:currentFirewallProfile.AllowInboundRules `
        -AllowLocalFirewallRules $script:currentFirewallProfile.AllowLocalFirewallRules `
        -AllowLocalIPsecRules $script:currentFirewallProfile.AllowLocalIPsecRules `
        -AllowUserApps $script:currentFirewallProfile.AllowUserApps `
        -AllowUserPorts $script:currentFirewallProfile.AllowUserPorts `
        -AllowUnicastResponseToMulticast $script:currentFirewallProfile.AllowUnicastResponseToMulticast `
        -NotifyOnListen $script:currentFirewallProfile.NotifyOnListen `
        -EnableStealthModeForIPsec $script:currentFirewallProfile.EnableStealthModeForIPsec `
        -LogFileName $script:currentFirewallProfile.LogFileName `
        -LogMaxSizeKilobytes $script:currentFirewallProfile.LogMaxSizeKilobytes `
        -LogAllowed $script:currentFirewallProfile.LogAllowed `
        -LogBlocked $script:currentFirewallProfile.LogBlocked `
        -LogIgnored $script:currentFirewallProfile.LogIgnored `
        -DisabledInterfaceAliases $script:currentFirewallProfile.DisabledInterfaceAliases

    # Remove Loopback Adapter
    Remove-IntegrationLoopbackAdapter -AdapterName 'NetworkingDscLBA'

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
