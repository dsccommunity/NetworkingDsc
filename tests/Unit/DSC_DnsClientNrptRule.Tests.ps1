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
    $script:dscResourceName = 'DSC_DnsClientNrptRule'

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


Describe 'DSC_DnsClientNrptRule\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        # Create the Mock Objects that will be used for running tests
        $testNrptRule = [PSObject]@{
            Name        = 'Server'
            Namespace   = '.contoso.com'
            NameServers = ('192.168.1.1')
            Ensure      = 'Present'
        }
    
        $testNrptRuleKeys = [PSObject]@{
            Name        = $testNrptRule.Name
            Namespace   = $testNrptRule.Namespace
            NameServers = $testNrptRule.NameServers
            NextHop     = $testNrptRule.NextHop
        }
    
        $mockNrptRule = [PSObject]@{
            Name        = $testNrptRule.Name
            Namespace   = $testNrptRule.Namespace
            NameServers = $testNrptRule.NameServers
            Ensure      = $testNrptRule.Ensure
        
        }
    }
    Context 'NRPT Rule does not exist' {
        Mock -CommandName Get-DnsClientNrptRule

        It 'Should return absent NRPT Rule' {
            $result = Get-TargetResource @testNrptRuleKeys
            $result.Ensure | Should -Be 'Absent'
        }

        It 'Should call the expected mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
        }
    }

    Context 'NRPT Rule does exist' {
        Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }

        It 'Should return correct NRPT Rule' {
            $result = Get-TargetResource @testNrptRuleKeys
            $result.Ensure | Should -Be 'Present'
            $result.Namespace | Should -Be $testNrptRule.Namespace
            $result.NameServers | Should -Be $testNrptRule.NameServers
        }

        It 'Should call the expected mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
        }
    }
}

Describe 'DSC_DnsClientNrptRule\Set-TargetResource' -Tag 'Set' {
    Context 'NRPT Rule does not exist but should' {
        Mock -CommandName Get-DnsClientNrptRule
        Mock -CommandName Add-DnsClientNrptRule
        Mock -CommandName Set-DnsClientNrptRule
        Mock -CommandName Remove-DnsClientNrptRule

        It 'Should not throw error' {
            {
                $setTargetResourceParameters = $testNrptRule.Clone()
                Set-TargetResource @setTargetResourceParameters
            } | Should -Not -Throw
        }

        It 'Should call expected Mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
            Assert-MockCalled -CommandName Add-DnsClientNrptRule -Exactly -Times 1
            Assert-MockCalled -CommandName Set-DnsClientNrptRule -Exactly -Times 0
            Assert-MockCalled -CommandName Remove-DnsClientNrptRule -Exactly -Times 0
        }
    }

    Context 'NRPT Rule exists and should but has a different Namespace' {
        Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
        Mock -CommandName Add-DnsClientNrptRule
        Mock -CommandName Set-DnsClientNrptRule
        Mock -CommandName Remove-DnsClientNrptRule

        It 'Should not throw error' {
            {
                $setTargetResourceParameters = $testNrptRule.Clone()
                $setTargetResourceParameters.Namespace = '.fabrikam.com'
                Set-TargetResource @setTargetResourceParameters
            } | Should -Not -Throw
        }

        It 'Should call expected Mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
            Assert-MockCalled -CommandName Add-DnsClientNrptRule -Exactly -Times 0
            Assert-MockCalled -CommandName Set-DnsClientNrptRule -Exactly -Times 1
            Assert-MockCalled -CommandName Remove-DnsClientNrptRule -Exactly -Times 0
        }
    }

    Context 'NRPT Rule exists and should but has a different NameServers' {
        Mock -CommandName Get-DnsClientNrptRule-MockWith { $mockNrptRule }
        Mock -CommandName Add-DnsClientNrptRule
        Mock -CommandName Set-DnsClientNrptRule
        Mock -CommandName Remove-DnsClientNrptRule

        It 'Should not throw error' {
            {
                $setTargetResourceParameters = $testNrptRule.Clone()
                $setTargetResourceParameters.NameServers = ('192.168.0.1')
                Set-TargetResource @setTargetResourceParameters
            } | Should -Not -Throw
        }

        It 'Should call expected Mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
            Assert-MockCalled -CommandName Add-DnsClientNrptRule -Exactly -Times 0
            Assert-MockCalled -CommandName Set-DnsClientNrptRule -Exactly -Times 1
            Assert-MockCalled -CommandName Remove-DnsClientNrptRule -Exactly -Times 0
        }
    }


    Context 'NRPT Rule exists and but should not' {
        Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }
        Mock -CommandName Add-DnsClientNrptRule
        Mock -CommandName Set-DnsClientNrptRule
        Mock -CommandName Remove-DnsClientNrptRule `
            -ParameterFilter {
            ($Namespace -eq $testNrptRule.Namespace) -and `
            ($NameServers -eq $testNrptRule.NameServers)
        }

        It 'Should not throw error' {
            {
                $setTargetResourceParameters = $testNrptRule.Clone()
                $setTargetResourceParameters.Ensure = 'Absent'
                Set-TargetResource @setTargetResourceParameters
            } | Should -Not -Throw
        }

        It 'Should call expected mocks and parameters' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
            Assert-MockCalled -CommandName Add-DnsClientNrptRule -Exactly -Times 0
            Assert-MockCalled -CommandName Set-DnsClientNrptRule -Exactly -Times 0
            Assert-MockCalled -CommandName Remove-DnsClientNrptRule `
                -ParameterFilter {
                    ($Namespace -eq $testNrptRule.Namespace) -and `
                    ($NameServers -eq $testNrptRule.NameServers)
            } `
                -Exactly -Times 1
        }
    }

    Context 'NRPT Rule does not exist and should not' {
        Mock -CommandName Get-DnsClientNrptRule
        Mock -CommandName Add-DnsClientNrptRule
        Mock -CommandName Set-DnsClientNrptRule
        Mock -CommandName Remove-DnsClientNrptRule

        It 'Should not throw error' {
            {
                $setTargetResourceParameters = $testNrptRule.Clone()
                $setTargetResourceParameters.Ensure = 'Absent'
                Set-TargetResource @setTargetResourceParameters
            } | Should -Not -Throw
        }

        It 'Should call expected Mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
            Assert-MockCalled -CommandName Add-DnsClientNrptRule -Exactly -Times 0
            Assert-MockCalled -CommandName Set-DnsClientNrptRule -Exactly -Times 0
            Assert-MockCalled -CommandName Remove-DnsClientNrptRule -Exactly -Times 0
        }
    }
}

Describe 'DSC_DnsClientNrptRule\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        # Create the Mock Objects that will be used for running tests
        $testNrptRule = [PSObject]@{
            Name        = 'Server'
            Namespace   = '.contoso.com'
            NameServers = ('192.168.1.1')
            Ensure      = 'Present'
        }
    
        $testNrptRuleKeys = [PSObject]@{
            Name        = $testNrptRule.Name
            Namespace   = $testNrptRule.Namespace
            NameServers = $testNrptRule.NameServers
            NextHop     = $testNrptRule.NextHop
        }
    
        $mockNrptRule = [PSObject]@{
            Name        = $testNrptRule.Name
            Namespace   = $testNrptRule.Namespace
            NameServers = $testNrptRule.NameServers
            Ensure      = $testNrptRule.Ensure
        
        }
    }
    Context 'NRPT Rule does not exist but should' {
        Mock -CommandName Get-DnsClientNrptRule

        It 'Should return false' {
            $testTargetResourceParameters = $testNrptRule.Clone()
            Test-TargetResource @testTargetResourceParameters | Should -Be $False

        }

        It 'Should call expected Mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
        }
    }

    Context 'NRPT Rule exists and should but has a different Namespace' {
        Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }

        It 'Should return false' {
            {
                $testTargetResourceParameters = $testNrptRule.Clone()
                $testTargetResourceParameters.Namespace = '.fabrikam.com'
                Test-TargetResource @testTargetResourceParameters | Should -Be $False
            } | Should -Not -Throw
        }

        It 'Should call expected Mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
        }
    }

    Context 'NRPT Rule exists and should but has a different NameServers' {
        Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }

        It 'Should return false' {
            {
                $testTargetResourceParameters = $testNrptRule.Clone()
                $testTargetResourceParameters.NameServers = ('192.168.0.1')
                Test-TargetResource @testTargetResourceParameters | Should -Be $False
            } | Should -Not -Throw
        }

        It 'Should call expected Mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
        }
    }

    Context 'NRPT Rule exists and should and all parameters match' {
        Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }

        It 'Should return true' {
            {
                $testTargetResourceParameters = $testNrptRule.Clone()
                Test-TargetResource @testTargetResourceParameters | Should -Be $True
            } | Should -Not -Throw
        }

        It 'Should call expected Mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
        }
    }

    Context 'NRPT Rule exists but should not' {
        Mock -CommandName Get-DnsClientNrptRule -MockWith { $mockNrptRule }

        It 'Should return false' {
            {
                $testTargetResourceParameters = $testNrptRule.Clone()
                $testTargetResourceParameters.Ensure = 'Absent'
                Test-TargetResource @testTargetResourceParameters | Should -Be $False
            } | Should -Not -Throw
        }

        It 'Should call expected Mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
        }
    }

    Context 'NRPT Rule does not exist and should not' {
        Mock -CommandName Get-DnsClientNrptRule

        It 'Should return true' {
            {
                $testTargetResourceParameters = $testNrptRule.Clone()
                $testTargetResourceParameters.Ensure = 'Absent'
                Test-TargetResource @testTargetResourceParameters | Should -Be $True
            } | Should -Not -Throw
        }

        It 'Should call expected Mocks' {
            Assert-MockCalled -CommandName Get-DnsClientNrptRule -Exactly -Times 1
        }
    }
}
