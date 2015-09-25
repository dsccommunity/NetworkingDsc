#######################################################################################
#  xDefaultGatewayAddress : DSC Resource that will set/test/get the current default gateway
#  Address, by accepting values among those given in xDefaultGatewayAddress.schema.mof
#######################################################################################



######################################################################################
# The Get-TargetResource cmdlet.
# This function will get the current Default Gateway Address
######################################################################################
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (        
        [String]$Address,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [Parameter(Mandatory)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily
    )
    
    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        'Getting the Default Gateway Address ...'
        ) -join '' )
    
    # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
    $DestinationPrefix = '0.0.0.0/0'
    if($AddressFamily -eq 'IPv6')
    {
        $DestinationPrefix = '::/0'
    }
    # Get all the default routes
    $defaultRoutes = Get-NetRoute -InterfaceAlias $InterfaceAlias -AddressFamily `
        $AddressFamily -ErrorAction Stop | `
        where-Object { $_.DestinationPrefix -eq $DestinationPrefix }

    $returnValue = @{
        AddressFamily = $AddressFamily
        InterfaceAlias = $InterfaceAlias
    }
    # If there is a Default Gateway defined for this interface/address family add it
    # to the return value.
    if ($defaultRoutes) {
        $returnValue += @{ Address = $DefaultRoutes.NextHop }
    }

    $returnValue
}

######################################################################################
# The Set-TargetResource cmdlet.
# This function will set the Default Gateway Address for the Interface/Family in the
# current node
######################################################################################
function Set-TargetResource
{
    param
    (
        [String]$Address,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [Parameter(Mandatory)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily
    )
    # Validate the parameters
    
    try
    {        
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            'Applying the Default Gateway Address ...'
            ) -join '' )

        #Should not need to validate the settings because Test-TargetResource already did this

        # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
        $DestinationPrefix = '0.0.0.0/0'
        if($AddressFamily -eq 'IPv6')
        {
            $DestinationPrefix = '::/0'
        }

        # Get all the default routes
        $defaultRoutes = @(Get-NetRoute `
            -InterfaceAlias $InterfaceAlias `
            -AddressFamily $AddressFamily `
            -ErrorAction Stop).Where( { $_.DestinationPrefix -eq $DestinationPrefix } )

        # Remove any existing default route
        foreach ($defaultRoute in $defaultRoutes) {
            Remove-NetRoute `
                -DestinationPrefix $defaultRoute.DestinationPrefix `
                -NextHop $defaultRoute.NextHop `
                -InterfaceIndex $defaultRoute.InterfaceIndex `
                -AddressFamily $defaultRoute.AddressFamily `
                -Confirm:$false -ErrorAction Stop
        }

        if ($Address)
        {
            # Set the correct Default Route
            # Build parameter hash table
            $parameters = @{
                DestinationPrefix = $DestinationPrefix
                InterfaceAlias = $InterfaceAlias
                AddressFamily = $AddressFamily
                NextHop = $Address
            }
            New-NetRoute @Parameters
            Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                'Default Gateway address was set to the desired state.'
                ) -join '' )
        }
        else
        {
            Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                'Default Gateway address has been removed.'
                ) -join '' )
        }
    }
    catch
    {
        Write-Verbose -Message (@("$($MyInvocation.MyCommand): "
            'Error setting valid Default Gateway address using InterfaceAlias $InterfaceAlias and '
            'AddressFamily $AddressFamily'
            ) -join '')
        throw $_.Exception
    }
}

######################################################################################
# The Test-TargetResource cmdlet.
# This will test if the given Address is set as the Gateway Server address for the
# Interface/Family in the current node
######################################################################################
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [String]$Address,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [Parameter(Mandatory)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily
    )
    # Flag to signal whether settings are correct
    [Boolean]$requiresChanges = $false

    try
    {        
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            'Checking the Default Gateway Address ...'
            ) -join '' )

        Test-ResourceProperty @PSBoundParameters

        # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
        $DestinationPrefix = '0.0.0.0/0'
        if($AddressFamily -eq 'IPv6')
        {
            $DestinationPrefix = '::/0'
        }
        # Get all the default routes
        $defaultRoutes = @(Get-NetRoute `
            -InterfaceAlias $InterfaceAlias `
            -AddressFamily $AddressFamily `
            -ErrorAction Stop).Where( { $_.DestinationPrefix -eq $DestinationPrefix } )

        # Test if the Default Gateway passed is equal to the current default gateway
        if($Address)
        {
            if($defaultRoutes) {
                if(-not $defaultRoutes.Where( { $_.NextHop -eq $Address } ))
                {
                    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                        "Default gateway does NOT match desired state. Expected $Address, "
                        "actual $($defaultRoutes.NextHop)."
                        ) -join '' )
                    $requiresChanges = $true
                }
                else
                {
                    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                        'Default gateway is correct.'
                        ) -join '' )
                }
            }
            else
            {
                Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                    "Default gateway does not exist. Expected $Address."
                    ) -join '' )
                $requiresChanges = $true
            }
        }
        else
        {
            # Is a default gateway address set?
            if ($defaultRoutes)
            {
                Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                    'Default gateway exists but it should not.'
                    ) -join '' )
                $requiresChanges = $true
            }
            else
            {
                Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                    'Default Gateway does not exist which is correct.'
                    ) -join '' )
            }
        }
    }
    catch
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            'Error testing valid Default Gateway address using InterfaceAlias $InterfaceAlias '
            "and AddressFamily $AddressFamily"
            ) -join '' )
        throw $_.Exception
    }
    return -not $requiresChanges
}

#######################################################################################
#  Helper functions
#######################################################################################
function Test-ResourceProperty {
    # Function will check the Address details are valid and do not conflict with
    # Address family. Ensures interface exists.
    # If any problems are detected an exception will be thrown.
    [CmdLetBinding()]
    param
    (
        [String]$Address,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily = 'IPv4'
    )

    if(-not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
                throw ( @(
                    "Interface $InterfaceAlias is not available. "
                    'Please select a valid interface and try again'
                    ) -join '')
    }
    if ($Address)
    {
        if(-not ([System.Net.Ipaddress]::TryParse($Address, [ref]0)))
        {
                throw ( @(
                    "Address $Address is not in the correct format. Please correct the Address "
                    'parameter in the configuration and try again.'
                    ) -join '' )
        }
        if (([System.Net.IPAddress]$Address).AddressFamily.ToString() `
            -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString())
        {
            if ($AddressFamily -ne 'IPv4')
            {
                throw ( @(
                        "Address $Address is in IPv4 format, which does not match server address "
                        "family $AddressFamily. "
                        'Please correct either of them in the configuration and try again.'
                    ) -join '' )
            }
        }
        else
        {
            if ($AddressFamily -ne 'IPv6')
            {
                throw ( @(
                        "Address $Address is in IPv6 format, which does not match server address "
                        "family $AddressFamily. "
                        'Please correct either of them in the configuration and try again'
                    ) -join '' )
            }
        }
    }
} # Test-ResourceProperty
#######################################################################################

#  FUNCTIONS TO BE EXPORTED 
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
