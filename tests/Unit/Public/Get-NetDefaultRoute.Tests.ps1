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

Describe 'Get-NetDefaultRoute' -Tag 'Public' {
    Context 'When interface has a default gateway set' {
        BeforeAll {
            Mock -CommandName Get-NetRoute -MockWith {
                @{
                    NextHop           = '192.168.0.1'
                    DestinationPrefix = '0.0.0.0/0'
                    InterfaceAlias    = 'Ethernet'
                    InterfaceIndex    = 1
                    AddressFamily     = 'IPv4'
                }
            }
        }

        It 'Should return current default gateway' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $GetNetDefaultRouteParameters = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $result = Get-NetDefaultRoute @GetNetDefaultRouteParameters

                $result.NextHop | Should -Be '192.168.0.1'
            }
        }
    }

    Context 'When interface has no default gateway set' {
        BeforeAll {
            Mock -CommandName Get-NetRoute
        }

        It 'Should return no default gateway' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $GetNetDefaultRouteParameters = @{
                    InterfaceAlias = 'Ethernet'
                    AddressFamily  = 'IPv4'
                }

                $result = Get-NetDefaultRoute @GetNetDefaultRouteParameters

                $result | Should -BeNullOrEmpty
            }
        }
    }
}
