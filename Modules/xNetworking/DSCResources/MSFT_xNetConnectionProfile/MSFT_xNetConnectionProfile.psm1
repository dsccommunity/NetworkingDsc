$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
                                                     -ChildPath 'NetworkingDsc.Common.psm1'))

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.ResourceHelper' `
                                                     -ChildPath 'NetworkingDsc.ResourceHelper.psm1'))

# Import Localization Strings
$localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xNetConnectionProfile' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
    Returns the current Networking Connection Profile for the specified interface.

    .PARAMETER InterfaceAlias
    Specifies the alias for the Interface that is being changed.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $InterfaceAlias
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingNetConnectionProfile) -f $InterfaceAlias
    ) -join '')

    $result = Get-NetConnectionProfile -InterfaceAlias $InterfaceAlias

    return @{
        InterfaceAlias   = $result.InterfaceAlias
        NetworkCategory  = $result.NetworkCategory
        IPv4Connectivity = $result.IPv4Connectivity
        IPv6Connectivity = $result.IPv6Connectivity
    }
}

<#
    .SYNOPSIS
    Sets the Network Connection Profile for a specified interface.

    .PARAMETER InterfaceAlias
    Specifies the alias for the Interface that is being changed.

    .PARAMETER IPv4Connectivity
    Specifies the IPv4 Connection Value.

    .PARAMETER IPv6Connectivity
    Specifies the IPv6 Connection Value.

    .PARAMETER NetworkCategory
    Sets the Network Category for the interface
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $InterfaceAlias,

        [ValidateSet('Disconnected', 'NoTraffic', 'Subnet', 'LocalNetwork', 'Internet')]
        [string]
        $IPv4Connectivity,

        [ValidateSet('Disconnected', 'NoTraffic', 'Subnet', 'LocalNetwork', 'Internet')]
        [string]
        $IPv6Connectivity,

        [ValidateSet('Public', 'Private')]
        [string]
        $NetworkCategory
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.SetNetConnectionProfile) -f $InterfaceAlias
    ) -join '')

    Assert-ResourceProperty @PSBoundParameters

    Set-NetConnectionProfile @PSBoundParameters
}

<#
    .SYNOPSIS
    Tests is the Network Connection Profile for the specified interface is in the correct state.

    .PARAMETER InterfaceAlias
    Specifies the alias for the Interface that is being changed.

    .PARAMETER IPv4Connectivity
    Specifies the IPv4 Connection Value.

    .PARAMETER IPv6Connectivity
    Specifies the IPv6 Connection Value.

    .PARAMETER NetworkCategory
    Sets the NetworkCategory for the interface
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $InterfaceAlias,

        [Parameter()]
        [ValidateSet('Disconnected', 'NoTraffic', 'Subnet', 'LocalNetwork', 'Internet')]
        [string]
        $IPv4Connectivity,

        [Parameter()]
        [ValidateSet('Disconnected', 'NoTraffic', 'Subnet', 'LocalNetwork', 'Internet')]
        [string]
        $IPv6Connectivity,

        [Parameter()]
        [ValidateSet('Public', 'Private')]
        [string]
        $NetworkCategory
    )

    Assert-ResourceProperty @PSBoundParameters

    $current = Get-TargetResource -InterfaceAlias $InterfaceAlias

    if (-not [String]::IsNullOrEmpty($IPv4Connectivity) -and `
        ($IPv4Connectivity -ne $current.IPv4Connectivity))
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestIPv4Connectivity) -f $IPv4Connectivity, $current.IPv4Connectivity
        ) -join '')

        return $false
    }

    if (-not [String]::IsNullOrEmpty($IPv6Connectivity) -and `
        ($IPv6Connectivity -ne $current.IPv6Connectivity))
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestIPv6Connectivity) -f $IPv6Connectivity, $current.IPv6Connectivity
        ) -join '')

        return $false
    }

    if (-not [String]::IsNullOrEmpty($NetworkCategory) -and `
        ($NetworkCategory -ne $current.NetworkCategory))
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestNetworkCategory) -f $NetworkCategory, $current.NetworkCategory
        ) -join '')

        return $false
    }

    return $true
}

<#
    .SYNOPSIS
    Check the parameter combination that was passed was valid.
    Ensures interface exists. If any problems are detected an
    exception will be thrown.

    .PARAMETER InterfaceAlias
    Specifies the alias for the Interface that is being changed.

    .PARAMETER IPv4Connectivity
    Specifies the IPv4 Connection Value.

    .PARAMETER IPv6Connectivity
    Specifies the IPv6 Connection Value.

    .PARAMETER NetworkCategory
    Sets the NetworkCategory for the interface
#>
function Assert-ResourceProperty
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $InterfaceAlias,

        [Parameter()]
        [ValidateSet('Disconnected', 'NoTraffic', 'Subnet', 'LocalNetwork', 'Internet')]
        [string]
        $IPv4Connectivity,

        [Parameter()]
        [ValidateSet('Disconnected', 'NoTraffic', 'Subnet', 'LocalNetwork', 'Internet')]
        [string]
        $IPv6Connectivity,

        [Parameter()]
        [ValidateSet('Public', 'Private')]
        [string]
        $NetworkCategory
    )

    if (-not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.InterfaceNotAvailableError -f $InterfaceAlias)
    }

    if ([String]::IsNullOrEmpty($IPv4Connectivity) -and `
        [String]::IsNullOrEmpty($IPv6Connectivity) -and `
        [String]::IsNullOrEmpty($NetworkCategory))
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.ParameterCombinationError)
    }
} # Assert-ResourceProperty
