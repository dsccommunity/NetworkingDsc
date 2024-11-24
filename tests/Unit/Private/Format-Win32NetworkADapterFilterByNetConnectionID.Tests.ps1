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

Describe 'Format-Win32NetworkADapterFilterByNetConnectionID' {
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

                (Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias).Contains('%') -eq $true -and
                (Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias).Contains('*') -eq $false | Should -BeTrue
            }
        }

        It 'Should change the operator to ''LIKE''' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                (Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias) | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
            }
        }

        It 'Should look like a usable filter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
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

                (Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias) | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
            }
        }

        It 'Should look like a usable filter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias | Should -BeExactly 'NetConnectionID LIKE "Ether%"'
            }
        }
    }

    Context 'When interface alias has no wildcards' {
        It 'Should look like a usable filter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $interfaceAlias = 'Ethernet'

                Format-Win32NetworkADapterFilterByNetConnectionID -InterfaceAlias $interfaceAlias | Should -BeExactly 'NetConnectionID="Ethernet"'
            }
        }
    }
}
