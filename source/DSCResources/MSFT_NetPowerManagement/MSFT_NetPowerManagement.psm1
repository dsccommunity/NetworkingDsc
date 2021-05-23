$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
            -ChildPath 'NetworkingDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Gets the power management state of the network adapter.

    .PARAMETER Name
        Specifies the name of the network adapter.
#>
function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State
    )

    Write-Verbose "Getting the power setting on the network adpater."

    $nic = Get-NetAdapterPowerManagement `
        -Name $Name `
        -IncludeHidden:$true

    if ($nic.DeviceSleepOnDisconnect -eq 'Inactive') {
        $State = 'Disabled'
    }
    else {
        $State = 'Enabled'
    }

    return @{
        Name  = $Name
        State = $State
    }
}

<#
    .SYNOPSIS
        Sets the power management properties on the network adapter.

    .PARAMETER Name
        Specifies the name of the network adapter.

    .PARAMETER State
        Allows to set the state of the Network Adapter power management settings to disable to enable.

    .PARAMETER NoRestart
        Specifies whether to restart the network adapter after changing the power management setting.
#>
function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State,

        [Parameter()]
        [System.Boolean]
        $NoRestart = $false
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $script:localizedData.CheckingNetAdapterMessage
    ) -join '')

    $PSBoundParameters.Remove("NoRestart")
    $currentState = Get-TargetResource @PSBoundParameters

    if ($currentState.State -eq 'Disabled')
    {
        if ($State -eq 'Enabled')
        {
            Enable-NetAdapterPowerManagement `
                -Name $Name `
                -IncludeHidden:$true `
                -NoRestart:$NoRestart
        }
    } else {
        if ($State -eq 'Disabled')
        {
            Disable-NetAdapterPowerManagement `
                -Name $Name `
                -IncludeHidden:$true `
                -NoRestart:$NoRestart
        }
    }
}

<#
    .SYNOPSIS
        Tests if the power management state of the network adapter is in the desired state.

    .PARAMETER Name
        Specifies the name of the network adapter.

    .PARAMETER State
        Allows to Check the state of the Network Adapter power management settings to disable to enable to see if it needs to be changed.
#>
function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State
    )

    Write-Verbose "Checking to see if the power setting on the NIC for $Name."

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.NetPowerManagementMessage -f $Name)
        ) -join '')

    $currentState = Get-TargetResource @PSBoundParameters

    if ($currentState)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.NetPowerManagementMessage -f $Name, $currentState.State)
            ) -join '')

        return $currentState.State -eq $State
    }

    return $false
}


Export-ModuleMember -Function *-TargetResource
