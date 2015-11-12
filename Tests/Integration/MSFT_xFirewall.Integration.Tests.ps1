# Configure these three lines:
$DSCModuleName   = 'xNetworking'
$DSCResourceName = 'MSFT_xFirewall'
$RelativeModulePath = "$DSCModuleName.psd1"

# If this module already exists in the Modules folder, make a copy of it in
# the temporary folder so that it isn't accidentally used in this test.
$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"
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
if (Get-Module -Name $DSCModuleFile.BaseName -All)
{
    Get-Module -Name $DSCModuleFile.BaseName -All | Remove-Module
}
Import-Module -Name $DSCModuleFile.FullName -Force

# Remove the Current Path from the Module Search Path
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

# Other Init Code Goes Here...

# Begin Testing
#try
#{

####################################################################################################

    # Load in the DSC Configuration
    . $PSScriptRoot\Firewall.ps1

    Describe 'xFirewall_Integration' {
        It 'Should compile without throwing' {
            {
                [System.Environment]::SetEnvironmentVariable('PSModulePath',
                    $env:PSModulePath,[System.EnvironmentVariableTarget]::Machine)
                Firewall -OutputPath $env:Temp\Firewall
                Start-DscConfiguration -Path $env:Temp\Firewall -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            {Get-DscConfiguration} | Should Not throw
        }

        It 'Should have set the firewall and all the parameters should match' {
            # Get the Rule details
            $firewallRule = Get-NetFireWallRule -Name $rule.Name
            $Properties = @{
                AddressFilters       = @(Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $FirewallRule)
                ApplicationFilters   = @(Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $FirewallRule)
                InterfaceFilters     = @(Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $FirewallRule)
                InterfaceTypeFilters = @(Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $FirewallRule)
                PortFilters          = @(Get-NetFirewallPortFilter -AssociatedNetFirewallRule $FirewallRule)
                Profile              = @(Get-NetFirewallProfile -AssociatedNetFirewallRule $FirewallRule)
                SecurityFilters      = @(Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $FirewallRule)
                ServiceFilters       = @(Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $FirewallRule)
            }

            # Use the Parameters List to perform these tests
            foreach ($p in $ParameterList)
            {
                $ParameterSource = (Invoke-Expression -Command "`$($($p.source))")
                $ParameterNew = (Invoke-Expression -Command "`$rule.$($p.name)")
                $ParameterSource | Should Be $ParameterNew
            }
        }
    }

####################################################################################################

#}
#finally
#{
    # Restore the Execution Policy
    if ($rollbackExecution)
    {
        Set-ExecutionPolicy -ExecutionPolicy $executionPolicy -Force
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

    # Other Cleanup Code Goes Here...
    Remove-NetFirewallRule -Name $rule.Name
    Remove-Item -Path $env:Temp\Firewall -Recurse -Force
#}
