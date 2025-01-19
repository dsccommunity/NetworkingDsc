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

Describe 'Public\Get-WinsClientServerStaticAddress' {
    BeforeAll {
        # Generate the adapter data to be used for Mocking
        $interfaceAlias = 'Adapter'
        $interfaceGuid = [Guid]::NewGuid().ToString()
        $script:nomatchAdapter = $null
        $script:matchAdapter = @{
            InterfaceGuid = $interfaceGuid
        }
        $parameters = @{
            InterfaceAlias = $interfaceAlias
        }
        $noIpStaticAddressString = ''
        $oneIpStaticAddressString = '8.8.8.8'
        $secondIpStaticAddressString = '4.4.4.4'
        $twoIpStaticAddressString = $oneIpStaticAddressString, $secondIpStaticAddressString

        InModuleScope -Parameters @{
            interfaceAlias              = $interfaceAlias
            parameters                  = $parameters
            oneIpStaticAddressString    = $oneIpStaticAddressString
            secondIpStaticAddressString = $secondIpStaticAddressString
        } -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:interfaceAlias = $interfaceAlias
            $script:parameters = $parameters
            $script:oneIpStaticAddressString = $oneIpStaticAddressString
            $script:secondIpStaticAddressString = $secondIpStaticAddressString
        }
    }

    Context 'When interface alias does not match adapter in system' {
        BeforeAll {
            Mock Get-NetAdapter -MockWith { $nomatchAdapter }
        }

        It 'Should throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.InterfaceAliasNotFoundError -f $interfaceAlias)

                { $script:result = Get-WinsClientServerStaticAddress @parameters } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When interface alias was found in system and WINS server is empty' {
        BeforeAll {
            Mock Get-NetAdapter -MockWith { $matchAdapter }
            Mock Get-ItemProperty -MockWith {
                @{
                    NameServer = $noIpStaticAddressString
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-WinsClientServerStaticAddress @parameters } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When interface alias was found in system and WINS server list contains one entry' {
        BeforeAll {
            Mock Get-NetAdapter -MockWith { $matchAdapter }
            Mock Get-ItemProperty -MockWith {
                @{
                    NameServerList = $oneIpStaticAddressString
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-WinsClientServerStaticAddress @parameters } | Should -Not -Throw
            }
        }

        It 'Should return expected address' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -Be $oneIpStaticAddressString
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When interface alias was found in system and WINS server list contains two entries' {
        BeforeAll {
            Mock Get-NetAdapter -MockWith { $matchAdapter }
            Mock Get-ItemProperty -MockWith {
                @{
                    NameServerList = $twoIpStaticAddressString
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-WinsClientServerStaticAddress @parameters } | Should -Not -Throw
            }
        }

        It 'Should return two expected addresses' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result[0] | Should -Be $oneIpStaticAddressString
                $script:result[1] | Should -Be $secondIpStaticAddressString
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope Context
        }
    }
}
