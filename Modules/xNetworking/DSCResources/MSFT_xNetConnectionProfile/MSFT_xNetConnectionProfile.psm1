# Get the path to the shared modules folder
$script:ModulesFolderPath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent)) `
                                      -ChildPath 'Modules'

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $script:ModulesFolderPath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.ResourceHelper' `
                                                     -ChildPath 'NetworkingDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xNetConnectionProfile' `
    -ResourcePath $PSScriptRoot

# Import the common networking functions
Import-Module -Name (Join-Path -Path $script:ModulesFolderPath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
                                                     -ChildPath 'NetworkingDsc.Common.psm1'))

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Position = 0, Mandatory = $true)]
        [string] $InterfaceAlias
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

function Set-TargetResource
{
    param
    (
        [parameter(Mandatory = $true)]
        [string] $InterfaceAlias,

        [ValidateSet('Disconnected', 'NoTraffic', 'Subnet', 'LocalNetwork', 'Internet')]
        [string] $IPv4Connectivity,

        [ValidateSet('Disconnected', 'NoTraffic', 'Subnet', 'LocalNetwork', 'Internet')]
        [string] $IPv6Connectivity,

        [ValidateSet('Public', 'Private')]
        [string] $NetworkCategory
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.SetNetConnectionProfile) -f $InterfaceAlias
    ) -join '')

    Set-NetConnectionProfile @PSBoundParameters
}


function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [string] $InterfaceAlias,

        [ValidateSet('Disconnected', 'NoTraffic', 'Subnet', 'LocalNetwork', 'Internet')]
        [string] $IPv4Connectivity,

        [ValidateSet('Disconnected', 'NoTraffic', 'Subnet', 'LocalNetwork', 'Internet')]
        [string] $IPv6Connectivity,

        [ValidateSet('Public', 'Private')]
        [string] $NetworkCategory
    )

    $current = Get-TargetResource -InterfaceAlias $InterfaceAlias

    if ($IPv4Connectivity -ne $current.IPv4Connectivity)
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestIPv4Connectivity) -f $IPv4Connectivity, $current.IPv4Connectivity
        ) -join '')

        return $false
    }

    if ($IPv6Connectivity -ne $current.IPv6Connectivity)
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestIPv6Connectivity) -f $IPv6Connectivity, $current.IPv6Connectivity
        ) -join '')

        return $false
    }

    if ($NetworkCategory -ne $current.NetworkCategory)
    {
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestNetworkCategory) -f $NetworkCategory, $current.NetworkCategory
        ) -join '')

        return $false
    }

    return $true
}
