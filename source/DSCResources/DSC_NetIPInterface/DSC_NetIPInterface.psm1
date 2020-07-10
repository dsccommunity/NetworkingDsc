$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
            -ChildPath 'NetworkingDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    This is an array of all the parameters used by this resource.
    It is used by Get
#>
$parameterList = @(
    'AdvertiseDefaultRoute'
    'Advertising'
    'AutomaticMetric'
    'DirectedMacWolPattern'
    'Dhcp'
    'EcnMarking'
    'ForceArpNdWolPattern'
    'Forwarding'
    'IgnoreDefaultRoutes'
    'ManagedAddressConfiguration'
    'NeighborUnreachabilityDetection'
    'OtherStatefulConfiguration'
    'RouterDiscovery'
    'WeakHostReceive'
    'WeakHostSend'
    'NlMtu'
)

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

    $getNetworkIPInterfaceParameters = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily  = $AddressFamily
    }

    return Get-NetworkIPInterface @getNetworkIPInterfaceParameters
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

    .PARAMETER NlMtu
    Specifies the network layer Maximum Transmission Unit (MTU) value, in bytes, for an IP interface.
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
        $WeakHostSend,

        [Parameter()]
        [System.UInt32]
        $NlMtu
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($script:localizedData.ApplyingNetIPInterfaceMessage) `
                -f $InterfaceAlias, $AddressFamily
        ) -join '')

    $getTargetResourceParameters = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily = $AddressFamily
    }

    $currentState = Get-TargetResource @getTargetResourceParameters

    <#
        Loop through each possible property and if it is passed to the resource
        and the current value of the property is different then add it to the
        netIPInterfaceParameters array that will be used to update the
        net IP interface settings.
    #>
    $parameterUpdateList = Remove-CommonParameter -Hashtable $PSBoundParameters
    $parameterUpdated = $false
    $setNetIPInterfaceParameters = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily = $AddressFamily
    }

    foreach ($parameter in $parameterUpdateList)
    {
        $parameterValue = $netIPInterface.$($parameter)
        $parameterNewValue = (Get-Variable -Name ($parameter)).Value

        if ($parameterNewValue -and ($parameterValue -ne $parameterNewValue))
        {
            $null = $setNetIPInterfaceParameters.Add($parameter, $parameterNewValue)

            Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                    $($script:localizedData.SettingNetIPInterfaceParameterValueMessage) `
                        -f $InterfaceAlias, $AddressFamily, $parameter, $parameterNewValue
                ) -join '')

            $parameterUpdated = $true
        }
    }

    if ($parameterUpdated)
    {
        $null = Set-NetIPInterface @setNetIPInterfaceParameters
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

    .PARAMETER NlMtu
    Specifies the network layer Maximum Transmission Unit (MTU) value, in bytes, for an IP interface.
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
        [System.UInt32]
        $NlMtu
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($script:localizedData.CheckingNetIPInterfaceMessage) -f $InterfaceAlias, $AddressFamily
        ) -join '')

    $getTargetResourceParameters = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily = $AddressFamily
    }

    $currentState = Get-TargetResource @getTargetResourceParameters

    return Test-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters
}

<#
    .SYNOPSIS
    Get the network IP interface for the address family.
    If the network interface is not found or the address family
    is not bound to the inerface then an exception will be thrown.

    It will return an hash table with only the parameters in found
    in the $script:parameterList array and the InterfaceAlias and
    AddressFamily parameters.

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
            -Message ($script:localizedData.NetworkIPInterfaceDoesNotExistMessage -f $InterfaceAlias, $AddressFamily)
    }

    <#
        Populate the properties for get target resource by looping through
        the parameter array list and adding the values to the result array
    #>
    $networkIPInterface = @{
        InterfaceAlias = $InterfaceAlias
        AddressFamily = $AddressFamily
    }

    foreach ($parameter in $script:parameterList)
    {
        $parameterValue = $netIPInterface.$($parameter)
        $null = $networkIPInterface.Add($parameter, $parameterValue)

        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
                $($script:localizedData.NetworkIPInterfaceParameterValueMessage) -f `
                    $InterfaceAlias, $AddressFamily, $parameter, $parameterValue
            ) -join '')
    }

    return $networkIPInterface
}

Export-ModuleMember -Function *-TargetResource
