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

Describe 'Public\Get-DnsClientServerStaticAddress' {
    BeforeAll {
        # Generate the adapter data to be used for Mocking
        $interfaceAlias = 'Adapter'
        $interfaceGuid = [Guid]::NewGuid().ToString()
        $script:nomatchAdapter = $null
        $script:matchAdapter = [PSObject]@{
            InterfaceGuid = $interfaceGuid
        }
        $ipv4Parameters = @{
            InterfaceAlias = $interfaceAlias
            AddressFamily  = 'IPv4'
        }
        $ipv6Parameters = @{
            InterfaceAlias = $interfaceAlias
            AddressFamily  = 'IPv6'
        }
        $script:noIpv4StaticAddressString = ''
        $script:oneIpv4StaticAddressString = '8.8.8.8'
        $secondIpv4StaticAddressString = '4.4.4.4'
        $script:twoIpv4StaticAddressString = "$oneIpv4StaticAddressString,$secondIpv4StaticAddressString"
        $script:noIpv6StaticAddressString = ''
        $script:oneIpv6StaticAddressString = '::1'
        $secondIpv6StaticAddressString = '::2'
        $script:twoIpv6StaticAddressString = "$oneIpv6StaticAddressString,$secondIpv6StaticAddressString"

        InModuleScope -Parameters @{
            interfaceAlias                = $interfaceAlias
            ipv4Parameters                = $ipv4Parameters
            ipv6Parameters                = $ipv6Parameters
            oneIpv4StaticAddressString    = $oneIpv4StaticAddressString
            secondIpv4StaticAddressString = $secondIpv4StaticAddressString
            oneIpv6StaticAddressString    = $oneIpv6StaticAddressString
            secondIpv6StaticAddressString = $secondIpv6StaticAddressString
        } -ScriptBlock {
            Set-StrictMode -Version 1.0
            $script:interfaceAlias = $interfaceAlias
            $script:ipv4Parameters = $ipv4Parameters
            $script:ipv6Parameters = $ipv6Parameters
            $script:oneIpv4StaticAddressString = $oneIpv4StaticAddressString
            $script:secondIpv4StaticAddressString = $secondIpv4StaticAddressString
            $script:oneIpv6StaticAddressString = $oneIpv6StaticAddressString
            $script:secondIpv6StaticAddressString = $secondIpv6StaticAddressString

        }
    }

    Context 'Interface Alias does not match adapter in system' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:nomatchAdapter }
        }

        It 'Should throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.InterfaceAliasNotFoundError -f $interfaceAlias)

                { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Interface Alias was found in system but IPv4 NameServer is empty' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:matchAdapter }

            Mock -CommandName Get-ItemProperty -MockWith {
                [psobject] @{
                    NameServer = $script:noIpv4StaticAddressString
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters } | Should -Not -Throw
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

    Context 'Interface Alias was found in system but IPv4 NameServer property does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:matchAdapter }

            Mock -CommandName Get-ItemProperty -MockWith {
                [psobject] @{
                    Dummy = ''
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters } | Should -Not -Throw
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

    Context 'Interface Alias was found in system but IPv4 NameServer contains one DNS entry' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:matchAdapter }

            Mock -CommandName Get-ItemProperty -MockWith {
                [psobject] @{
                    NameServer = $script:oneIpv4StaticAddressString
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters } | Should -Not -Throw
            }
        }

        It 'Should return expected address' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -Be $oneIpv4StaticAddressString
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Interface Alias was found in system but IPv4 NameServer contains two DNS entries' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:matchAdapter }

            Mock -CommandName Get-ItemProperty -MockWith {
                [psobject] @{
                    NameServer = $script:twoIpv4StaticAddressString
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters } | Should -Not -Throw
            }
        }

        It 'Should return two expected addresses' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result[0] | Should -Be $oneIpv4StaticAddressString
                $script:result[1] | Should -Be $secondIpv4StaticAddressString
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Interface Alias was found in system but IPv6 NameServer is empty' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:matchAdapter }

            Mock -CommandName Get-ItemProperty -MockWith {
                [psobject] @{
                    NameServer = $script:noIpv6StaticAddressString
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters } | Should -Not -Throw
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

    Context 'Interface Alias was found in system but IPv6 NameServer property does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:matchAdapter }

            Mock -CommandName Get-ItemProperty -MockWith {
                [psobject] @{
                    Dummy = ''
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters } | Should -Not -Throw
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

    Context 'Interface Alias was found in system but IPv6 NameServer contains one DNS entry' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:matchAdapter }

            Mock -CommandName Get-ItemProperty -MockWith {
                [psobject] @{
                    NameServer = $script:oneIpv6StaticAddressString
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters } | Should -Not -Throw
            }
        }

        It 'Should return expected address' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result | Should -Be $script:oneIpv6StaticAddressString
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Interface Alias was found in system but IPv6 NameServer contains two DNS entries' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $script:matchAdapter }

            Mock -CommandName Get-ItemProperty -MockWith {
                [psobject] @{
                    NameServer = $script:twoIpv6StaticAddressString
                }
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters } | Should -Not -Throw
            }
        }

        It 'Should return two expected addresses' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result[0] | Should -Be $script:oneIpv6StaticAddressString
                $script:result[1] | Should -Be $script:secondIpv6StaticAddressString
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetAdapter -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope Context
        }
    }
}
