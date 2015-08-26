function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        # Name of the Firewall Rule
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )

    # Populate the properties for get target resource
    Write-Verbose "GET: Get Rules for the specified Name[$Name]"
    $firewallRule = Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue
    if (-not $firewallRule)
    {
        Write-Verbose "GET: Firewall Rule does not exist, there is nothing interesting to do"
        return @{
            Name   = $Name
            Ensure = 'Absent'
        }
    }

    $properties = Get-FirewallRuleProperty -FirewallRule $firewallRule

    return @{
        Name            = $Name
        Ensure          = 'Present'
        DisplayName     = $firewallRule.DisplayName
        DisplayGroup    = $firewallRule.DisplayGroup
        Enabled         = $firewallRule.Enabled
        Profile         = $firewallRule.Profile.ToString() -replace(" ", "") -split(",")
        Direction       = $firewallRule.Direction
        Description     = $firewallRule.Description
        RemotePort      = @($properties.PortFilters.RemotePort)
        LocalPort       = @($properties.PortFilters.LocalPort)
        Protocol        = $properties.PortFilters.Protocol
        ApplicationPath = $properties.ApplicationFilters.Program
        Service         = $properties.ServiceFilters.Service
    }
}

function Set-TargetResource
{
    param
    (
        # Name of the Firewall Rule
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        # Localized, user-facing name of the Firewall Rule being created
        [ValidateNotNullOrEmpty()]
        [String] $DisplayName = $Name,

        # Name of the Firewall Group where we want to put the Firewall Rules
        [ValidateNotNullOrEmpty()]
        [String] $DisplayGroup = 'DSC_FirewallRule',

        # Ensure the presence/absence of the resource
        [ValidateSet("Present", "Absent")]
        [String] $Ensure = "Present",

        # Enable or disable the supplied configuration
        [ValidateSet("True", "False")]
        [String] $Enabled = "Enabled",

        # Specifies one or more profiles to which the rule is assigned
        [String[]] $Profile = ("Any"),

        # Direction of the connection
        [ValidateSet("Inbound", "Outbound")]
        [String] $Direction,

        # Specific Port used for filter. Specified by port number, range, or keyword
        [ValidateNotNullOrEmpty()]
        [String[]] $RemotePort,

        # Local Port used for the filter
        [ValidateNotNullOrEmpty()]
        [String[]] $LocalPort,

        # Specific Protocol for filter. Specified by name, number, or range
        [ValidateNotNullOrEmpty()]
        [String] $Protocol,

        # Documentation for the Rule
        [String] $Description,

        # Path and file name of the program for which the rule is applied
        [ValidateNotNullOrEmpty()]
        [String] $ApplicationPath,

        # Specifies the short name of a Windows service to which the firewall rule applies
        [ValidateNotNullOrEmpty()]
        [String] $Service
    )

    $null = $PSBoundParameters.Remove('Ensure')
    if (-not ($PSBoundParameters.ContainsKey('DisplayName')))
    {
        $null = $PSBoundParameters.Add('DisplayName', $Name)
    }

    Write-Verbose "SET: Find firewall rules with specified parameters for Name = $Name, DisplayGroup = $DisplayGroup"
    $firewallRules = Get-FirewallRule -Name $Name -DisplayGroup $DisplayGroup

    $exists = ($firewallRules -ne $null)

    if ($Ensure -eq "Present")
    {
        Write-Verbose "SET: We want the firewall rule to exist since Ensure is set to $Ensure"
        if ($exists)
        {
            Write-Verbose "SET: We want the firewall rule to exist and it does exist. Check for valid properties"
            foreach ($firewallRule in $firewallRules)
            {
                Write-Verbose "SET: Check each defined parameter against the existing firewall rule - $($firewallRule.Name)"
                if ( -not (Test-RuleProperties -FirewallRule $firewallRule @PSBoundParameters) )
                {
                    Write-Verbose "SET: Removing existing firewall rule [$Name] to recreate one based on desired configuration"
                    Remove-NetFirewallRule -Name $Name

                    # Set the Firewall rule based on specified parameters
                    New-NetFirewallRule @PSBoundParameters
                }
            }
        }
        else
        {
            # Set the Firewall rule based on specified parameters
            Write-Verbose "SET: We want the firewall rule [$Name] to exist, but it does not"
            New-NetFirewallRule @PSBoundParameters
        }
    }
    else
    {
        Write-Verbose "SET: We do not want the firewall rule to exist"
        if ($exists)
        {
            Write-Verbose "SET: We do not want the firewall rule to exist, but it does. Removing the Rule(s)"
            foreach ($firewallRule in $firewallRules)
            {
                Remove-NetFirewallRule -Name $firewallRule.Name
            }
        }
        else
        {
            Write-Verbose "SET: We do not want the firewall rule to exist, and it does not"
            # Do Nothing
        }
    }
}

# DSC uses Test-TargetResource cmdlet to check the status of the resource instance on the target machine
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        # Name of the Firewall Rule
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        # Localized, user-facing name of the Firewall Rule being created
        [ValidateNotNullOrEmpty()]
        [String] $DisplayName = $Name,

        # Name of the Firewall Group where we want to put the Firewall Rules
        [ValidateNotNullOrEmpty()]
        [String] $DisplayGroup,

        # Ensure the presence/absence of the resource
        [ValidateSet("Present", "Absent")]
        [String] $Ensure = "Present",

        # Enable or disable the supplied configuration
        [ValidateSet("True", "False")]
        [String] $Enabled,

        # Specifies one or more profiles to which the rule is assigned
        [String[]] $Profile,

        # Direction of the connection
        [ValidateSet("Inbound", "Outbound")]
        [String] $Direction,

        # Specific Port used for filter. Specified by port number, range, or keyword
        [ValidateNotNullOrEmpty()]
        [String[]] $RemotePort,

        # Local Port used for the filter
        [ValidateNotNullOrEmpty()]
        [String[]] $LocalPort,

        # Specific Protocol for filter. Specified by name, number, or range
        [ValidateNotNullOrEmpty()]
        [String] $Protocol,

        # Documentation for the Rule
        [String] $Description,

        # Path and file name of the program for which the rule is applied
        [ValidateNotNullOrEmpty()]
        [String] $ApplicationPath,

        # Specifies the short name of a Windows service to which the firewall rule applies
        [ValidateNotNullOrEmpty()]
        [String] $Service
    )

    $null = $PSBoundParameters.Remove('Ensure')

    Write-Verbose "TEST: Find rules with specified parameters"
    $firewallRules = Get-FirewallRule -Name $Name -DisplayGroup $DisplayGroup

    if (-not $firewallRules)
    {
        Write-Verbose "TEST: Get-FirewallRule returned NULL"

        # Returns whether complies with $Ensure
        $returnValue = ($false -eq ($Ensure -eq "Present"))

        Write-Verbose "TEST: Returning $returnValue"

        return $returnValue
    }

    $exists = $true
    $valid = $true
    foreach ($firewallRule in $firewallRules)
    {
        Write-Verbose "TEST: Check each defined parameter against the existing Firewall Rule - $($firewallRule.Name)"
        if (-not (Test-RuleProperties -FirewallRule $firewallRule @PSBoundParameters ) )
        {
            $valid = $false
        }
    }

    # Returns whether or not $exists complies with $Ensure
    $returnValue = ($valid -and $exists -eq ($Ensure -eq "Present"))

    Write-Verbose "TEST: Returning $returnValue"

    return $returnValue
}

#region HelperFunctions

######################
## Helper Functions ##
######################

# Function to validate if the supplied Rule adheres to all parameters set
function Test-RuleProperties
{
    param (
        [Parameter(Mandatory)]
        $FirewallRule,
        [String] $Name,
        [String] $DisplayName = $Name,
        [String] $DisplayGroup,
        [String] $Enabled,
        [String[]] $Profile,
        [String] $Direction,
        [String[]] $RemotePort,
        [String[]] $LocalPort,
        [String] $Protocol,
        [String] $Description,
        [String] $ApplicationPath,
        [String] $Service
    )

    $properties = Get-FirewallRuleProperty -FirewallRule $FirewallRule

    $desiredConfigurationMatch = $true

    if ($Name -and ($FirewallRule.Name -ne $Name))
    {
        Write-Verbose "Test-RuleProperties: Name property value - $FirewallRule.Name does not match desired state - $Name"
        $desiredConfigurationMatch = $false
    }

    if ($Enabled -and ($FirewallRule.Enabled.ToString() -eq ("Enabled" -ne $Enabled)))
    {
        Write-Verbose "Test-RuleProperties: State property value - $FirewallRule.Enabled.ToString() does not match desired state - $State"
        $desiredConfigurationMatch = $false
    }

    if ($Profile)
    {
        [String[]]$networkProfileinRule = $FirewallRule.Profile.ToString() -replace(" ", "") -split(",")

        if ($networkProfileinRule.Count -eq $Profile.Count)
        {
            foreach($networkProfile in $Profile)
            {
                if (-not ($networkProfileinRule -contains($networkProfile)))
                {
                    Write-Verbose "Test-RuleProperties: Profile property value - '$networkProfileinRule' does not match desired state - '$Profile'"
                    $desiredConfigurationMatch = $false
                }
            }
        }
        else
        {
            Write-Verbose "Test-RuleProperties: Profile property value - '$networkProfileinRule' does not match desired state - '$Profile'"
            $desiredConfigurationMatch = $false
        }
    }

    if ($Direction -and ($FirewallRule.Direction -ne $Direction))
    {
        Write-Verbose "Test-RuleProperties: Direction property value - $FirewallRule.Direction does not match desired state - $Direction"
        $desiredConfigurationMatch = $false
    }

    if ($RemotePort)
    {
        [String[]]$remotePortInRule = $properties.PortFilters.RemotePort

        if ($remotePortInRule.Count -eq $RemotePort.Count)
        {
            foreach($port in $RemotePort)
            {
                if (-not ($remotePortInRule -contains($port)))
                {
                    Write-Verbose "Test-RuleProperties: RemotePort property value - '$remotePortInRule' does not match desired state - '$RemotePort'"

                    $desiredConfigurationMatch = $false
                }
            }
        }
        else
        {
            Write-Verbose "Test-RuleProperties: RemotePort property value - '$remotePortInRule' does not match desired state - '$RemotePort'"

            $desiredConfigurationMatch = $false
        }
    }

    if ($LocalPort)
    {
        [String[]]$localPortInRule = $properties.PortFilters.LocalPort

        if ($localPortInRule.Count -eq $LocalPort.Count)
        {
            foreach($port in $LocalPort)
            {
                if (-not ($localPortInRule -contains($port)))
                {
                    Write-Verbose "Test-RuleProperties: LocalPort property value - '$localPortInRule' does not match desired state - '$LocalPort'"
                    $desiredConfigurationMatch = $false
                }
            }
        }
        else
        {
            Write-Verbose "Test-RuleProperties: LocalPort property value - '$localPortInRule' does not match desired state - '$LocalPort'"
            $desiredConfigurationMatch = $false
        }
    }

    if ($Protocol -and ($properties.PortFilters.Protocol -ne $Protocol))
    {
        Write-Verbose "Test-RuleProperties: Protocol property value - $properties.PortFilters.Protocol does not match desired state - $Protocol"
        $desiredConfigurationMatch = $false
    }

    if ($Description -and ($FirewallRule.Description -ne $Description))
    {
        Write-Verbose "Test-RuleProperties: Description property value - $FirewallRule.Description does not match desired state - $Description"
        $desiredConfigurationMatch = $false
    }

    if ($ApplicationPath -and ($properties.ApplicationFilters.Program -ne $ApplicationPath))
    {
        Write-Verbose "Test-RuleProperties: ApplicationPath property value - $properties.ApplicationFilters.Program does not match desired state - $ApplicationPath"
        $desiredConfigurationMatch = $false
    }

    if ($Service -and ($properties.ServiceFilters.Service -ne $Service))
    {
        Write-Verbose "Test-RuleProperties: Service property value - $properties.ServiceFilters.Service  does not match desired state - $Service"
        $desiredConfigurationMatch = $false
    }

    Write-Verbose "Test-RuleProperties returning $desiredConfigurationMatch"
    return $desiredConfigurationMatch
}

# Returns a list of FirewallRules that comply to the specified parameters.
function Get-FirewallRule
{
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        [String] $DisplayGroup
    )

    $firewallRules = @(Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue)

    if (-not $firewallRules)
    {
        Write-Verbose "Get-FirewallRule: No Firewall Rules found for [$Name]"
        return $null
    }
    else
    {
        if ($DisplayGroup)
        {
            foreach ($firewallRule in $firewallRules)
            {
                if ($firewallRule.DisplayGroup -eq $DisplayGroup)
                {
                    Write-Verbose "Get-FirewallRule: Found a Firewall Rule for Name: [$Name] and DisplayGroup [$DisplayGroup]"
                    return $firewallRule
                }
            }
        }
    }

    return $firewallRules
}

# Returns the filters associated with the given firewall rule
function Get-FirewallRuleProperty
{
    param (
        [Parameter(Mandatory)]
        $FirewallRule
     )

    Write-Verbose "Get-FirewallRuleProperty:  Get all the properties"
    Write-Verbose "Get-FirewallRuleProperty: Add filter info to rule map"
    return @{
        AddressFilters       = @(Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $FirewallRule)
        ApplicationFilters   = @(Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $FirewallRule)
        InterfaceFilters     = @(Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $FirewallRule)
        InterfaceTypeFilters = @(Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $FirewallRule)
        PortFilters          = @(Get-NetFirewallPortFilter -AssociatedNetFirewallRule $FirewallRule)
        Profile              = @(Get-NetFirewallProfile -AssociatedNetFirewallRule $FirewallRule)
        SecurityFilters      = @(Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $FirewallRule)
        ServiceFilters       = @(Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $FirewallRule)
    }
}

#endregion

Export-ModuleMember -Function *-TargetResource
