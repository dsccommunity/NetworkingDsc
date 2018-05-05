$script:DSCModuleName = 'NetworkingDsc'
$script:DSCResourceName = 'MSFT_HostsFile'

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\NetworkingDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        Describe 'MSFT_HostsFile' {
            BeforeEach {
                Mock -CommandName Add-Content
                Mock -CommandName Set-Content
            }

            Context 'A host entry does not exist, and should' {
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

            Context 'A host entry exists but has the wrong IP address' {
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

            Context 'A host entry exists with the correct IP address' {
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

            Context 'A host entry exists but it should not' {
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

            Context 'A commented out host entry exists' {
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

            Context 'A host entry does not it exist and should not' {
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

            Context 'A host entry exists and is correct, but it listed with multiple entries on one line' {
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

            Context 'A host entry exists and is not correct, but it listed with multiple entries on one line' {
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

            Context 'Invalid parameters will throw meaningful errors' {
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
                    { Set-TargetResource @testParams } | Should -Throw $LocalizedData.UnableToEnsureWithoutIP
                }
            }
        }
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
