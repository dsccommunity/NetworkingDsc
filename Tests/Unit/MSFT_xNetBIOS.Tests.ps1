$Global:DSCModuleName   = 'xNetworking'
$Global:DSCResourceName = 'MSFT_xNetBIOS'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $Global:DSCResourceName {

        $MockNetadapterSettingsDefault = New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' | Add-Member -MemberType NoteProperty -Name TcpipNetbiosOptions -Value 0 -PassThru
        $MockNetadapterSettingsEnable = New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' | Add-Member -MemberType NoteProperty -Name TcpipNetbiosOptions -Value 1 -PassThru
        $MockNetadapterSettingsDisable = New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' | Add-Member -MemberType NoteProperty -Name TcpipNetbiosOptions -Value 2 -PassThru

        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            Mock -CommandName Get-CimAssociatedInstance -MockWith {return $MockNetadapterSettingsDefault}

            It 'Returns a hashtable' {
                $targetResource = Get-TargetResource -InterfaceAlias 'Ethernet' -Setting 'Default'
                $targetResource -is [System.Collections.Hashtable] | Should Be $true
            }

            It 'NetBIOS over TCP/IP numerical setting "0" should translate to "Default"' {
                $Result = Get-TargetResource -InterfaceAlias 'Ethernet' -Setting 'Default'
                $Result.Setting | should be 'Default'
            }

            It 'NetBIOS over TCP/IP setting should return real value "Default", not parameter value "Enable"' {
                $Result = Get-TargetResource -InterfaceAlias 'Ethernet' -Setting 'Enable'
                $Result.Setting | should be 'Default'
            }
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            Context 'invoking with NetBIOS over TCP/IP set to default' {

                Mock -CommandName Get-CimAssociatedInstance -MockWith {return $MockNetadapterSettingsDefault}

                It 'should return true when value "Default" is set' {
                    Test-TargetResource -InterfaceAlias 'Ethernet' -Setting 'Default' | Should Be $true
                }
                It 'should return false when value "Disable" is set' {
                    Test-TargetResource -InterfaceAlias 'Ethernet' -Setting 'Disable' | Should Be $false
                }
            }

            Context 'invoking with NetBIOS over TCP/IP set to Disable' {

                Mock -CommandName Get-CimAssociatedInstance -MockWith {return $MockNetadapterSettingsDisable}

                It 'should return true when value "Disable" is set' {
                    Test-TargetResource -InterfaceAlias 'Ethernet' -Setting 'Disable' | Should Be $true
                }
                It 'should return false when value "Enable" is set' {
                    Test-TargetResource -InterfaceAlias 'Ethernet' -Setting 'Enable' | Should Be $false
                }
            }

            Context 'invoking with NetBIOS over TCP/IP set to Enable' {

                Mock -CommandName Get-CimAssociatedInstance -MockWith {return $MockNetadapterSettingsEnable}

                It 'should return true when value "Enable" is set' {
                    Test-TargetResource -InterfaceAlias 'Ethernet' -Setting 'Enable' | Should Be $true
                }
                It 'should return false when value "Disable" is set' {
                    Test-TargetResource -InterfaceAlias 'Ethernet' -Setting 'Disable' | Should Be $false
                }
            }

            Context 'Invoking with NonExisting Network Adapter' {
                Mock -CommandName Get-CimAssociatedInstance -MockWith { }
                $ErrorRecord = New-Object System.Management.Automation.ErrorRecord 'Interface BogusAdapter was not found.', 'NICNotFound', 'ObjectNotFound', $null
                It 'should throw ObjectNotFound exception' {
                    {Test-TargetResource -InterfaceAlias 'BogusAdapter' -Setting 'Enable'} | Should Throw $ErrorRecord
                }
            }
        }
        #endregion


        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            Mock Set-ItemProperty
            Mock Invoke-CimMethod

            Context '"Setting" is "Default"' {

                Mock -CommandName Get-CimAssociatedInstance -MockWith {return $MockNetadapterSettingsEnable}

                It 'Should call "Set-ItemProperty" instead of "Invoke-CimMethod"' {
                    $Null = Set-TargetResource -InterfaceAlias 'Ethernet' -Setting 'Default'

                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1
                    Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 0
                }
            }

            Context '"Setting" is "Disable"' {

                It 'Should call "Invoke-CimMethod" instead of "Set-ItemProperty"' {
                    Mock -CommandName Get-CimAssociatedInstance -MockWith {return $MockNetadapterSettingsEnable}
                    Mock Invoke-CimMethod

                    $Null = Set-TargetResource -InterfaceAlias 'Ethernet' -Setting 'Disable'

                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0
                    Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 1
                }
            }
        }
        #endregion
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}

