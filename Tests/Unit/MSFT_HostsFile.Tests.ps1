$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_HostsFile'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        Describe 'MSFT_HostsFile' {
            BeforeEach {
                Mock -CommandName Add-Content
                Mock -CommandName Set-Content
            }

            Context 'When a host entry does not exist, and should' {
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
                        ''
                    )
                }

                It 'Should return absent from the get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Absent'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It 'Should create the entry in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Add-Content
                }
            }

            Context 'When a host entry exists but has the wrong IP address' {
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
                        "127.0.0.1         $($testParams.HostName)",
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

            Context 'When a host entry exists with the correct IP address' {
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
                        "$($testParams.IPAddress)         $($testParams.HostName)",
                        ''
                    )
                }

                It 'Should return present from the get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context 'When a host entry exists but it should not' {
                $testParams = @{
                    HostName = 'www.contoso.com'
                    Ensure   = 'Absent'
                    Verbose  = $true
                }

                Mock -CommandName Get-Content -MockWith {
                    return @(
                        '# A mocked example of a host file - this line is a comment',
                        '',
                        '127.0.0.1       localhost',
                        '127.0.0.1  www.anotherexample.com',
                        "127.0.0.1         $($testParams.HostName)",
                        ''
                    )
                }

                It 'Should return present from the get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It 'Should remove the entry in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Set-Content
                }
            }

            Context 'When a commented out host entry exists' {
                $testParams = @{
                    HostName  = 'www.contoso.com'
                    IPAddress = '127.0.0.1'
                    Verbose   = $true
                }

                Mock -CommandName Get-Content -MockWith {
                    return @(
                        '# A mocked example of a host file - this line is a comment',
                        '',
                        '127.0.0.1       localhost',
                        '127.0.0.1  www.anotherexample.com',
                        "# 127.0.0.1         $($testParams.HostName)",
                        ''
                    )
                }

                It 'Should return present from the get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Absent'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It 'Should add the entry in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Add-Content
                }
            }

            Context 'When a host entry does not it exist and should not' {
                $testParams = @{
                    HostName = 'www.contoso.com'
                    Ensure   = 'Absent'
                    Verbose  = $true
                }

                Mock -CommandName Get-Content -MockWith {
                    return @(
                        '# A mocked example of a host file - this line is a comment',
                        '',
                        '127.0.0.1       localhost',
                        '127.0.0.1  www.anotherexample.com',
                        ''
                    )
                }

                It 'Should return absent from the get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Absent'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context 'When a host entry exists and is correct, but it listed with multiple entries on one line' {
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
                        "$($testParams.IPAddress)         demo.contoso.com   $($testParams.HostName) more.examples.com",
                        ''
                    )
                }

                It 'Should return present from the get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context 'When a host entry exists and is not correct, but it listed with multiple entries on one line' {
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
                        "127.0.0.1         demo.contoso.com   $($testParams.HostName) more.examples.com",
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

            Context 'When called with invalid parameters' {
                $testParams = @{
                    HostName = 'www.contoso.com'
                    Verbose  = $true
                }

                Mock -CommandName Get-Content -MockWith {
                    return @(
                        '# A mocked example of a host file - this line is a comment',
                        '',
                        '127.0.0.1       localhost',
                        '127.0.0.1  www.anotherexample.com',
                        ''
                    )
                }

                It 'Should throw an error when IP Address is not provide and ensure is present' {
                    { Set-TargetResource @testParams } | Should -Throw $script:localizedData.UnableToEnsureWithoutIP
                }
            }
        }
    } #end InModuleScope $DSCResourceName
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
