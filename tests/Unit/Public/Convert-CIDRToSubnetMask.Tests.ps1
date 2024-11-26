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

Describe 'Convert-CIDRToSubnetMask' {
    Context 'Subnet Mask Notation Used "192.168.0.0/255.255.0.0"' {
        It 'Should Return "192.168.0.0/255.255.0.0"' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Convert-CIDRToSubnetMask -Address @('192.168.0.0/255.255.0.0') | Should -Be '192.168.0.0/255.255.0.0'
            }
        }
    }

    Context 'Subnet Mask Notation Used "192.168.0.10/255.255.0.0" resulting in source bits masked' {
        It 'Should Return "192.168.0.0/255.255.0.0" with source bits masked' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Convert-CIDRToSubnetMask -Address @('192.168.0.10/255.255.0.0') | Should -Be '192.168.0.0/255.255.0.0'
            }
        }
    }

    Context 'CIDR Notation Used "192.168.0.0/16"' {
        It 'Should Return "192.168.0.0/255.255.0.0"' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Convert-CIDRToSubnetMask -Address @('192.168.0.0/16') | Should -Be '192.168.0.0/255.255.0.0'
            }
        }
    }

    Context 'CIDR Notation Used "192.168.0.10/16" resulting in source bits masked' {
        It 'Should Return "192.168.0.0/255.255.0.0" with source bits masked' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Convert-CIDRToSubnetMask -Address @('192.168.0.10/16') | Should -Be '192.168.0.0/255.255.0.0'
            }
        }
    }

    Context 'Multiple Notations Used "192.168.0.0/16,10.0.0.24/255.255.255.0"' {
        It 'Should Return "192.168.0.0/255.255.0.0,10.0.0.0/255.255.255.0"' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $Result = Convert-CIDRToSubnetMask -Address @('192.168.0.0/16', '10.0.0.24/255.255.255.0')
                $Result[0] | Should -Be '192.168.0.0/255.255.0.0'
                $Result[1] | Should -Be '10.0.0.0/255.255.255.0'
            }
        }
    }

    Context 'Range Used "192.168.1.0-192.168.1.128"' {
        It 'Should Return "192.168.1.0-192.168.1.128"' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Convert-CIDRToSubnetMask -Address @('192.168.1.0-192.168.1.128') | Should -Be '192.168.1.0-192.168.1.128'
            }
        }
    }

    Context 'IPv6 Used "fe80::/112"' {
        It 'Should Return "fe80::/112"' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Convert-CIDRToSubnetMask -Address @('fe80::/112') | Should -Be 'fe80::/112'
            }
        }
    }
}
