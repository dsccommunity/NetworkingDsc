$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_IPAddressOption'

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
        Describe 'DSC_IPAddressOption\Get-TargetResource' -Tag 'Get' {
            Context 'Invoked with an existing IP address' {
                Mock -CommandName Get-NetIPAddress -MockWith {
                    [PSCustomObject] @{
                        IPAddress      = '192.168.0.1'
                        InterfaceAlias = 'Ethernet'
                        InterfaceIndex = 1
                        PrefixLength   = [System.Byte] 24
                        AddressFamily  = 'IPv4'
                        SkipAsSource   = $true
                    }
                }

                It 'Should return existing IP options' {
                    $getTargetResourceParameters = @{
                        IPAddress = '192.168.0.1'
                    }
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.IPAddress | Should -Be $getTargetResourceParameters.IPAddress
                    $result.SkipAsSource | Should -Be $true
                }
            }
        }

        Describe 'DSC_IPAddressOption\Set-TargetResource' -Tag 'Set' {
            Context 'Invoked with an existing IP address, SkipAsSource = $false' {
                BeforeEach {
                    Mock -CommandName Get-NetIPAddress -MockWith {
                        [PSCustomObject] @{
                            IPAddress      = '192.168.0.1'
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 24
                            AddressFamily  = 'IPv4'
                            SkipAsSource   = $false
                        }
                    }

                    Mock -CommandName Set-NetIPAddress
                }

                Context 'Invoked with valid IP address' {
                    It 'Should return $null' {
                        $setTargetResourceParameters = @{
                            IPAddress    = '192.168.0.1'
                            SkipAsSource = $true
                        }
                        { $result = Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $result | Should -BeNullOrEmpty
                    }

                    It 'Should call all the mock' {
                        Assert-MockCalled -CommandName Set-NetIPAddress -Exactly -Times 1
                    }
                }
            }
        }

        Describe 'DSC_IPAddressOption\Test-TargetResource' -Tag 'Test' {
            Context 'Invoked with an existing IP address, SkipAsSource = $true' {
                BeforeEach {
                    Mock -CommandName Get-NetIPAddress -MockWith {
                        [PSCustomObject] @{
                            IPAddress      = '192.168.0.1'
                            InterfaceAlias = 'Ethernet'
                            InterfaceIndex = 1
                            PrefixLength   = [System.Byte] 24
                            AddressFamily  = 'IPv4'
                            SkipAsSource   = $true
                        }
                    }
                }

                Context 'Invoked with valid IP address' {
                    It 'Should return $true' {
                        $testGetResourceParameters = @{
                            IPAddress    = '192.168.0.1'
                            SkipAsSource = $true
                        }

                        $result = Test-TargetResource @testGetResourceParameters
                        $result | Should -Be $true
                    }
                }
            }
        }
    } #end InModuleScope $DSCResourceName
}
finally
{
    Invoke-TestCleanup
}
