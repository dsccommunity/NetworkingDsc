#######################################################################################
#  xFirewall : DSC Resource that will set/test/get Firewall Rules
#######################################################################################

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
GettingFirewallRuleMessage=Getting firewall rule with Name '{0}'.
FirewallRuleDoesNotExistMessage=Firewall rule with Name '{0}' does not exist.
ApplyingFirewallRuleMessage=Applying settings for firewall rule with Name '{0}'.
FindFirewallRuleMessage=Find firewall rule with Name '{0}'.
FirewallRuleShouldExistMessage=We want the firewall rule with Name '{0}' to exist since Ensure is set to {1}.
FirewallRuleShouldExistAndDoesMessage=We want the firewall rule with Name '{0}' to exist and it does. Check for valid properties.
CheckFirewallRuleParametersMessage=Check each defined parameter against the existing firewall rule with Name '{0}'.
UpdatingExistingFirewallMessage=Updating existing firewall rule with Name '{0}'.
FirewallRuleShouldExistAndDoesNotMessage=We want the firewall rule with Name '{0}' to exist, but it does not.
FirewallRuleShouldNotExistMessage=We do not want the firewall rule with Name '{0}' to exist since Ensure is set to {1}.
FirewallRuleShouldNotExistButDoesMessage=We do not want the firewall rule with Name '{0}' to exist, but it does. Removing it.
FirewallRuleShouldNotExistAndDoesNotMessage=We do not want the firewall rule with Name '{0}' to exist, and it does not.
CheckingFirewallRuleMessage=Checking settings for firewall rule with Name '{0}'.
CheckingFirewallReturningMessage=Check Firewall rule with Name '{0}' returning {1}.
CheckingFirewallParametersMessage=Check each defined parameter against the existing Firewall Rule with Name '{0}'.
PropertyNoMatchMessage={0} property value '{1}' does not match desired state '{2}'.
TestFirewallRuleReturningMessage=Test Firewall rule with Name '{0}' returning {1}.
FirewallRuleNotFoundMessage=No Firewall Rule found with Name '{0}'.
GetAllPropertiesMessage=Get all the properties and add filter info to rule map.
RuleNotUniqueError={0} Firewall Rules with the Name '{1}' were found. Only one expected.
'@
}

######################################################################################
# The Get-TargetResource cmdlet.
######################################################################################
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

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingFirewallRuleMessage) -f $Name
        ) -join '')

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.FindFirewallRuleMessage) -f $Name
        ) -join '')
    $firewallRule = Get-FirewallRule -Name $Name

    if (-not $firewallRule)
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.FirewallRuleDoesNotExistMessage) -f $Name
            ) -join '')
        return @{
            Name   = $Name
            Ensure = 'Absent'
        }
    }

    $properties = Get-FirewallRuleProperty -FirewallRule $firewallRule

    # Populate the properties for get target resource
    return @{
        Name            = $Name
        Ensure          = 'Present'
        DisplayName     = $firewallRule.DisplayName
        Group           = $firewallRule.Group
        DisplayGroup    = $firewallRule.DisplayGroup
        Enabled         = $firewallRule.Enabled
        Action          = $firewallRule.Action
        Profile         = $firewallRule.Profile.ToString() -replace(' ', '') -split(',')
        Direction       = $firewallRule.Direction
        Description     = $firewallRule.Description
        RemotePort      = @($properties.PortFilters.RemotePort)
        LocalPort       = @($properties.PortFilters.LocalPort)
        Protocol        = $properties.PortFilters.Protocol
        ApplicationPath = $properties.ApplicationFilters.Program
        Service         = $properties.ServiceFilters.Service
    }
}

######################################################################################
# The Set-TargetResource cmdlet.
######################################################################################
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
        [String] $DisplayName,

        # Name of the Firewall Group where we want to put the Firewall Rules
        [ValidateNotNullOrEmpty()]
        [String] $DisplayGroup,

        # Ensure the presence/absence of the resource
        [ValidateSet('Present', 'Absent')]
        [String] $Ensure = 'Present',

        # Enable or disable the supplied configuration
        [ValidateSet('True', 'False')]
        [String] $Enabled,

        [ValidateSet('NotConfigured', 'Allow', 'Block')]
        [String] $Action,

        # Specifies one or more profiles to which the rule is assigned
        [String[]] $Profile,

        # Direction of the connection
        [ValidateSet('Inbound', 'Outbound')]
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

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.ApplyingFirewallRuleMessage) -f $Name
        ) -join '')

    # Remove any parameters not used in Splats
    $null = $PSBoundParameters.Remove('Ensure')

    # Effectively renaming DisplayGroup to Group
    if ($DisplayGroup) {
        $null = $PSBoundParameters.Add('Group', $DisplayGroup)
    }
    $null = $PSBoundParameters.Remove('DisplayGroup')

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.FindFirewallRuleMessage) -f $Name
        ) -join '')
    $firewallRule = Get-FirewallRule -Name $Name

    $exists = ($firewallRule -ne $null)

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.FirewallRuleShouldExistMessage) -f $Name,$Ensure
            ) -join '')

        if ($exists)
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.FirewallRuleShouldExistAndDoesMessage) -f $Name
                ) -join '')
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.CheckFirewallRuleParametersMessage) -f $Name
                ) -join '')

            if (-not (Test-RuleProperties -FirewallRule $firewallRule @PSBoundParameters))
            {
                Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                    $($LocalizedData.UpdatingExistingFirewallMessage) -f $Name
                    ) -join '')

                # Set the existing Firewall rule based on specified parameters
                Set-NetFirewallRule @PSBoundParameters
            }
        }
        else
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.FirewallRuleShouldExistAndDoesNotMessage) -f $Name
                ) -join '')

            # Set any default parameter values
            if (-not $DisplayName) {
                if (-not $PSBoundParameters.ContainsKey('DisplayName')) {
                    $null = $PSBoundParameters.Add('DisplayName',$Name)
                } else {
                    $PSBoundParameters.DisplayName = $Name
                }
            }


            # Add the new Firewall rule based on specified parameters
            New-NetFirewallRule @PSBoundParameters
        }
    }
    else
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.FirewallRuleShouldNotExistMessage) -f $Name,$Ensure
            ) -join '')

        if ($exists)
        {           
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.FirewallRuleShouldNotExistButDoesMessage) -f $Name
                ) -join '')

            # Remove the existing Firewall rule
            Remove-NetFirewallRule -Name $Name
        }
        else
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.FirewallRuleShouldNotExistAndDoesNotMessage) -f $Name
                ) -join '')
            # Do Nothing
        }
    }
}

######################################################################################
# The Test-TargetResource cmdlet.
# DSC uses Test-TargetResource cmdlet to check the status of the resource instance on
# the target machine
######################################################################################
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
        [String] $DisplayName,

        # Name of the Firewall Group where we want to put the Firewall Rules
        [ValidateNotNullOrEmpty()]
        [String] $DisplayGroup,

        # Ensure the presence/absence of the resource
        [ValidateSet('Present', 'Absent')]
        [String] $Ensure = 'Present',

        # Enable or disable the supplied configuration
        [ValidateSet('True', 'False')]
        [String] $Enabled,

        [ValidateSet('NotConfigured', 'Allow', 'Block')]
        [String] $Action,

        # Specifies one or more profiles to which the rule is assigned
        [String[]] $Profile,

        # Direction of the connection
        [ValidateSet('Inbound', 'Outbound')]
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

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.CheckingFirewallRuleMessage) -f $Name
        ) -join '')

    # Remove any parameters not used in Splats
    $null = $PSBoundParameters.Remove('Ensure')

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.FindFirewallRuleMessage) -f $Name
        ) -join '')
    $firewallRule = Get-FirewallRule -Name $Name

    $exists = ($firewallRule -ne $null)

    if (-not $exists)
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.FirewallRuleDoesNotExistMessage) -f $Name
            ) -join '')

        # Returns whether complies with $Ensure
        $returnValue = ($false -eq ($Ensure -eq 'Present'))

        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.CheckingFirewallReturningMessage) -f $Name,$returnValue
            ) -join '')

        return $returnValue
    }

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.CheckingFirewallParametersMessage) -f $Name
        ) -join '')
    $desiredConfigurationMatch = Test-RuleProperties -FirewallRule $firewallRule @PSBoundParameters

    # Returns whether or not $exists complies with $Ensure
    $returnValue = ($desiredConfigurationMatch -and $exists -eq ($Ensure -eq 'Present'))

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.CheckingFirewallReturningMessage) -f $Name,$returnValue
        ) -join '')

    return $returnValue
}

#region HelperFunctions

######################
## Helper Functions ##
######################

######################################################################################
# Function to validate if the supplied Rule adheres to all parameters set
######################################################################################
function Test-RuleProperties
{
    param (
        [Parameter(Mandatory)]
        $FirewallRule,
        [String] $Name,
        [String] $DisplayName = $Name,
        [String] $DisplayGroup,
        [String] $Group,
        [String] $Enabled = 'True',
        [string] $Action = 'Allow',
        [String[]] $Profile = 'Any',
        [String] $Direction = 'Inbound',
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
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.PropertyNoMatchMessage) -f 'Name',$FirewallRule.Name,$Name
            ) -join '')
        $desiredConfigurationMatch = $false
    }

    if ($Enabled -and ($FirewallRule.Enabled.ToString() -ne $Enabled))
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.PropertyNoMatchMessage) -f 'Enabled',$FirewallRule.Enabled.ToString(),$Enabled
            ) -join '')
        $desiredConfigurationMatch = $false
    }

    if ($Action -and ($FirewallRule.Action -ne $Action))
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.PropertyNoMatchMessage) -f 'Action',$FirewallRule.Action,$Action
            ) -join '')
        $desiredConfigurationMatch = $false
    }

    if ($Profile)
    {
        [String[]] $networkProfileinRule = $FirewallRule.Profile.ToString() -replace(' ', '') -split(',')

        if ($networkProfileinRule.Count -eq $Profile.Count)
        {
            foreach($networkProfile in $Profile)
            {
                if (-not ($networkProfileinRule -contains $networkProfile))
                {
                    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                        $($LocalizedData.PropertyNoMatchMessage) -f 'Profile',$networkProfileinRule,$Profile
                        ) -join '')
                    $desiredConfigurationMatch = $false
                    break
                }
            }
        }
        else
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.PropertyNoMatchMessage) -f 'Profile',$networkProfileinRule,$Profile
                ) -join '')
            $desiredConfigurationMatch = $false
        }
    }

    if ($Direction -and ($FirewallRule.Direction -ne $Direction))
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.PropertyNoMatchMessage) -f 'Direction',$FirewallRule.Direction,$Direction
            ) -join '')
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
                    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                        $($LocalizedData.PropertyNoMatchMessage) -f 'RemotePort',$remotePortInRule,$RemotePort
                        ) -join '')
                    $desiredConfigurationMatch = $false
                }
            }
        }
        else
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.PropertyNoMatchMessage) -f 'RemotePort',$remotePortInRule,$RemotePort
                ) -join '')
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
                    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                        $($LocalizedData.PropertyNoMatchMessage) -f 'LocalPort',$localPortInRule,$LocalPort
                        ) -join '')
                    $desiredConfigurationMatch = $false
                }
            }
        }
        else
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.PropertyNoMatchMessage) -f 'LocalPort',$localPortInRule,$LocalPort
                ) -join '')
            $desiredConfigurationMatch = $false
        }
    }

    if ($Protocol -and ($properties.PortFilters.Protocol -ne $Protocol))
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.PropertyNoMatchMessage) -f 'Protocol',$properties.PortFilters.Protocol,$Protocol
            ) -join '')
        $desiredConfigurationMatch = $false
    }

    if ($Description -and ($FirewallRule.Description -ne $Description))
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.PropertyNoMatchMessage) -f 'Description',$FirewallRule.Description,$Description
            ) -join '')
        $desiredConfigurationMatch = $false
    }

    if ($ApplicationPath -and ($properties.ApplicationFilters.Program -ne $ApplicationPath))
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.PropertyNoMatchMessage) -f 'ApplicationPath',$properties.ApplicationFilters.Program,$ApplicationPath
            ) -join '')
        $desiredConfigurationMatch = $false
    }

    if ($Service -and ($properties.ServiceFilters.Service -ne $Service))
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.PropertyNoMatchMessage) -f 'Service',$properties.ServiceFilters.Service,$Service
            ) -join '')
        $desiredConfigurationMatch = $false
    }

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.TestFirewallRuleReturningMessage) -f $Name,$desiredConfigurationMatch
        ) -join '')
    return $desiredConfigurationMatch
}

######################################################################################
# Returns a list of FirewallRules that comply to the specified parameters.
######################################################################################
function Get-FirewallRule
{
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )

    $firewallRule = @(Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue)

    if (-not $firewallRule)
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.FirewallRuleNotFoundMessage) -f $Name
            ) -join '')
        return $null
    }
    # If more than one rule is returned for a name, then throw an exception
    # because this should not be possible.
    if ($firewallRule.Count -gt 1) {
        $errorId = 'RuleNotUnique'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
        $errorMessage = $($LocalizedData.RuleNotUniqueError) -f $firewallRule.Count,$Name
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    return $firewallRule
}

######################################################################################
# Returns the filters associated with the given firewall rule
######################################################################################
function Get-FirewallRuleProperty
{
    param (
        [Parameter(Mandatory)]
        $FirewallRule
     )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.GetAllPropertiesMessage)
        ) -join '')
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
