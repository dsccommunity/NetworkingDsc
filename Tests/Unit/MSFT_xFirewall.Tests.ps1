$DSCModuleName      = 'xNetworking'
$DSCResourceName    = 'MSFT_xFirewall'
$RelativeModulePath = "DSCResources\$DSCResourceName\$DSCResourceName.psm1"

#region HEADER
# Temp Working Folder - always gets remove on completion
$WorkingFolder = Join-Path -Path $env:Temp -ChildPath $DSCResourceName

# Copy to Program Files for WMF 4.0 Compatability as it can only find resources in a few known places.
$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

# If this module already exists in the Modules folder, make a copy of it in
# the temporary folder so that it isn't accidentally used in this test.
if(-not (Test-Path -Path $moduleRoot))
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
}
else
{
    # Copy the existing folder out to the temp directory to hold until the end of the run
    # Delete the folder to remove the old files.
    $tempLocation = Join-Path -Path $env:Temp -ChildPath $DSCModuleName
    Copy-Item -Path $moduleRoot -Destination $tempLocation -Recurse -Force
    Remove-Item -Path $moduleRoot -Recurse -Force
    $null = New-Item -Path $moduleRoot -ItemType Directory
}


# Copy the module to be tested into the Module Root
Copy-Item -Path $PSScriptRoot\..\..\* -Destination $moduleRoot -Recurse -Force -Exclude '.git'

# Import the Module
$Splat = @{
    Path = $moduleRoot
    ChildPath = $RelativeModulePath
    Resolve = $true
    ErrorAction = 'Stop'
}
$DSCModuleFile = Get-Item -Path (Join-Path @Splat)

# Remove all copies of the module from memory so an old one is not used.
if (Get-Module -Name $DSCModuleFile.BaseName -All)
{
    Get-Module -Name $DSCModuleFile.BaseName -All | Remove-Module
}

# Import the Module to test.
Import-Module -Name $DSCModuleFile.FullName -Force

<#
  This is to fix a problem in AppVoyer where we have multiple copies of the resource
  in two different folders. This should probably be adjusted to be smarter about how
  it finds the resources.
#>
if (($env:PSModulePath).Split(';') -ccontains $pwd.Path)
{
    $script:tempPath = $env:PSModulePath
    $env:PSModulePath = ($env:PSModulePath -split ';' | Where-Object {$_ -ne $pwd.path}) -join ';'
}

# Preserve and set the execution policy so that the DSC MOF can be created
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -ne 'Unrestricted')
{
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
    $rollbackExecution = $true
}
#endregion

# Begin Testing
try
{

    #region Pester Tests

    InModuleScope $DSCResourceName {

        #region Pester Test Initialization
        # Get the rule that will be used for testing
        $FirewallRuleName = (Get-NetFirewallRule | `
            Sort-Object Name | `
            Where-Object {$_.DisplayGroup -ne $null} | `
            Select-Object -first 1).Name
        $FirewallRule = Get-FirewallRule -Name $FirewallRuleName
        $Properties = Get-FirewallRuleProperty -FirewallRule $FirewallRule
        #endregion

        #region Function Get-TargetResource
        Describe 'Get-TargetResource' {
            Context 'Absent should return correctly' {
                Mock Get-NetFirewallRule

                It 'Should return absent' {
                    $result = Get-TargetResource -Name 'FirewallRule'
                    $result.Name | Should Be 'FirewallRule'
                    $result.Ensure | Should Be 'Absent'
                }
            }

            Context 'Present should return correctly' {
                $result = Get-TargetResource -Name $FirewallRule.Name

                # Looping these tests
                foreach ($parameter in $ParameterList)
                {
                    $ParameterSource = (Invoke-Expression -Command "`$($($parameter.source))")
                    $ParameterNew = (Invoke-Expression -Command "`$result.$($parameter.name)")
                    It "should have the correct $($parameter.Name)" {
                        $ParameterSource | Should Be $ParameterNew
                    }
                }
            }
        }
        #endregion


        #region Function Test-TargetResource
        Describe 'Test-TargetResource' {
            Context 'Ensure is Absent and the Firewall is not Present' {
                Mock Get-FirewallRule

                It 'should return $true' {
                    $result = Test-TargetResource -Name 'FirewallRule' -Ensure 'Absent'
                    $result | Should Be $true
                }
            }
            Context 'Ensure is Absent and the Firewall is Present' {
                Mock Test-RuleProperties

                It 'should return $false' {
                    $result = Test-TargetResource -Name $FirewallRule.Name -Ensure 'Absent'
                    $result | Should Be $false
                }
            }
            Context 'Ensure is Present and the Firewall is Present and properties match' {
                Mock Test-RuleProperties -MockWith { return $true }

                It 'should return $true' {
                    $result = Test-TargetResource -Name $FirewallRule.Name
                    $result | Should Be $true
                }
            }
            Context 'Ensure is Present and the Firewall is Present and properties are different' {
                Mock Test-RuleProperties -MockWith { return $false }

                It 'should return $false' {
                    $result = Test-TargetResource -Name $FirewallRule.Name
                    $result | Should Be $false
                }
            }
            Context 'Ensure is Present and the Firewall is Absent' {
                Mock Get-FirewallRule
                It 'should return $false' {
                    $result = Test-TargetResource -Name $FirewallRule.Name
                    $result | Should Be $false
                }
            }
        }
        #endregion


        #region Function Set-TargetResource
        Describe 'Set-TargetResource' {
            # To speed up all these tests create Mocks so that these functions are not repeatedly called
            Mock Get-FirewallRule -MockWith { $FirewallRule }
            Mock Get-FirewallRuleProperty -MockWith { $Properties }

            Context 'Ensure is Absent and Firewall Exist' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Remove-NetFirewallRule
                    $result = Set-TargetResource -Name $FirewallRule.Name -Ensure 'Absent'

                    Assert-MockCalled Remove-NetFirewallRule -Exactly 1
                }
            }
            Context 'Ensure is Absent and the Firewall Does Not Exist' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Get-FirewallRule
                    Mock Remove-NetFirewallRule
                    $result = Set-TargetResource -Name $FirewallRule.Name -Ensure 'Absent'

                    Assert-MockCalled Remove-NetFirewallRule -Exactly 0
                }
            }
            Context 'Ensure is Present and the Firewall Does Not Exist' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Get-FirewallRule
                    Mock New-NetFirewallRule
                    $result = Set-TargetResource -Name $FirewallRule.Name -Ensure 'Present'

                    Assert-MockCalled New-NetFirewallRule -Exactly 1
                    Assert-MockCalled Get-FirewallRule -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different DisplayName' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -DisplayName 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Group' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock New-NetFirewallRule
                    Mock Remove-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -DisplayName $FirewallRule.DisplayName `
                        -Group 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled New-NetFirewallRule -Exactly 1
                    Assert-MockCalled Remove-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Enabled' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    if( $FirewallRule.Enabled -eq 'True' ) {
                        $NewEnabled = 'False'
                    }
                    else
                    {
                        $NewEnabled = 'True'
                    }
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Enabled $NewEnabled `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Action' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    if ( $FirewallRule.Action -eq 'Allow') {
                        $NewAction = 'Block'
                    }
                    else
                    {
                        $NewAction = 'Allow'
                    }
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Action $NewAction `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Profile' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    if ( $FirewallRule.Profile -ccontains 'Domain') {
                        $NewProfile = @('Public','Private')
                    }
                    else
                    {
                        $NewProfile = @('Domain','Public')
                    }
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Profile $NewProfile `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Direction' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    if ( $FirewallRule.Direction -eq 'Inbound') {
                        $NewDirection = 'Outbound'
                    }
                        else
                    {
                        $NewDirection = 'Inbound'
                    }
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Direction $NewDirection `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different RemotePort' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -RemotePort 9999 `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different LocalPort' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -LocalPort 9999 `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Protocol' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    if ( $FirewallRule.Protocol -eq 'TCP') {
                        $NewProtocol = 'UDP'
                    }
                    else
                    {
                        $NewProtocol = 'TCP'
                    }
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Protocol $NewProtocol `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Description' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Description 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Program' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Program 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Service' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Service 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Authentication' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    if ( $properties.SecurityFilters.Authentication -eq 'Required') {
                        $NewAuthentication = 'NotRequired'
                    }
                    else
                    {
                        $NewAuthentication = 'Required'
                    }
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Authentication $NewAuthentication `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Encryption' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    if ( $properties.SecurityFilters.Encryption -eq 'Required') {
                        $NewEncryption = 'NotRequired'
                    }
                    else
                    {
                        $NewEncryption = 'Required'
                    }
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Encryption $NewEncryption `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different InterfaceAlias' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -InterfaceAlias 'Different' `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different InterfaceType' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    if ( $properties.InterfaceTypeFilters.InterfaceType -eq 'Wired') {
                        $NewInterfaceType = 'Wireless'
                    }
                    else
                    {
                        $NewInterfaceType = 'Wired'
                    }
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -InterfaceType $NewInterfaceType `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different LocalAddress' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -LocalAddress @('10.0.0.1/255.0.0.0','10.1.1.0-10.1.2.0') `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different LocalUser' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -LocalUser 'O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)' `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Package' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Package 'S-1-15-2-3676279713-3632409675-756843784-3388909659-2454753834-4233625902-1413163418' `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different Platform' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -Platform @('6.1') `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist but has a different RemoteAddress' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -RemoteAddress @('10.0.0.1/255.0.0.0','10.1.1.0-10.1.2.0') `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different RemoteMachine' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -RemoteMachine 'O:LSD:(D;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1621)(A;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1620)' `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
            Context 'Ensure is Present and the Firewall Does Exist but has a different RemoteUser' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $false}
                    $result = Set-TargetResource `
                        -Name $FirewallRule.Name `
                        -RemoteUser 'O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)' `
                        -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 1
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }

            Context 'Ensure is Present and the Firewall Does Exist and is the same' {
                It "should call expected mocks on firewall rule $($FirewallRule.Name)" {
                    Mock Set-NetFirewallRule
                    Mock Test-RuleProperties {return $true}
                    $result = Set-TargetResource -Name $FirewallRule.Name -Ensure 'Present'

                    Assert-MockCalled Set-NetFirewallRule -Exactly 0
                    Assert-MockCalled Test-RuleProperties -Exactly 1
                }
            }
        }
        #endregion


        #region Function Test-RuleProperties
        Describe 'Test-RuleProperties' {
            # Make an object that can be splatted onto the function
            $Splat = @{
                Name = $FirewallRule.Name
                DisplayGroup = $FirewallRule.DisplayGroup
                Group = $FirewallRule.Group
                Enabled = $FirewallRule.Enabled
                Profile = $FirewallRule.Profile
                Direction = $FirewallRule.Direction
                Action = $FirewallRule.Action
                RemotePort = $Properties.PortFilters.RemotePort
                LocalPort = $Properties.PortFilters.LocalPort
                Protocol = $Properties.PortFilters.Protocol
                Description = $FirewallRule.Description
                Program = $Properties.ApplicationFilters.Program
                Service = $Properties.ServiceFilters.Service
                Authentication = $properties.SecurityFilters.Authentication
                Encryption = $properties.SecurityFilters.Encryption
                InterfaceAlias = $properties.InterfaceFilters.InterfaceAlias
                InterfaceType = $properties.InterfaceTypeFilters.InterfaceType
                LocalAddress = $properties.AddressFilters.LocalAddress
                LocalUser = $properties.SecurityFilters.LocalUser
                Package = $properties.ApplicationFilters.Package
                Platform = $firewallRule.Platform
                RemoteAddress = $properties.AddressFilters.RemoteAddress
                RemoteMachine = $properties.SecurityFilters.RemoteMachine
                RemoteUser = $properties.SecurityFilters.RemoteUser
            }

            # To speed up all these tests create Mocks so that these functions are not repeatedly called
            Mock Get-FirewallRule -MockWith { $FirewallRule }
            Mock Get-FirewallRuleProperty -MockWith { $Properties }

            Context 'testing with a rule with no property differences' {
                $CompareRule = $Splat.Clone()
                It 'should return True' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $True
                }
            }
            Context 'testing with a rule with a different name' {
                $CompareRule = $Splat.Clone()
                $CompareRule.Name = 'Different'
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different displayname' {
                $CompareRule = $Splat.Clone()
                $CompareRule.DisplayName = 'Different'
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different group' {
                $CompareRule = $Splat.Clone()
                $CompareRule.Group = 'Different'
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different enabled' {
                $CompareRule = $Splat.Clone()
                if( $CompareRule.Enabled -eq 'True' ) {
                    $CompareRule.Enabled = 'False'
                }
                else
                {
                    $CompareRule.Enabled = 'True'
                }
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different action' {
                $CompareRule = $Splat.Clone()
                if ($CompareRule.Action -eq 'Allow') {
                    $CompareRule.Action = 'Block'
                }
                else
                {
                    $CompareRule.Action = 'Allow'
                }
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different profile' {
                $CompareRule = $Splat.Clone()
                if ( $CompareRule.Profile -ccontains 'Domain') {
                    $CompareRule.Profile = @('Public','Private')
                }
                else
                {
                    $CompareRule.Profile = @('Domain','Public')
                }
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different direction' {
                $CompareRule = $Splat.Clone()
                if ($CompareRule.Direction -eq 'Inbound') {
                    $CompareRule.Direction = 'Outbound'
                }
                else
                {
                    $CompareRule.Direction = 'Inbound'
                }
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different remote port' {
                $CompareRule = $Splat.Clone()
                $CompareRule.RemotePort = 1
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different local port' {
                $CompareRule = $Splat.Clone()
                $CompareRule.LocalPort = 1
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different protocol' {
                $CompareRule = $Splat.Clone()
                if ( $CompareRule.Protocol -eq 'TCP') {
                    $CompareRule.Protocol = 'UDP'
                }
                else
                {
                    $CompareRule.Protocol = 'TCP'
                }
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different description' {
                $CompareRule = $Splat.Clone()
                $CompareRule.Description = 'Different'
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different program' {
                $CompareRule = $Splat.Clone()
                $CompareRule.Program = 'Different'
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different service' {
                $CompareRule = $Splat.Clone()
                $CompareRule.Service = 'Different'
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different Authentication' {
                $CompareRule = $Splat.Clone()
                if ( $CompareRule.Authentication -eq 'Required') {
                    $CompareRule.Authentication = 'NotRequired'
                }
                else
                {
                    $CompareRule.Authentication = 'Required'
                }
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different Encryption' {
                $CompareRule = $Splat.Clone()
                if ( $CompareRule.Encryption -eq 'Required') {
                    $CompareRule.Encryption = 'NotRequired'
                }
                else
                {
                    $CompareRule.Encryption = 'Required'
                }
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different InterfaceAlias' {
                $CompareRule = $Splat.Clone()
                $CompareRule.InterfaceAlias = 'Different'
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different InterfaceType' {
                $CompareRule = $Splat.Clone()
                if ( $CompareRule.InterfaceType -eq 'Wired') {
                    $CompareRule.InterfaceType = 'Wireless'
                }
                else
                {
                    $CompareRule.InterfaceType = 'Wired'
                }
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different LocalAddress' {
                $CompareRule = $Splat.Clone()
                $CompareRule.LocalAddress = @('10.0.0.1/255.0.0.0','10.1.1.0-10.1.2.0')
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different LocalUser' {
                $CompareRule = $Splat.Clone()
                $CompareRule.LocalUser = 'O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)'
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different Package' {
                $CompareRule = $Splat.Clone()
                $CompareRule.Package = 'S-1-15-2-3676279713-3632409675-756843784-3388909659-2454753834-4233625902-1413163418'
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different Platform' {
                $CompareRule = $Splat.Clone()
                $CompareRule.Platform = @('6.2')
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different RemoteAddress' {
                $CompareRule = $Splat.Clone()
                $CompareRule.RemoteAddress = @('10.0.0.1/255.0.0.0','10.1.1.0-10.1.2.0')
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different RemoteMachine' {
                $CompareRule = $Splat.Clone()
                $CompareRule.RemoteMachine = 'O:LSD:(D;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1621)(A;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1620)'
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }
            Context 'testing with a rule with a different RemoteUser' {
                $CompareRule = $Splat.Clone()
                $CompareRule.RemoteUser = 'O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)'
                It 'should return False' {
                    $Result = Test-RuleProperties -FirewallRule $FirewallRule @CompareRule
                    $Result | Should be $False
                }
            }

        }
        #endregion


        #region Function Get-FirewallRule
        Describe ' Get-FirewallRule' {
            $FirewallRule = Get-NetFirewallRule | Select-Object -First 1
            $FirewallRules = Get-NetFirewallRule | Select-Object -First 2

            Context 'testing with firewall that exists' {
                It 'should return a firewall rule when name is passed' {
                    $Result = Get-FirewallRule -Name $FirewallRule.Name
                    $Result | Should Not BeNullOrEmpty
                }
            }
            Context 'testing with firewall that does not exist' {
                It 'should not return anything' {
                    $Result = Get-FirewallRule -Name 'Does not exist'
                    $Result | Should BeNullOrEmpty
                }
            }
            Context 'testing with firewall that somehow occurs more than once' {
                Mock Get-NetFirewallRule -MockWith { $FirewallRules }

                $errorId = 'RuleNotUnique'
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $errorMessage = $($LocalizedData.RuleNotUniqueError) -f 2,$FirewallRule.Name
                $exception = New-Object -TypeName System.InvalidOperationException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                It 'should throw RuleNotUnique exception' {
                    { $Result = Get-FirewallRule -Name $FirewallRule.Name } | Should Throw $errorRecord
                }
            }
        }
        #endregion


        #region Function Get-FirewallRuleProperty
        Describe 'Get-FirewallRuleProperty' {
            Context 'All Properties' {
                $result = Get-FirewallRuleProperty -FirewallRule $FirewallRule
                It 'Should return the right address filter' {
                    $expected = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $FirewallRule

                    $($result.AddressFilters | Out-String -Stream) |
                        Should Be $($expected | Out-String -Stream)
                }

                It 'Should return the right application filter' {
                    $expected = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $FirewallRule

                    $($result.ApplicationFilters | Out-String -Stream) |
                        Should Be $($expected | Out-String -Stream)
                }

                It 'Should return the right interface filter' {
                    $expected = Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $FirewallRule

                    $($result.InterfaceFilters | Out-String -Stream) |
                        Should Be $($expected | Out-String -Stream)
                }

                It 'Should return the right interface type filter' {
                    $expected = Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $FirewallRule
                    $($result.InterfaceTypeFilters | Out-String -Stream) |
                        Should Be $($expected | Out-String -Stream)
                }

                It 'Should return the right port filter' {
                    $expected = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $FirewallRule
                    $($result.PortFilters | Out-String -Stream) |
                        Should Be $($expected | Out-String -Stream)
                }

                It 'Should return the right Profile' {
                    $expected = Get-NetFirewallProfile -AssociatedNetFirewallRule $FirewallRule
                    $($result.Profile | Out-String -Stream) |
                        Should Be $($expected | Out-String -Stream)
                }

                It 'Should return the right Profile' {
                    $expected = Get-NetFirewallProfile -AssociatedNetFirewallRule $FirewallRule
                    $($result.Profile | Out-String -Stream) |
                        Should Be $($expected | Out-String -Stream)
                }

                It 'Should return the right Security Filters' {
                    $expected = Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $FirewallRule
                    $($result.SecurityFilters | Out-String -Stream) |
                        Should Be $($expected | Out-String -Stream)
                }

                It 'Should return the right Service Filters' {
                    $expected = Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $FirewallRule
                    $($result.ServiceFilters | Out-String -Stream) |
                        Should Be $($expected | Out-String -Stream)
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
    # Set PSModulePath back to previous settings
    $env:PSModulePath = $script:tempPath;

    # Restore the Execution Policy
    if ($rollbackExecution)
    {
        Set-ExecutionPolicy -ExecutionPolicy $executionPolicy -Force
    }

    # Cleanup Working Folder
    if (Test-Path -Path $WorkingFolder)
    {
        Remove-Item -Path $WorkingFolder -Recurse -Force
    }

    # Clean up after the test completes.
    Remove-Item -Path $moduleRoot -Recurse -Force

    # Restore previous versions, if it exists.
    if ($tempLocation)
    {
        $null = New-Item -Path $moduleRoot -ItemType Directory
        Copy-Item -Path $tempLocation -Destination "${env:ProgramFiles}\WindowsPowerShell\Modules" -Recurse -Force
        Remove-Item -Path $tempLocation -Recurse -Force
    }
    #endregion

    # Other Cleanup Code Goes Here...
}
