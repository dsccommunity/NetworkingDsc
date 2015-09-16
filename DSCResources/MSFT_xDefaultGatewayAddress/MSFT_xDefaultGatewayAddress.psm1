<#######################################################################################
 #  xDefaultGatewayAddress : DSC Resource that will set/test/get the current default gateway
 #  Address, by accepting values among those given in xDefaultGatewayAddress.schema.mof
 #######################################################################################>



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
        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily
    )
    
    # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
    $DestinationPrefix = "0.0.0.0/0"
    if($AddressFamily -eq "IPv6")
    {
        $DestinationPrefix = "::/0"
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
        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily
    )

    Test-Properties @PSBoundParameters -Apply
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
        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily
    )

    Test-Properties @PSBoundParameters
}


#######################################################################################
#  Helper function that validates the Gateway Address property. If the switch parameter
# "Apply" is set, then it will set the properties after a test
#######################################################################################
function Test-Properties
{
    param
    (
        [String]$Address,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [Parameter(Mandatory)]
        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily,

        [Switch]$Apply
    )
    # Validate the parameters
    
    If ($Address) {
        if(!([System.Net.Ipaddress]::TryParse($Address, [ref]0)))
             {
                 throw "Address *$Address* is not in the correct format. Please correct the Address in the configuration and try again"
             }
             if (([System.Net.IPAddress]$Address).AddressFamily.ToString() -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString())
             {
                if ($AddressFamily -ne "IPv4")
                {
                    throw "Server address $Address is in IPv4 format, which does not match server address family $AddressFamily. Please correct either of them in the configuration and try again"
                }
             }
             else
             {
                if ($AddressFamily -ne "IPv6")
                {
                    throw "Server address $Address is in IPv6 format, which does not match server address family $AddressFamily. Please correct either of them in the configuration and try again"
                }
             }
         }
    try
    {        
        # Flag to signal whether settings are correct
        $requiresChanges = $false

        Write-Verbose -Message "Checking the Default Gateway Address ..."

        # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
        $DestinationPrefix = "0.0.0.0/0"
        if($AddressFamily -eq "IPv6")
        {
            $DestinationPrefix = "::/0"
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
                    Write-Verbose -Message ( @(
                        "Default gateway does NOT match desired state. Expected $Address, "
                        "actual $($defaultRoutes.NextHop)."
                        ) -join ""
                    )
                    $requiresChanges = $true
                }
                else
                {
                    Write-Verbose -Message "Default gateway is correct."
                }
            }
            else
            {
                Write-Verbose -Message "Default gateway does not exist. Expected $Address ."
                $requiresChanges = $true
            }
        }
        else
        {
            # Is a default gateway address set?
            if ($defaultRoutes)
            {
                Write-Verbose -Message "Default gateway exists but it should not."
                $requiresChanges = $true
            }
            else
            {
                Write-Verbose -Message "Default Gateway does not exist which is correct."
            }
        }

        if($requiresChanges)
        {
            # Apply is true in the case of set - target resource - in which case, it will apply the
            # required IP configuration
            if($Apply)
            {
                Write-Verbose -Message ( @(
                    "At least one setting differs from the passed parameters. Applying "
                    "configuration..."
                    ) -join ""
                )

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
                }

                Write-Verbose -Message "Default Gateway address was set to the desired state."
                return $true
            }
            else
            {
                return $false
            }
        }
        else
        {
            Write-Verbose -Message "Default Gateway address is in the desired state."
            return $true
        }

    }
    catch
    {
        Write-Verbose -Message ( @(
            "Can not set or find valid Default Gateway address using InterfaceAlias $InterfaceAlias and "
            "AddressFamily $AddressFamily"
            ) -join ""
        )
        throw $_.Exception
    }
}



#  FUNCTIONS TO BE EXPORTED 
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
