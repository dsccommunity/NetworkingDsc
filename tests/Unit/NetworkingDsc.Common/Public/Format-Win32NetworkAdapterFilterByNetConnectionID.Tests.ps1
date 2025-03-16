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
                & "$PSScriptRoot/../../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
    $script:subModuleName = 'NetworkingDsc.Common'

    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force
}

Describe 'NetworkingDsc.Common\Format-Win32NetworkAdapterFilterByNetConnectionID' {
    Context 'When interface alias has an ''*''' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:interfaceAlias = 'Ether*'
            }
        }

        It 'Should convert the ''*'' to a ''%''' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                (Format-Win32NetworkAdapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias).Contains('%') -eq $true -and
                (Format-Win32NetworkAdapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias).Contains('*') -eq $false | Should -BeTrue
            }
        }

        It 'Should change the operator to ''LIKE''' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                (Format-Win32NetworkAdapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias) | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
            }
        }

        It 'Should look like a usable filter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Format-Win32NetworkAdapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
            }
        }
    }

    Context 'When interface alias has a ''%''' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $interfaceAlias = 'Ether%'
            }
        }

        It 'Should change the operator to ''LIKE''' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                (Format-Win32NetworkAdapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias) | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
            }
        }

        It 'Should look like a usable filter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Format-Win32NetworkAdapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
            }
        }
    }

    Context 'When interface alias has no wildcards' {
        It 'Should look like a usable filter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $interfaceAlias = 'Ethernet'

                Format-Win32NetworkAdapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias | Should -BeExactly 'NetConnectionID="Ethernet"'
            }
        }
    }
}
