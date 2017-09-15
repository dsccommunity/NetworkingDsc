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
    -ResourceName 'MSFT_xNetAdapterRsc' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
.SYNOPSIS
    Gets the current state of NetAdapterRSC for a adapter.

.PARAMETER Name
    Specifies the Name of the network adapter to check.

.PARAMETER Protocol
    Specifies which protocol to target.

.PARAMETER State
    Specifies the RSC state for the protocol.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("IPv4", "IPv6", "All")]
        [String]
        $Protocol,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $State
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapter = Get-NetAdapterRsc -Name $Name -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapter)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NetAdapterTestingStateMessage -f $Name, $Protocol)
            ) -join '')

        $result = @{
            Name     = $Name
            Protocol = $Protocol
        }
        switch ($Protocol)
        {
            'IPv4'
            {
                $result.add('State', $netAdapter.IPv4Enabled)
                $result.add('StateIPv4', $netAdapter.IPv4Enabled)
            }
            'IPv6'
            {
                $result.add('State', $netAdapter.IPv6Enabled)
                $result.add('StateIPv6', $netAdapter.IPv6Enabled)
            }
            'All'
            {
                $result.add('State', $netAdapter.IPv4Enabled)
                $result.add('StateIPv4', $netAdapter.IPv4Enabled)
                $result.add('StateIPv6', $netAdapter.IPv6Enabled)
            }
        }

        return $result
    }
}

<#
.SYNOPSIS
    Sets the NetAdapterRSC resource state.

.PARAMETER Name
    Specifies the Name of the network adapter to check.

.PARAMETER Protocol
    Specifies which protocol to target.

.PARAMETER State
    Specifies the RSC state for the protocol.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("IPv4", "IPv6", "All")]
        [String]
        $Protocol,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $State
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapter = Get-NetAdapterRsc -Name $Name -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapter)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NetAdapterTestingStateMessage -f $Name, $Protocol)
            ) -join '')

        if ($Protocol -in ('IPv4', 'All') -and $State -ne $netAdapter.IPv4Enabled)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.NetAdapterApplyingChangesMessage -f `
                            $Name, $Protocol, $($netAdapter.IPv4Enabled.ToString()), $($State.ToString()) )
                ) -join '')

            Set-NetAdapterRsc -Name $Name -IPv4Enabled $State
        }
        if ($Protocol -in ('IPv6', 'All') -and $State -ne $netAdapter.IPv6Enabled)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.NetAdapterApplyingChangesMessage -f `
                            $Name, $Protocol, $($netAdapter.IPv6Enabled.ToString()), $($State.ToString()) )
                ) -join '')

            Set-NetAdapterRsc -Name $Name -IPv6Enabled $State
        }
    }
}

<#
.SYNOPSIS
    Tests if the NetAdapterRsc resource state is desired state.

.PARAMETER Name
    Specifies the Name of the network adapter to check.

.PARAMETER Protocol
    Specifies which protocol to target.

.PARAMETER State
    Specifies the RSC state for the protocol.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("IPv4", "IPv6", "All")]
        [String]
        $Protocol,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $State
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapter = Get-NetAdapterRsc -Name $Name -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapter)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $localizedData.NetAdapterTestingStateMessage -f `
                    $Name, $Protocol
            ) -join '')

        switch ($Protocol)
        {
            'IPv4'
            {
                return ($State -eq $netAdapter.IPv4Enabled)
            }
            'IPv6'
            {
                return ($State -eq $netAdapter.IPv6Enabled)
            }
            'All'
            {
                return ($State -eq $netAdapter.IPv4Enabled -and $State -eq $netAdapter.IPv6Enabled)
            }
        }
    }
}
