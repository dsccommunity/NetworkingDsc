[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'DefaultGatewayAddress'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'NetworkingDsc'
    $script:dscResourceFriendlyName = 'DefaultGatewayAddress'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

$script:dscModuleName = 'NetworkingDsc'
$script:dscResourceName = 'DSC_HostsFile'

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
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

Describe 'HostsFile Integration Tests' {
    BeforeAll {
        Copy-Item -Path "${env:SystemRoot}\System32\Drivers\Etc\Hosts" -Destination "${env:Temp}\Hosts" -Force
    }

    AfterAll {
        # Restore unmodified hosts file
        Copy-Item "${env:Temp}\Hosts" "${env:SystemRoot}\System32\Drivers\Etc\Hosts" -Force
    }

    Describe "$($script:dscResourceName)_Integration - Add Single Line" {
        $configData = @{
            AllNodes = @(
                @{
                    NodeName  = 'localhost'
                    HostName  = 'Host01'
                    IPAddress = '192.168.0.1'
                    Ensure    = 'Present'
                }
            )
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration `
                    -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $result = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }
            $result.Ensure                 | Should -Be $configData.AllNodes[0].Ensure
            $result.HostName               | Should -Be $configData.AllNodes[0].HostName
            $result.IPAddress              | Should -Be $configData.AllNodes[0].IPAddress
        }
    }

    Describe "$($script:dscResourceName)_Integration - Add Multiple Line" {
        BeforeAll {
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName  = 'localhost'
                        HostName  = 'Host01'
                        IPAddress = '192.168.0.2'
                        Ensure    = 'Present'
                    }
                )
            }
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration `
                    -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $result = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }
            $result.Ensure                 | Should -Be $configData.AllNodes[0].Ensure
            $result.HostName               | Should -Be $configData.AllNodes[0].HostName
            $result.IPAddress              | Should -Be $configData.AllNodes[0].IPAddress
        }
    }

    Describe "$($script:dscResourceName)_Integration - Remove Single Line" {
        BeforeAll {
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName  = 'localhost'
                        HostName  = 'Host01'
                        IPAddress = '192.168.0.1'
                        Ensure    = 'Absent'
                    }
                )
            }
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration `
                    -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $result = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }
            $result.Ensure                 | Should -Be $configData.AllNodes[0].Ensure
            $result.HostName               | Should -Be $configData.AllNodes[0].HostName
            $result.IPAddress              | Should -BeNullOrEmpty
        }
    }
}
