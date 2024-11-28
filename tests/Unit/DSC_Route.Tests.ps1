# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
}

BeforeAll {
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceName = 'DSC_Route'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_Route\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $mockNetAdapter = @{
            Name = 'Ethernet'
        }

        $mockRoute = @{
            InterfaceAlias    = 'Ethernet'
            AddressFamily     = 'IPv4'
            DestinationPrefix = '10.0.0.1/8'
            NextHop           = '10.0.0.2'
            Ensure            = 'Present'
            RouteMetric       = 200
            Publish           = 'Age'
            PreferredLifetime = ([Timespan]::FromSeconds(50000))
        }

        $testRoute = @{
            InterfaceAlias    = 'Ethernet'
            AddressFamily     = 'IPv4'
            DestinationPrefix = '10.0.0.1/8'
            NextHop           = '10.0.0.2'
            Ensure            = 'Present'
            RouteMetric       = 200
            Publish           = 'Age'
            PreferredLifetime = 50000
        }

        InModuleScope -ScriptBlock {
            $script:testRoute = @{
                InterfaceAlias    = 'Ethernet'
                AddressFamily     = 'IPv4'
                DestinationPrefix = '10.0.0.1/8'
                NextHop           = '10.0.0.2'
                Ensure            = 'Present'
                RouteMetric       = 200
                Publish           = 'Age'
                PreferredLifetime = 50000
            }
        }
    }
    Context 'Route does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetRoute
        }

        It 'Should return absent Route' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testRouteKeys = @{
                    InterfaceAlias    = 'Ethernet'
                    AddressFamily     = 'IPv4'
                    DestinationPrefix = '10.0.0.1/8'
                    NextHop           = '10.0.0.2'
                }

                $result = Get-TargetResource @testRouteKeys
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Route does exist' {
        BeforeAll {
            Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
        }

        It 'Should return correct Route' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testRouteKeys = @{
                    InterfaceAlias    = 'Ethernet'
                    AddressFamily     = 'IPv4'
                    DestinationPrefix = '10.0.0.1/8'
                    NextHop           = '10.0.0.2'
                }

                $result = Get-TargetResource @testRouteKeys
                $result.Ensure | Should -Be 'Present'
                $result.InterfaceAlias | Should -Be $testRoute.InterfaceAlias
                $result.AddressFamily | Should -Be $testRoute.AddressFamily
                $result.DestinationPrefix | Should -Be $testRoute.DestinationPrefix
                $result.NextHop | Should -Be $testRoute.NextHop
                $result.RouteMetric | Should -Be $testRoute.RouteMetric
                $result.Publish | Should -Be $testRoute.Publish
                $result.PreferredLifetime | Should -Be $testRoute.PreferredLifetime
            }
        }

        It 'Should call the expected mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_Route\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $mockNetAdapter = @{
            Name = 'Ethernet'
        }

        $mockRoute = @{
            InterfaceAlias    = 'Ethernet'
            AddressFamily     = 'IPv4'
            DestinationPrefix = '10.0.0.1/8'
            NextHop           = '10.0.0.2'
            Ensure            = 'Present'
            RouteMetric       = 200
            Publish           = 'Age'
            PreferredLifetime = ([Timespan]::FromSeconds(50000))
        }

        $testRoute = @{
            InterfaceAlias    = 'Ethernet'
            AddressFamily     = 'IPv4'
            DestinationPrefix = '10.0.0.1/8'
            NextHop           = '10.0.0.2'
            Ensure            = 'Present'
            RouteMetric       = 200
            Publish           = 'Age'
            PreferredLifetime = 50000
        }

        InModuleScope -ScriptBlock {
            $script:testRoute = @{
                InterfaceAlias    = 'Ethernet'
                AddressFamily     = 'IPv4'
                DestinationPrefix = '10.0.0.1/8'
                NextHop           = '10.0.0.2'
                Ensure            = 'Present'
                RouteMetric       = 200
                Publish           = 'Age'
                PreferredLifetime = 50000
            }
        }
    }
    Context 'Route does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-NetRoute
            Mock -CommandName New-NetRoute
            Mock -CommandName Set-NetRoute
            Mock -CommandName Remove-NetRoute
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $testRoute.Clone()

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-NetRoute -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Route exists and should but has a different RouteMetric' {
        BeforeAll {
            Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
            Mock -CommandName New-NetRoute
            Mock -CommandName Set-NetRoute
            Mock -CommandName Remove-NetRoute
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $script:testRoute.Clone()
                $setTargetResourceParameters.RouteMetric = $setTargetResourceParameters.RouteMetric + 10

                $result = Set-TargetResource @setTargetResourceParameters

                { $result } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetRoute -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Route exists and should but has a different Publish' {
        BeforeAll {
            Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
            Mock -CommandName New-NetRoute
            Mock -CommandName Set-NetRoute
            Mock -CommandName Remove-NetRoute
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $testRoute.Clone()
                $setTargetResourceParameters.Publish = 'No'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetRoute -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Route exists and should but has a different PreferredLifetime' {
        BeforeAll {
            Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
            Mock -CommandName New-NetRoute
            Mock -CommandName Set-NetRoute
            Mock -CommandName Remove-NetRoute
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $testRoute.Clone()
                $setTargetResourceParameters.PreferredLifetime = $testRoute.PreferredLifetime + 1000

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetRoute -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 0 -Scope Context
        }
    }

    Context 'Route exists and but should not' {
        BeforeAll {
            Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
            Mock -CommandName New-NetRoute
            Mock -CommandName Set-NetRoute
            Mock -CommandName Remove-NetRoute `
                -ParameterFilter {
                    ($InterfaceAlias -eq $testRoute.InterfaceAlias) -and `
                ($AddressFamily -eq $testRoute.AddressFamily) -and `
                ($DestinationPrefix -eq $testRoute.DestinationPrefix) -and `
                ($NextHop -eq $testRoute.NextHop) -and `
                ($RouteMetric -eq $testRoute.RouteMetric)
            }
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $testRoute.Clone()
                $setTargetResourceParameters.Ensure = 'Absent'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks and parameters' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetRoute -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetRoute -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-NetRoute `
                -ParameterFilter {
                $InterfaceAlias -eq $testRoute.InterfaceAlias -and `
                    $AddressFamily -eq $testRoute.AddressFamily -and `
                    $DestinationPrefix -eq $testRoute.DestinationPrefix -and `
                    $NextHop -eq $testRoute.NextHop -and `
                    $RouteMetric -eq $testRoute.RouteMetric
            } -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Route does not exist and should not' {
        BeforeAll {
            Mock -CommandName Get-NetRoute
            Mock -CommandName New-NetRoute
            Mock -CommandName Set-NetRoute
            Mock -CommandName Remove-NetRoute
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $testRoute.Clone()
                $setTargetResourceParameters.Ensure = 'Absent'

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-NetRoute -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-NetRoute -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Remove-NetRoute -Exactly -Times 0 -Scope Context
        }
    }
}

Describe 'DSC_Route\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $mockNetAdapter = @{
            Name = 'Ethernet'
        }

        $mockRoute = @{
            InterfaceAlias    = 'Ethernet'
            AddressFamily     = 'IPv4'
            DestinationPrefix = '10.0.0.1/8'
            NextHop           = '10.0.0.2'
            Ensure            = 'Present'
            RouteMetric       = 200
            Publish           = 'Age'
            PreferredLifetime = ([Timespan]::FromSeconds(50000))
        }

        $testRoute = @{
            InterfaceAlias    = 'Ethernet'
            AddressFamily     = 'IPv4'
            DestinationPrefix = '10.0.0.1/8'
            NextHop           = '10.0.0.2'
            Ensure            = 'Present'
            RouteMetric       = 200
            Publish           = 'Age'
            PreferredLifetime = 50000
        }

        InModuleScope -ScriptBlock {
            $script:testRoute = @{
                InterfaceAlias    = 'Ethernet'
                AddressFamily     = 'IPv4'
                DestinationPrefix = '10.0.0.1/8'
                NextHop           = '10.0.0.2'
                Ensure            = 'Present'
                RouteMetric       = 200
                Publish           = 'Age'
                PreferredLifetime = 50000
            }
        }
    }
    Context 'Route does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            Mock -CommandName Get-NetRoute
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testRoute.Clone()
                Test-TargetResource @testTargetResourceParameters | Should -BeFalse
            }

        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Route exists and should but has a different RouteMetric' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testRoute.Clone()
                $testTargetResourceParameters.RouteMetric = $testTargetResourceParameters.RouteMetric + 5

                $result = Test-TargetResource @testTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Route exists and should but has a different Publish' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testRoute.Clone()
                $testTargetResourceParameters.Publish = 'Yes'

                $result = Test-TargetResource @testTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Route exists and should but has a different PreferredLifetime' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testRoute.Clone()
                $testTargetResourceParameters.PreferredLifetime = $testTargetResourceParameters.PreferredLifetime + 5000

                $result = Test-TargetResource @testTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Route exists and should and all parameters match' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testRoute.Clone()

                $result = Test-TargetResource @testTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Route exists but should not' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            Mock -CommandName Get-NetRoute -MockWith { $mockRoute }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testRoute.Clone()
                $testTargetResourceParameters.Ensure = 'Absent'

                $result = Test-TargetResource @testTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
        }
    }

    Context 'Route does not exist and should not' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
            Mock -CommandName Get-NetRoute
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $testRoute.Clone()
                $testTargetResourceParameters.Ensure = 'Absent'

                $result = Test-TargetResource @testTargetResourceParameters

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-NetRoute -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'DSC_Route\Assert-ResourceProperty' {
    BeforeAll {
        $mockNetAdapter = @{
            Name = 'Ethernet'
        }

        InModuleScope -ScriptBlock {
            $script:testRoute = @{
                InterfaceAlias    = 'Ethernet'
                AddressFamily     = 'IPv4'
                DestinationPrefix = '10.0.0.1/8'
                NextHop           = '10.0.0.2'
                Ensure            = 'Present'
                RouteMetric       = 200
                Publish           = 'Age'
                PreferredLifetime = 50000
            }
        }
    }
    Context 'Invoking with bad interface alias' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter
        }

        It 'Should throw an InterfaceNotAvailable error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.InterfaceNotAvailableError -f $testRoute.InterfaceAlias) `
                    -ArgumentName 'InterfaceAlias'

                { Assert-ResourceProperty @testRoute } | Should -Throw $errorRecord
            }
        }
    }

    Context 'Invoking with bad IPv4 DestinationPrefix address' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $Splat = $testRoute.Clone()
                $Splat.DestinationPrefix = '10.0.300.0/24'
                $Splat.NextHop = '10.0.1.0'
                $Splat.AddressFamily = 'IPv4'

                { Assert-ResourceProperty @Splat } | Should -Throw
            }
        }
    }

    Context 'Invoking with bad IPv6 DestinationPrefix address' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $Splat = $testRoute.Clone()
                $Splat.DestinationPrefix = 'fe8x::/64'
                $Splat.NextHop = 'fe90::'
                $Splat.AddressFamily = 'IPv6'

                { Assert-ResourceProperty @Splat } | Should -Throw
            }
        }
    }

    Context 'Invoking with IPv4 DestinationPrefix mismatch' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $Splat = $testRoute.Clone()
                $Splat.DestinationPrefix = 'fe80::/64'
                $Splat.NextHop = '10.0.1.0'
                $Splat.AddressFamily = 'IPv4'

                { Assert-ResourceProperty @Splat } | Should -Throw
            }
        }
    }

    Context 'Invoking with IPv6 DestinationPrefix mismatch' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $Splat = $testRoute.Clone()
                $Splat.DestinationPrefix = '10.0.0.0/24'
                $Splat.NextHop = 'fe81::'
                $Splat.AddressFamily = 'IPv6'

                { Assert-ResourceProperty @Splat } | Should -Throw
            }
        }
    }

    Context 'Invoking with bad IPv4 NextHop address' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $Splat = $testRoute.Clone()
                $Splat.DestinationPrefix = '10.0.0.0/24'
                $Splat.NextHop = '10.0.300.0'
                $Splat.AddressFamily = 'IPv4'

                { Assert-ResourceProperty @Splat } | Should -Throw
            }
        }
    }

    Context 'Invoking with bad IPv6 NextHop address' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $Splat = $testRoute.Clone()
                $Splat.DestinationPrefix = 'fe80::/64'
                $Splat.NextHop = 'fe9x::'
                $Splat.AddressFamily = 'IPv6'

                { Assert-ResourceProperty @Splat } | Should -Throw
            }
        }
    }

    Context 'Invoking with IPv4 NextHop mismatch' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $Splat = $testRoute.Clone()
                $Splat.DestinationPrefix = '10.0.0.0/24'
                $Splat.NextHop = 'fe90::'
                $Splat.AddressFamily = 'IPv4'

                { Assert-ResourceProperty @Splat } | Should -Throw
            }
        }
    }

    Context 'Invoking with IPv6 NextHop mismatch' {
        BeforeAll {
            Mock -CommandName Get-NetAdapter -MockWith { $mockNetAdapter }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $Splat = $testRoute.Clone()
                $Splat.DestinationPrefix = 'fe80::/64'
                $Splat.NextHop = '10.0.1.0'
                $Splat.AddressFamily = 'IPv6'

                { Assert-ResourceProperty @Splat } | Should -Throw
            }
        }
    }
}
