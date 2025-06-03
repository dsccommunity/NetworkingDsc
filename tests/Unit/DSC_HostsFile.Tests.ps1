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
    $script:dscResourceName = 'DSC_HostsFile'

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

Describe 'DSC_HostsFile' {
    BeforeAll {
        Mock -CommandName Add-Content
        Mock -CommandName Set-Content
    }

    Context 'When a host entry does not exist, and should' {
        BeforeAll {
            Mock -CommandName Get-Content -MockWith {
                return @(
                    '# A mocked example of a host file - this line is a comment',
                    '',
                    '127.0.0.1       localhost',
                    '127.0.0.1  www.anotherexample.com',
                    ''
                )
            }
        }

        It 'Should return absent from the get method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }
        }

        It 'Should create the entry in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Add-Content -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a host entry exists but has the wrong IP address' {
        BeforeAll {
            Mock -CommandName Get-Content -MockWith {
                return @(
                    '# A mocked example of a host file - this line is a comment',
                    '',
                    '127.0.0.1       localhost',
                    '127.0.0.1  www.anotherexample.com',
                    '127.0.0.1         www.contoso.com',
                    ''
                )
            }
        }

        It 'Should return present from the get method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }
        }

        It 'Should update the entry in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Set-Content -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a host entry exists with the correct IP address' {
        BeforeAll {
            Mock -CommandName Get-Content -MockWith {
                return @(
                    '# A mocked example of a host file - this line is a comment',
                    '',
                    '127.0.0.1       localhost',
                    '127.0.0.1  www.anotherexample.com',
                    '192.168.0.156         www.contoso.com',
                    ''
                )
            }
        }

        It 'Should return present from the get method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                Test-TargetResource @testParams | Should -BeTrue
            }
        }
    }

    Context 'When a host entry exists but it should not' {
        BeforeAll {
            Mock -CommandName Get-Content -MockWith {
                return @(
                    '# A mocked example of a host file - this line is a comment',
                    '',
                    '127.0.0.1       localhost',
                    '127.0.0.1  www.anotherexample.com',
                    '127.0.0.1         www.contoso.com',
                    ''
                )
            }
        }

        It 'Should return present from the get method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName = 'www.contoso.com'
                    Ensure   = 'Absent'
                }

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName = 'www.contoso.com'
                    Ensure   = 'Absent'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }
        }

        It 'Should remove the entry in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName = 'www.contoso.com'
                    Ensure   = 'Absent'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Set-Content -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a commented out host entry exists' {
        BeforeAll {
            Mock -CommandName Get-Content -MockWith {
                return @(
                    '# A mocked example of a host file - this line is a comment',
                    '',
                    '127.0.0.1       localhost',
                    '127.0.0.1  www.anotherexample.com',
                    '# 127.0.0.1         www.contoso.com',
                    ''
                )
            }
        }

        It 'Should return present from the get method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '127.0.0.1'
                }

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '127.0.0.1'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }
        }

        It 'Should add the entry in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '127.0.0.1'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Add-Content -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a host entry does not it exist and should not' {
        BeforeAll {
            Mock -CommandName Get-Content -MockWith {
                return @(
                    '# A mocked example of a host file - this line is a comment',
                    '',
                    '127.0.0.1       localhost',
                    '127.0.0.1  www.anotherexample.com',
                    ''
                )
            }
        }

        It 'Should return absent from the get method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName = 'www.contoso.com'
                    Ensure   = 'Absent'
                }

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Absent'
            }

            Context 'When a host entry has leading spaces' {
                $testParams = @{
                    HostName  = 'www.anotherexample.com'
                    IPAddress = '127.0.0.1'
                    Verbose   = $true
                }

                Mock -CommandName Get-Content -MockWith {
                    return @(
                        '# A mocked example of a host file - this line is a comment',
                        '',
                        '127.0.0.1       localhost',
                        '# comment',
                        '  127.0.0.1  www.anotherexample.com',
                        ''
                    )
                }

                It 'Should return absent from the get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
                }
            }

            Context 'When a host entry exists and is not correct, but has a leading space' {
                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                    Verbose   = $true
                }

                Mock -CommandName Get-Content -MockWith {
                    return @(
                        '# A mocked example of a host file - this line is a comment',
                        '',
                        '127.0.0.1       localhost',
                        '127.0.0.1  www.anotherexample.com',
                        " 127.0.0.1  $($testParams.HostName)",
                        '127.0.0.5  anotherexample.com',
                        ''
                    )
                }

                It 'Should return present from the get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It 'Should update the entry in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Set-Content
                }
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName = 'www.contoso.com'
                    Ensure   = 'Absent'
                }

                Test-TargetResource @testParams | Should -BeTrue
            }
        }
    }

    Context 'When a host entry exists and is correct, but it listed with multiple entries on one line' {
        BeforeAll {
            Mock -CommandName Get-Content -MockWith {
                return @(
                    '# A mocked example of a host file - this line is a comment',
                    '',
                    '127.0.0.1       localhost',
                    '127.0.0.1  www.anotherexample.com',
                    '192.168.0.156        demo.contoso.com   www.contoso.com more.examples.com',
                    ''
                )
            }
        }

        It 'Should return present from the get method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                Test-TargetResource @testParams | Should -BeTrue
            }
        }
    }

    Context 'When a host entry exists and is not correct, but it listed with multiple entries on one line' {
        BeforeAll {
            Mock -CommandName Get-Content -MockWith {
                return @(
                    '# A mocked example of a host file - this line is a comment',
                    '',
                    '127.0.0.1       localhost',
                    '127.0.0.1  www.anotherexample.com',
                    '127.0.0.1         demo.contoso.com   www.contoso.com more.examples.com',
                    ''
                )
            }
        }

        It 'Should return present from the get method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }
        }

        It 'Should update the entry in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '192.168.0.156'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Set-Content -Exactly -Times 1 -Scope It
        }
    }

    Context 'When called with invalid parameters' {
        BeforeAll {
            Mock -CommandName Get-Content -MockWith {
                return @(
                    '# A mocked example of a host file - this line is a comment',
                    '',
                    '127.0.0.1       localhost',
                    '127.0.0.1  www.anotherexample.com',
                    ''
                )
            }
        }

        It 'Should throw an error when IP Address is not provide and ensure is present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    HostName = 'www.contoso.com'
                }

                $errorMessage = Get-InvalidArgumentRecord -Message $script:localizedData.UnableToEnsureWithoutIP -ArgumentName 'IPAddress'

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage $errorMessage
            }
        }
    }
}
