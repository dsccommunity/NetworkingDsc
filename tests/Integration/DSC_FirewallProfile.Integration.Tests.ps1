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
    $script:dscResourceFriendlyName = 'FirewallProfile'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceFriendlyName = 'FirewallProfile'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe 'FirewallProfile Integration Tests' {
    BeforeAll {
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
    }

    AfterAll {
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
    }

    Describe "$($script:dscResourceName)_Integration" {
        AfterEach {
            Wait-ForIdleLcm
        }

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

        Context 'When checking the parameters' {
            BeforeDiscovery {
                $testCases = @(
                    'AllowInboundRules',
                    'AllowLocalFirewallRules',
                    'AllowLocalIPsecRules',
                    'AllowUnicastResponseToMulticast',
                    'AllowUserApps',
                    'AllowUserPorts',
                    'DefaultInboundAction',
                    'DefaultOutboundAction',
                    'DisabledInterfaceAliases',
                    'Enabled',
                    'EnableStealthModeForIPsec',
                    'LogAllowed',
                    'LogBlocked',
                    'LogFileName',
                    'LogIgnored',
                    'LogMaxSizeKilobytes',
                    'NotifyOnListen'
                )
            }

            BeforeAll {
                # Get the DNS Client Global Settings details
                $firewallProfileNew = Get-NetFirewallProfile -Name $script:firewallProfileName
            }

            It 'Should have set parameter <_> correctly' -ForEach $testCases {
                $parameterCurrentValue = (Get-Variable -Name 'firewallProfileNew').value.$_
                $parameterNewValue = (Get-Variable -Name configData).Value.AllNodes[0].$_

                $parameterCurrentValue | Should -Be $parameterNewValue
            }
        }
    }
}
