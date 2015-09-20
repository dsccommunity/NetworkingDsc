<#######################################################################################
 #  MSDSCPack_IPAddress : DSC Resource that will set/test/get the current IP
 #  Address, by accepting values among those given in MSDSCPack_IPAddress.schema.mof
 #######################################################################################>

######################################################################################
# The Get-TargetResource cmdlet.
# This function will get the present list of IP Address DSC Resource schema variables on the system
######################################################################################
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$IPAddress,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [uInt32]$SubnetMask = 16,

        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily = "IPv4"
    )

    Write-Verbose -Message "GET: Applying the IP Address..."

    $CurrentIPAddress = Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily $AddressFamily

    $returnValue = @{
        IPAddress      = [System.String]::Join(", ",$CurrentIPAddress.IPAddress)
        SubnetMask     = [System.String]::Join(", ",$CurrentIPAddress.PrefixLength)
        AddressFamily  = $AddressFamily
        InterfaceAlias = $InterfaceAlias
    }

    $returnValue
}

######################################################################################
# The Set-TargetResource cmdlet.
# This function will set a new IP Address in the current node
######################################################################################
function Set-TargetResource
{
    param
    (
        #IP Address that has to be set
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$IPAddress,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [uInt32]$SubnetMask,

        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily = "IPv4"
    )

    try
    {
        Validate-ResourceProperty @PSBoundParameters

        Write-Verbose -Message "SET: Applying the IP Address..."

        # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
        $DestinationPrefix = "0.0.0.0/0"
        if($AddressFamily -eq "IPv6")
        {
            $DestinationPrefix = "::/0"
        }

        # Get all the default routes - this has to be done in case the IP Address is
        # beng Removed
        $defaultRoutes = @(Get-NetRoute -InterfaceAlias `
            $InterfaceAlias -AddressFamily `
            $AddressFamily -ErrorAction Stop).Where( { $_.DestinationPrefix -eq $DestinationPrefix } )

        # Remove any default routes on the specified interface -- it is important to do
        # this *before* removing the IP address, particularly in the case where the IP
        # address was auto-configured by DHCP
        if($defaultRoutes)
        {
            foreach ($defaultRoute in $defaultRoutes) {
                Remove-NetRoute `
                    -DestinationPrefix $defaultRoute.DestinationPrefix `
                    -NextHop $defaultRoute.NextHop `
                    -InterfaceIndex $defaultRoute.InterfaceIndex `
                    -AddressFamily $defaultRoute.AddressFamily `
                    -Confirm:$false -ErrorAction Stop
            }
        }

        # Get the current IP Address based on the parameters given.
        $currentIPs = @(Get-NetIPAddress `
            -InterfaceAlias $InterfaceAlias `
            -AddressFamily $AddressFamily `
            -ErrorAction Stop)

        # Remove any IP addresses on the specified interface
        if($currentIPs)
        {
            foreach ($CurrentIP in $CurrentIPs) {
                Remove-NetIPAddress `
                    -IPAddress $CurrentIP.IPAddress `
                    -InterfaceIndex $CurrentIP.InterfaceIndex `
                    -AddressFamily $CurrentIP.AddressFamily `
                    -Confirm:$false -ErrorAction Stop
            }
        }

        # Build parameter hash table
        $Parameters = @{
            IPAddress = $IPAddress
            PrefixLength = $SubnetMask
            InterfaceAlias = $InterfaceAlias
        }

        # Apply the specified IP configuration
        $null = New-NetIPAddress @Parameters -ErrorAction Stop

        # Make the connection profile private
        Get-NetConnectionProfile -InterfaceAlias $InterfaceAlias | `
            Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue
        Write-Verbose -Message "SET: IP Interface was set to the desired state."
    }
    catch
    {
        Write-Verbose -Message ( @(
            "SET: Error setting IP Address using InterfaceAlias $InterfaceAlias and "
            "AddressFamily $AddressFamily"
            ) -join ""
        )
        throw $_.Exception
    }
} # Set-TargetResource

######################################################################################
# The Test-TargetResource cmdlet.
# This will test if the given IP Address is among the current node's IP Address collection
######################################################################################
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$IPAddress,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [uInt32]$SubnetMask,

        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily = "IPv4"
    )

    # Flag to signal whether settings are correct
    [Boolean]$requiresChanges = $false
    try
    {
        Write-Verbose -Message "TEST: Checking the IP Address ..."

        Validate-ResourceProperty @PSBoundParameters

        # Get the current IP Address based on the parameters given.
        $currentIPs = @(Get-NetIPAddress `
            -InterfaceAlias $InterfaceAlias `
            -AddressFamily $AddressFamily `
            -ErrorAction Stop)

        # Test if the IP Address passed is present
        if(-not $currentIPs.IPAddress.Contains($IPAddress))
        {
            Write-Verbose -Message ( @(
                "TEST: IP Address does NOT match desired state. Expected $IPAddress, "
                "actual $($currentIPs.IPAddress)."
                ) -join ""
            )
            $requiresChanges = $true
        }
        else
        {
            Write-Verbose -Message "TEST: IP Address is correct."

            # Filter the IP addresses for the IP address to check
            $filterIP = $currentIPs.Where( { $_.IPAddress -eq $IPAddress } )

            # Only test the Subnet Mask if the IP address is present
            if(-not $filterIP.PrefixLength.Equals([byte]$SubnetMask))
            {
                Write-Verbose -Message ( @(
                    "TEST: Subnet mask does NOT match desired state. Expected $SubnetMask, "
                    "actual $($filterIP.PrefixLength)."
                    ) -join ""
                )
                $requiresChanges = $true
            }
            else
            {
                Write-Verbose -Message "TEST: Subnet mask is correct."
            }
        }

        # Test if DHCP is already disabled
        if(-not (Get-NetIPInterface -InterfaceAlias $InterfaceAlias -AddressFamily `
            $AddressFamily).Dhcp.ToString().Equals('Disabled'))
        {
            Write-Verbose -Message "TEST: DHCP is NOT disabled."
            $requiresChanges = $true
        }
        else
        {
            Write-Verbose -Message "TEST: DHCP is already disabled."
        }
    } catch {
        Write-Verbose -Message ( @(
            "TEST: Error testing valid IPAddress using InterfaceAlias $InterfaceAlias "
            "and AddressFamily $AddressFamily"
            ) -join ""
        )
        throw $_.Exception
    }
    return -not $requiresChanges
} # Test-TargetResource

#######################################################################################
#  Helper functions
#######################################################################################
function Validate-ResourceProperty {
# Function will check the IP Address details are valid and do not conflict with
# Address family. Also checks the subnet mask and ensures the interface exists.
# If any problems are detected an exception will be thrown.
    [CmdLetBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$IPAddress,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [uInt32]$SubnetMask = 16,

        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily = "IPv4"
    )

    if ((($AddressFamily -eq "IPv4") -and ($SubnetMask -lt 0) -or ($SubnetMask -gt 32)) -or 
        (($AddressFamily -eq "IPv6") -and ($SubnetMask -lt 0) -or ($SubnetMask -gt 128))
        )
    {
            throw  ( @(
                "A Subnet Mask of $SubnetMask is not valid for $AddressFamily addresses. "
                "Please correct the subnet mask and try again."
                ) -join ""
            )
    }
    if(-not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
            throw "Interface $InterfaceAlias is not available. Please select a valid interface and try again"
    }
    if(-not ([System.Net.Ipaddress]::TryParse($IPAddress, [ref]0)))
    {
            throw ( @(
                "IP Address *$IPAddress* is not in the correct format. Please correct the IPAddress "
                "parameter in the configuration and try again."
                ) -join ""
            )
    }
    if (([System.Net.IPAddress]$IPAddress).AddressFamily.ToString() -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString())
    {
        if ($AddressFamily -ne "IPv4")
        {
            throw ( @(
                "Address $IPAddress is in IPv4 format, which does not match server address family $AddressFamily. "
                "Please correct either of them in the configuration and try again."
                ) -join ""
            )
        }
    }
    else
    {
        if ($AddressFamily -ne "IPv6")
        {
            throw ( @(
                "Address $IPAddress is in IPv6 format, which does not match server address family $AddressFamily. "
                "Please correct either of them in the configuration and try again"
                ) -join ""
            )
        }
    }
} # Validate-ResourceProperty
#######################################################################################

#  FUNCTIONS TO BE EXPORTED
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
