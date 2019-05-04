$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
            -ChildPath 'NetworkingDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_NetIPInterface'

<#
    This is an array of all the parameters used by this resource
    It can be used by several of the functions to reduce the amount of code required
    Each element contains 4 properties:
    Name: The parameter name
    Type: This is the content type of the paramater (it is either array or string or blank)
    A blank type means it will not be compared
    MockedValue: This value is used for unit testing and will be used as the value that
    will be returned in mocks.
    TestValue: This value is used for unit testing and will be used to compare with the
    value returned by the mocks.
#>
$script:resourceData = Import-LocalizedData `
    -BaseDirectory $PSScriptRoot `
    -FileName 'MSFT_NetIPInterface.data.psd1'
$script:parameterList = $script:resourceData.ParameterList

<#
    .SYNOPSIS
    Returns the current state of the Network Interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface to configure.

    .PARAMETER AddressFamily
    IP address family on the interface to configure.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingNetIPInterfaceMessage) -f $InterfaceAlias, $AddressFamily
        ) -join '')

    $netIPInterfaceParameters = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily  = $AddressFamily
    }

    $netIPInterface = Get-NetworkIPInterface @netIPInterfaceParameters

    <#
        Populate the properties for get target resource by looping through
        the parameter array list and adding the values to the result array
    #>

    foreach ($parameter in $script:parameterList)
    {
        $parameterName = $parameter.Name
        $parameterValue = $netIPInterface.$($parameter.Name)
        $netIPInterfaceParameters.Add($parameterName, $parameterValue)

        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($script:localizedData.NetIPInterfaceParameterValueMessage) -f `
                    $InterfaceAlias, $AddressFamily, $parameterName, $parameterValue
            ) -join '')
    }

    return $netIPInterfaceParameters
}

<#
    .SYNOPSIS
    Sets the current state of the Network Interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface to configure.

    .PARAMETER AddressFamily
    IP address family on the interface to configure.

    .PARAMETER AdvertiseDefaultRoute
    Specifies the default router advertisement for an interface.

    .PARAMETER Advertising
    Specifies the router advertisement value for the IP interface.

    .PARAMETER AutomaticMetric
    Specifies the value for automatic metric calculation.

    .PARAMETER Dhcp
    Specifies the Dynamic Host Configuration Protocol (DHCP) value for an IP interface.

    .PARAMETER DirectedMacWolPattern
    Specifies the wake-up packet value for an IP interface.

    .PARAMETER EcnMarking
    Specifies the value for Explicit Congestion Notification (ECN) marking.

    .PARAMETER ForceArpNdWolPattern
    Specifies the Wake On LAN (WOL) value for the IP interface.

    .PARAMETER Forwarding
    Specifies the packet forwarding value for the IP interface.

    .PARAMETER IgnoreDefaultRoutes
    Specifies a value for Default Route advertisements.

    .PARAMETER ManagedAddressConfiguration
    Specifies the value for managed address configuration.

    .PARAMETER NeighborUnreachabilityDetection
    Specifies the value for Neighbor Unreachability Detection (NUD).

    .PARAMETER OtherStatefulConfiguration
    Specifies the value for configuration other than addresses.

    .PARAMETER RouterDiscovery
    Specifies the value for router discovery for an IP interface.

    .PARAMETER WeakHostReceive
    Specifies the receive value for a weak host model.

    .PARAMETER WeakHostSend
    Specifies the send value for a weak host model.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $AdvertiseDefaultRoute,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $Advertising,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $AutomaticMetric,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $Dhcp,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $DirectedMacWolPattern,

        [Parameter()]
        [ValidateSet('Disabled', 'UseEct1', 'UseEct0', 'AppDecide')]
        [System.String]
        $EcnMarking,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $ForceArpNdWolPattern,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $Forwarding,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $IgnoreDefaultRoutes,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $ManagedAddressConfiguration,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $NeighborUnreachabilityDetection,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $OtherStatefulConfiguration,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled', 'ControlledByDHCP')]
        [System.String]
        $RouterDiscovery,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $WeakHostReceive,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $WeakHostSend
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($script:localizedData.ApplyingNetIPInterfaceMessage) `
                -f $InterfaceAlias, $AddressFamily
        ) -join '')

    $netIPInterfaceParameters = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily  = $AddressFamily
    }

    $netIPInterface = Get-NetworkIPInterface @netIPInterfaceParameters

    <#
        Loop through each possible property and if it is passed to the resource
        and the current value of the property is different then add it to the
        netIPInterfaceParameters array that will be used to update the
        net IP interface settings.
    #>
    $parameterUpdated = $false
    foreach ($parameter in $script:parameterList)
    {
        $parameterName = $parameter.Name

        if ($PSBoundParameters.ContainsKey($parameterName))
        {
            $parameterValue = $netIPInterface.$($parameterName)
            $parameterNewValue = (Get-Variable -Name ($parameterName)).Value

            if ($parameterNewValue -and ($parameterValue -ne $parameterNewValue))
            {
                $null = $netIPInterfaceParameters.Add($parameterName, $parameterNewValue)

                Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                        $($script:localizedData.SettingNetIPInterfaceParameterValueMessage) `
                            -f $InterfaceAlias, $AddressFamily, $parameterName, $parameterNewValue
                    ) -join '')

                $parameterUpdated = $true
            }
        }
    }

    if ($parameterUpdated)
    {
        $null = Set-NetIPInterface @netIPInterfaceParameters
    }
}

<#
    .SYNOPSIS
    Sets the current state of the Network Interface.

    .PARAMETER InterfaceAlias
    Alias of the network interface to configure.

    .PARAMETER AddressFamily
    IP address family on the interface to configure.

    .PARAMETER AdvertiseDefaultRoute
    Specifies the default router advertisement for an interface.

    .PARAMETER Advertising
    Specifies the router advertisement value for the IP interface.

    .PARAMETER AutomaticMetric
    Specifies the value for automatic metric calculation.

    .PARAMETER Dhcp
    Specifies the Dynamic Host Configuration Protocol (DHCP) value for an IP interface.

    .PARAMETER DirectedMacWolPattern
    Specifies the wake-up packet value for an IP interface.

    .PARAMETER EcnMarking
    Specifies the value for Explicit Congestion Notification (ECN) marking.

    .PARAMETER ForceArpNdWolPattern
    Specifies the Wake On LAN (WOL) value for the IP interface.

    .PARAMETER Forwarding
    Specifies the packet forwarding value for the IP interface.

    .PARAMETER IgnoreDefaultRoutes
    Specifies a value for Default Route advertisements.

    .PARAMETER ManagedAddressConfiguration
    Specifies the value for managed address configuration.

    .PARAMETER NeighborUnreachabilityDetection
    Specifies the value for Neighbor Unreachability Detection (NUD).

    .PARAMETER OtherStatefulConfiguration
    Specifies the value for configuration other than addresses.

    .PARAMETER RouterDiscovery
    Specifies the value for router discovery for an IP interface.

    .PARAMETER WeakHostReceive
    Specifies the receive value for a weak host model.

    .PARAMETER WeakHostSend
    Specifies the send value for a weak host model.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $AdvertiseDefaultRoute,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $Advertising,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $AutomaticMetric,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $Dhcp,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $DirectedMacWolPattern,

        [Parameter()]
        [ValidateSet('Disabled', 'UseEct1', 'UseEct0', 'AppDecide')]
        [System.String]
        $EcnMarking,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $ForceArpNdWolPattern,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $Forwarding,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $IgnoreDefaultRoutes,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $ManagedAddressConfiguration,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $NeighborUnreachabilityDetection,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $OtherStatefulConfiguration,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled', 'ControlledByDHCP')]
        [System.String]
        $RouterDiscovery,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $WeakHostReceive,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $WeakHostSend
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($script:localizedData.CheckingNetIPInterfaceMessage) -f $InterfaceAlias, $AddressFamily
        ) -join '')

    $netIPInterfaceParameters = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily  = $AddressFamily
    }

    $netIPInterface = Get-NetworkIPInterface @netIPInterfaceParameters

    $desiredConfigurationMatch = $true

    <#
        Loop through the $script:parameterList array and compare the source
        with the value of each parameter. If different then set $desiredConfigurationMatch
        to false.
    #>
    foreach ($parameter in $script:parameterList)
    {
        $parameterName = $parameter.Name

        if ($PSBoundParameters.ContainsKey($parameterName))
        {
            $parameterValue = $netIPInterface.$($parameterName)
            $parameterNewValue = (Get-Variable -Name ($parameterName)).Value

            switch -Wildcard ($parameter.Type)
            {
                'String'
                {
                    # Perform a plain string comparison.
                    if ($parameterNewValue -and ($parameterValue -ne $parameterNewValue))
                    {
                        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                                $($script:localizedData.PropertyNoMatchMessage) `
                                    -f $parameterName, $parameterValue, $parameterNewValue
                            ) -join '')

                        $desiredConfigurationMatch = $false
                    }
                }
            }
        }
    }

    return $desiredConfigurationMatch
}

<#
    .SYNOPSIS
    Get the network IP interface for the address family.
    If the network interface is not found or the address family
    is not bound to the inerface then an exception will be thrown.

    .PARAMETER InterfaceAlias
    Alias of the network interface to configure.

    .PARAMETER AddressFamily
    IP address family on the interface to configure.
#>
function Get-NetworkIPInterface
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingNetIPInterfaceMessage) -f $InterfaceAlias, $AddressFamily
        ) -join '')

    $netIPInterface = Get-NetIPInterface @PSBoundParameters -ErrorAction SilentlyContinue

    if (-not $netIPInterface)
    {
        # The Net IP Interface does not exist or address family is not bound
        New-InvalidOperationException `
            -Message ($script:localizedData.NetIPInterfaceDoesNotExistMessage -f $InterfaceAlias, $AddressFamily)
    }

    return $netIPInterface
}

Export-ModuleMember -Function *-TargetResource
