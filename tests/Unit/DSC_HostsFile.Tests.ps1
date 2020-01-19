$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_HostsFile'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        Describe 'DSC_HostsFile' {
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
    Invoke-TestCleanup
}
