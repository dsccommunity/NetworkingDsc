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
    -ResourceName 'MSFT_NetAdapterState' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
.SYNOPSIS
    Gets the current state of a network adapter.

.PARAMETER Name
    Specifies the name of the network adapter.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapter = Get-NetAdapter -Name $Name -ErrorAction Stop
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
                $($LocalizedData.NetAdapterTestingStateMessage -f $Name)
            ) -join '')

        $result = @{
            Name  = $Name
            State = if ($netAdapter.AdminStatus.value__ -eq 1)
                    {
                        'Enabled'
                    }
                    else
                    {
                        'Disabled'
                    }
        }

        return $result
    }
}

<#
.SYNOPSIS
    Sets the NetAdapterState resource state.

.PARAMETER Name
    Specifies the name of the network adapter..

.PARAMETER State
    Specifies the desired state for the network adapter.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $State
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapter = Get-NetAdapter -Name $Name -ErrorAction Stop
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
                $($LocalizedData.NetAdapterTestingStateMessage -f $Name)
            ) -join '')

        try
        {
            if ($State -eq 'Enabled')
            {
                Enable-NetAdapter -Name $Name -ErrorAction Stop
            }
            else
            {
                Disable-NetAdapter -Name $Name -Confirm:$false -ErrorAction Stop
            }
        }
        catch
        {
            Write-Error -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NetAdapterSetFailedMessage -f $Name, $State, $_)
            ) -join '')
        }
    }
}

<#
.SYNOPSIS
    Tests if the NetAdapterState resource state is desired state.

.PARAMETER Name
    Specifies the name of the network adapter.

.PARAMETER State
    Specifies the state of the network adapter.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $State
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    $netAdapter = Get-NetAdapter -Name $Name -ErrorAction SilentlyContinue

    if ($netAdapter)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($localizedData.NetAdapterTestingStateMessage -f $Name)
            ) -join '')

        $currentState = if ($netAdapter.AdminStatus.value__ -eq 1)
        {
            'Enabled'
        }
        else
        {
            'Disabled'
        }

        return $currentState -eq $State
    }
    else
    {
        return $false
    }
}
