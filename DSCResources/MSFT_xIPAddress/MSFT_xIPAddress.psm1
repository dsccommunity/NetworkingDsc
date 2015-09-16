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

    $returnValue = @{
        IPAddress = [System.String]::Join(", ",(Get-NetIPAddress -InterfaceAlias $InterfaceAlias `
            -AddressFamily $AddressFamily).IPAddress)
        SubnetMask = $SubnetMask
        AddressFamily = $AddressFamily
        InterfaceAlias=$InterfaceAlias
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

    ValidateProperties @PSBoundParameters -Apply
}

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

    ValidateProperties @PSBoundParameters
}

#######################################################################################
#  Helper function that validates the IP Address properties. If the switch parameter
# "Apply" is set, then it will set the properties after a test
#######################################################################################
function ValidateProperties
{
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
        [String]$AddressFamily = "IPv4",

        [Switch]$Apply
    )

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
            throw "Server address $IPAddress is in IPv4 format, which does not match server address family $AddressFamily. Please correct either of them in the configuration and try again"
        }
    }
    else
    {
        if ($AddressFamily -ne "IPv6")
        {
            throw "Server address $IPAddress is in IPv6 format, which does not match server address family $AddressFamily. Please correct either of them in the configuration and try again"
        }
    }

    try
    {
        # Flag to signal whether settings are correct
        $requiresChanges = $false

        Write-Verbose -Message "Checking the IPAddress ..."
        # Get the current IP Address based on the parameters given.
        $currentIP = Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily `
            $AddressFamily -ErrorAction Stop

        # Test if the IP Address passed is present
        if(-not $currentIP.IPAddress.Contains($IPAddress))
        {
            Write-Verbose -Message ( @(
                "IPAddress does NOT match desired state. Expected $IPAddress, actual "
                "$($currentIP.IPAddress)."
                ) -join ""
            )
            $requiresChanges = $true
        }
        else
        {
            Write-Verbose -Message "IPAddress is correct."

            # Filter the IP addresses for the IP address to check
            $filterIP = $currentIP | where { $_.IPAddress -eq $IPAddress }

            # Only test the Subnet Mask if the IP address is present
            if(-not $filterIP.PrefixLength.Equals([byte]$SubnetMask))
            {
                Write-Verbose -Message ( @(
                    "Subnet mask does NOT match desired state. Expected $SubnetMask, actual "
                    "$($filterIP.PrefixLength)."
                    ) -join ""
                )
                $requiresChanges = $true
            }
            else
            {
                Write-Verbose -Message "Subnet mask is correct."
            }
        }

        # Test if DHCP is already disabled
        if(-not (Get-NetIPInterface -InterfaceAlias $InterfaceAlias -AddressFamily `
            $AddressFamily).Dhcp.ToString().Equals('Disabled'))
        {
            Write-Verbose -Message "DHCP is NOT disabled."
            $requiresChanges = $true
        }
        else
        {
            Write-Verbose -Message "DHCP is already disabled."
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

                # Build parameter hash table
                $Parameters = @{
                    IPAddress = $IPAddress
                    PrefixLength = $SubnetMask
                    InterfaceAlias = $InterfaceAlias
                }

                # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
                $DestinationPrefix = "0.0.0.0/0"
                if($AddressFamily -eq "IPv6")
                {
                    $DestinationPrefix = "::/0"
                }

                # Get all the default routes - this has to be done in case the IP Address is
                # beng Removed
                $defaultRoutes = Get-NetRoute -InterfaceAlias $InterfaceAlias -AddressFamily `
                    $AddressFamily -ErrorAction Stop | `
                    where { $_.DestinationPrefix -eq $DestinationPrefix }

                # Remove any default routes on the specified interface -- it is important to do
                # this *before* removing the IP address, particularly in the case where the IP
                # address was auto-configured by DHCP
                if($defaultRoutes)
                {
                    $defaultRoutes | Remove-NetRoute -confirm:$false -ErrorAction Stop
                }

                # Remove any IP addresses on the specified interface
                if($currentIP)
                {
                    $currentIP | Remove-NetIPAddress -confirm:$false -ErrorAction Stop
                }

                # Apply the specified IP configuration
                $null = New-NetIPAddress @Parameters -ErrorAction Stop

                # Make the connection profile private
                Get-NetConnectionProfile -InterfaceAlias $InterfaceAlias | `
                    Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue
                Write-Verbose -Message "IP Interface was set to the desired state."
            }
            else
            {
                return $false
            }
        }
        else
        {
            Write-Verbose -Message "IP interface is in the desired state."
            return $true
        }
    }
    catch
    {
        Write-Error -Message ( @(
            "Can not set or find valid IPAddress using InterfaceAlias $InterfaceAlias and "
            "AddressFamily $AddressFamily"
            ) -join ""
        )
        throw $_.Exception
    }
}

#  FUNCTIONS TO BE EXPORTED
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
