#######################################################################################
#  xIPAddress : DSC Resource that will set/test/get the current IP
#  Address, by accepting values among those given in xIPAddress.schema.mof
#######################################################################################

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
GettingIPAddressMessage=Getting the IP Address.
ApplyingIPAddressMessage=Applying the IP Address.
IPAddressSetStateMessage=IP Interface was set to the desired state.
CheckingIPAddressMessage=Checking the IP Address.
IPAddressDoesNotMatchMessage=IP Address does NOT match desired state. Expected {0}, actual {1}.
IPAddressMatchMessage=IP Address is in desired state.
SubnetMaskDoesNotMatchMessage=Subnet mask does NOT match desired state. Expected {0}, actual {1}.
SubnetMaskMatchMessage=Subnet mask is in desired state.
DHCPIsNotDisabledMessage=DHCP is NOT disabled.
DHCPIsAlreadyDisabledMessage=DHCP is already disabled.
InterfaceNotAvailableError=Interface "{0}" is not available. Please select a valid interface and try again.
AddressFormatError=Address "{0}" is not in the correct format. Please correct the Address parameter in the configuration and try again.
AddressIPv4MismatchError=Address "{0}" is in IPv4 format, which does not match server address family {1}. Please correct either of them in the configuration and try again.
AddressIPv6MismatchError=Address "{0}" is in IPv6 format, which does not match server address family {1}. Please correct either of them in the configuration and try again.
SubnetMaskError=A Subnet Mask of {0} is not valid for {1} addresses. Please correct the subnet mask and try again.
'@
}

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

        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily = 'IPv4'
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingIPAddressMessage)
        ) -join '')

    $CurrentIPAddress = Get-NetIPAddress `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily

    $returnValue = @{
        IPAddress      = [System.String]::Join(', ',$CurrentIPAddress.IPAddress)
        SubnetMask     = [System.String]::Join(', ',$CurrentIPAddress.PrefixLength)
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

        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily = 'IPv4'
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.ApplyingIPAddressMessage)
        ) -join '')

    # Use $AddressFamily to select the IPv4 or IPv6 destination prefix
    $DestinationPrefix = '0.0.0.0/0'
    if ($AddressFamily -eq 'IPv6')
    {
        $DestinationPrefix = '::/0'
    }

    # Get all the default routes - this has to be done in case the IP Address is
    # beng Removed
    $defaultRoutes = @(Get-NetRoute `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily `
        -ErrorAction Stop).Where( { $_.DestinationPrefix -eq $DestinationPrefix } )

    # Remove any default routes on the specified interface -- it is important to do
    # this *before* removing the IP address, particularly in the case where the IP
    # address was auto-configured by DHCP
    if ($defaultRoutes)
    {
        foreach ($defaultRoute in $defaultRoutes) {
            Remove-NetRoute `
                -DestinationPrefix $defaultRoute.DestinationPrefix `
                -NextHop $defaultRoute.NextHop `
                -InterfaceIndex $defaultRoute.InterfaceIndex `
                -AddressFamily $defaultRoute.AddressFamily `
                -Confirm:$false `
                -ErrorAction Stop
        }
    }

    # Get the current IP Address based on the parameters given.
    $currentIPs = @(Get-NetIPAddress `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily `
        -ErrorAction Stop)

    # Remove any IP addresses on the specified interface
    if ($currentIPs)
    {
        foreach ($CurrentIP in $CurrentIPs) {
            Remove-NetIPAddress `
                -IPAddress $CurrentIP.IPAddress `
                -InterfaceIndex $CurrentIP.InterfaceIndex `
                -AddressFamily $CurrentIP.AddressFamily `
                -Confirm:$false `
                -ErrorAction Stop
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

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.IPAddressSetStateMessage)
        ) -join '' )
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

        [uInt32]$SubnetMask = 16,

        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily = 'IPv4'
    )

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.CheckingIPAddressMessage)
        ) -join '')

    Test-ResourceProperty @PSBoundParameters

    # Get the current IP Address based on the parameters given.
    $currentIPs = @(Get-NetIPAddress `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily `
        -ErrorAction Stop)

    # Test if the IP Address passed is present
    if (-not $currentIPs.IPAddress.Contains($IPAddress))
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.IPAddressDoesNotMatchMessage) -f $IPAddress,$currentIPs.IPAddress
            ) -join '' )
        $desiredConfigurationMatch = $false
    }
    else
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.IPAddressMatchMessage)
            ) -join '')

        # Filter the IP addresses for the IP address to check
        $filterIP = $currentIPs.Where( { $_.IPAddress -eq $IPAddress } )

        # Only test the Subnet Mask if the IP address is present
        if (-not $filterIP.PrefixLength.Equals([byte]$SubnetMask))
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.SubnetMaskDoesNotMatchMessage) -f $SubnetMask,$currentIPs.PrefixLength
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($LocalizedData.SubnetMaskMatchMessage)
                ) -join '' )
        }
    }

    # Test if DHCP is already disabled
    if (-not (Get-NetIPInterface `
        -InterfaceAlias $InterfaceAlias `
        -AddressFamily $AddressFamily).Dhcp.ToString().Equals('Disabled'))
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.DHCPIsNotDisabledMessage)
            ) -join '' )
        $desiredConfigurationMatch = $false
    }
    else
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.DHCPIsAlreadyDisabledMessage)
            ) -join '' )
    }
    return $desiredConfigurationMatch
} # Test-TargetResource

#######################################################################################
#  Helper functions
#######################################################################################
function Test-ResourceProperty {
    # Function will check the IP Address details are valid and do not conflict with
    # Address family. Also checks the subnet mask and ensures the interface exists.
    # If any problems are detected an exception will be thrown.
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$IPAddress,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [uInt32]$SubnetMask = 16,

        [ValidateSet('IPv4', 'IPv6')]
        [String]$AddressFamily = 'IPv4'
    )

    if (-not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
        $errorId = 'InterfaceNotAvailable'
        $errorCategory = [System.Management.Automation.ErrorCategory]::DeviceError
        $errorMessage = $($LocalizedData.InterfaceNotAvailableError) -f $InterfaceAlias
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }
    if (-not ([System.Net.Ipaddress]::TryParse($IPAddress, [ref]0)))
    {
        $errorId = 'AddressFormatError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.AddressFormatError) -f $IPAddress
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    $detectedAddressFamily = ([System.Net.IPAddress]$IPAddress).AddressFamily.ToString()
    if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString()) `
        -and ($AddressFamily -ne 'IPv4'))
    {
        $errorId = 'AddressMismatchError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.AddressIPv4MismatchError) -f $IPAddress,$AddressFamily
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6.ToString()) `
        -and ($AddressFamily -ne 'IPv6'))
    {
        $errorId = 'AddressMismatchError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.AddressIPv6MismatchError) -f $IPAddress,$AddressFamily
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    if ((
            ($AddressFamily -eq 'IPv4') `
                -and (($SubnetMask -lt [uint32]0) -or ($SubnetMask -gt [uint32]32))
            ) -or (
            ($AddressFamily -eq 'IPv6') `
                -and (($SubnetMask -lt [uint32]0) -or ($SubnetMask -gt [uint32]128))
        ))
    {
        $errorId = 'SubnetMaskError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.SubnetMaskError) -f $SubnetMask,$AddressFamily
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

} # Test-ResourceProperty
#######################################################################################

#  FUNCTIONS TO BE EXPORTED
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
