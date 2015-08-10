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

        [ValidateNotNullOrEmpty()]
        [String]$DefaultGateway,

        [ValidateSet("IPv4", "IPv6")]
        [String]$AddressFamily = "IPv4"
    )

    $returnValue = @{
        IPAddress = [System.String]::Join(", ",(Get-NetIPAddress -InterfaceAlias $InterfaceAlias `
            -AddressFamily $AddressFamily).IPAddress)
        SubnetMask = $SubnetMask
        DefaultGateway = $DefaultGateway
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

        [ValidateNotNullOrEmpty()]
        [String]$DefaultGateway,

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

        [ValidateNotNullOrEmpty()]
        [String]$DefaultGateway,

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

        [ValidateNotNullOrEmpty()]
        [String]$DefaultGateway,

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

    try
    {
        Write-Verbose -Message "Checking the IPAddress ..."
        #Get the current IP Address based on the parameters given.
        $currentIP = Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily `
            $AddressFamily -ErrorAction Stop

        # Build hash table of current settings
        $currentSettings = @{
            IPAddress = $currentIP.IPAddress
            PrefixLength = $currentIP.PrefixLength
            InterfaceAlias = $currentIP.InterfaceAlias
        }

        # Flag to signal whether settings are correct
        $requiresChanges = $false

        #Test if the IP Address passed is equal to the current ip address
        if(-not $currentSettings['IPAddress'].Contains($IPAddress))
        {
            Write-Verbose -Message ( @(
                "IPAddress does NOT match desired state. Expected $IPAddress, actual "
                "$($currentSettings['IPAddress'])."
                ) -join ""
            )
            $requiresChanges = $true
        }
        else
        {
            Write-Verbose -Message "IPAddress is correct."
        }

        #Test if the Subnet Mask passed is equal to the current subnet mask
        if(-not $currentSettings['PrefixLength'].Equals([byte]$SubnetMask))
        {
            Write-Verbose -Message ( @(
                "Subnet mask does NOT match desired state. Expected $SubnetMask, actual "
                "$($currentSettings['PrefixLength'])."
                ) -join ""
            )
            $requiresChanges = $true
        }
        else
        {
            Write-Verbose -Message "Subnet mask is correct."
        }

        #Test if the Default Gateway passed is equal to the current default gateway
        if($DefaultGateway)
        {
            if(-not ([System.Net.Ipaddress]::TryParse($DefaultGateway, [ref]0)))
            {
                throw ( @(
                    "Default Gateway *$DefaultGateway* is NOT in the correct format. Please "
                    "correct the DefaultGateway parameter in the configuration and try again."
                    ) -join ""
                )
            }

            $netIpConf = Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias -ErrorAction Stop

            # Use the $AddressFamily parameter to get the NextHop value from either the
            # "IPv4Gateway" or "IPv6Gateway" property.
            $defaultGatewayProperty = "$($AddressFamily)DefaultGateway"
            $currentSettings['DefaultGateway'] = ($netIpConf."$defaultGatewayProperty").NextHop

            if(-not ($currentSettings['DefaultGateway'] -eq $DefaultGateway))
            {
                Write-Verbose -Message ( @(
                    "Default gateway does NOT match desired state. Expected $DefaultGateway, "
                    "actual $($currentSettings['DefaultGateway'])."
                    ) -join ""
                )
                $requiresChanges = $true
            }
            else
            {
                Write-Verbose -Message "Default gateway is correct."
            }
        }

        #Test if DHCP is already disabled
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
                    InterfaceAlias = $currentIP[0].InterfaceAlias
                }
                if($DefaultGateway)
                {
                    $Parameters['DefaultGateway'] = $DefaultGateway
                }

                # If null, remove the gateway from the current settings hash table
                if($currentSettings['DefaultGateway'] -eq $null)
                {
                    $currentSettings.remove('DefaultGateway')
                }

                # Remove IP address first; required if the IP is correct but other settings are not
                Remove-NetIPAddress @currentSettings -confirm:$false -ErrorAction Stop

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
            Write-Verbose -Message "IP Interface is in the desired state."
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
