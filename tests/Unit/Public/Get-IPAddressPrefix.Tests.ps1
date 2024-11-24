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

Describe 'Public\Get-IPAddressPrefix' {
    Context 'IPv4 CIDR notation provided' {
        It 'Should return the provided IP and prefix as separate properties' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $IPaddress = Get-IPAddressPrefix -IPAddress '192.168.10.0/24'

                $IPaddress.IPaddress | Should -Be '192.168.10.0'
                $IPaddress.PrefixLength | Should -Be 24
            }
        }
    }

    Context 'IPv4 Class A address with no CIDR notation' {
        It 'Should return correct prefix when Class A address provided' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $IPaddress = Get-IPAddressPrefix -IPAddress '10.1.2.3'

                $IPaddress.IPaddress | Should -Be '10.1.2.3'
                $IPaddress.PrefixLength | Should -Be 8
            }
        }
    }

    Context 'IPv4 Class B address with no CIDR notation' {
        It 'Should return correct prefix when Class B address provided' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $IPaddress = Get-IPAddressPrefix -IPAddress '172.16.2.3'

                $IPaddress.IPaddress | Should -Be '172.16.2.3'
                $IPaddress.PrefixLength | Should -Be 16
            }
        }
    }

    Context 'IPv4 Class C address with no CIDR notation' {
        It 'Should return correct prefix when Class C address provided' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $IPaddress = Get-IPAddressPrefix -IPAddress '192.168.20.3'

                $IPaddress.IPaddress | Should -Be '192.168.20.3'
                $IPaddress.PrefixLength | Should -Be 24
            }
        }
    }

    Context 'IPv6 CIDR notation provided' {
        It 'Should return provided IP and prefix as separate properties' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $IPaddress = Get-IPAddressPrefix -IPAddress 'FF12::12::123/64' -AddressFamily IPv6

                $IPaddress.IPaddress | Should -Be 'FF12::12::123'
                $IPaddress.PrefixLength | Should -Be 64
            }
        }
    }

    Context 'IPv6 with no CIDR notation provided' {
        It 'Should return provided IP and correct IPv6 prefix' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $IPaddress = Get-IPAddressPrefix -IPAddress 'FF12::12::123' -AddressFamily IPv6

                $IPaddress.IPaddress | Should -Be 'FF12::12::123'
                $IPaddress.PrefixLength | Should -Be 64
            }
        }
    }
}
