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
    -ResourceName 'MSFT_xNetAdapterRss' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
.SYNOPSIS
    Gets the current state of NetAdapterRss for a adapter.

.PARAMETER Name
    Specifies the Name of the network adapter to check.

.PARAMETER State
    Specifies the Rss state for the protocol.
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
        [Boolean]
        $Enabled
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapter = Get-NetAdapterRss -Name $Name -ErrorAction Stop
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
                $($LocalizedData.NetAdapterTestingStateMessage -f $Name, $Enabled)
            ) -join '')

        $result = @{
            Name    = $Name
            Enabled = $netAdapter.Enabled
        }

        return $result
    }
}

<#
.SYNOPSIS
    Sets the NetAdapterRss resource state.

.PARAMETER Name
    Specifies the Name of the network adapter to check.

.PARAMETER State
    Specifies the Rss state for the protocol.
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
        [Boolean]
        $Enabled
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapter = Get-NetAdapterRss -Name $Name -ErrorAction Stop
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
                $($LocalizedData.NetAdapterTestingStateMessage -f $Name, $Enabled)
            ) -join '')

        if ($Enabled -ne $netAdapter.Enabled)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.NetAdapterApplyingChangesMessage -f `
                            $Name, $Enabled, $($netAdapter.Enabled.ToString()), $($Enabled.ToString()) )
                ) -join '')

            Set-NetAdapterRss -Name $Name -Enabled:$Enabled
        }
    }
}

<#
.SYNOPSIS
    Tests if the NetAdapterRss resource state is desired state.

.PARAMETER Name
    Specifies the Name of the network adapter to check.

.PARAMETER State
    Specifies the Rss state for the protocol.
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
        [Boolean]
        $Enabled
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapter = Get-NetAdapterRss -Name $Name -ErrorAction Stop
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
                    $Name, $Enabled
            ) -join '')

        return ($Enabled -eq $netAdapter.Enabled)
    }
}
