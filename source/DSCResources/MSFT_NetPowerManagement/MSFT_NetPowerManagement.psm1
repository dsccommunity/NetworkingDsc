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
        Gets the power management features of the network adapter.

    .PARAMETER AdapterType
        Specifies the network adapter type you want to change. example 'Ethernet 802.3'
#>
function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $AdapterType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State
    )

    Write-Verbose "Getting the power setting on the network adpater."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    $nic = Get-CimClass Win32_NetworkAdapter | where-object {$_.AdapterType -eq $AdapterType}
    $powerMgmt = Get-CimClass MSPower_DeviceEnable -Namespace root\wmi | where-object {$_.InstanceName.ToUpper().Contains($nic.PNPDeviceID)}

    if ($powerMgmt.Enable -eq $true) {
        $State = $False
    }
    else {
        $State = $true
    }


    $returnValue = @{
        NICPowerSaving = $powerMgmt.Enable
        AdapterType    = $AdapterType
        State          = $State
    }

    $returnValue
}

<#
    .SYNOPSIS
        Sets the power management properties on the network adapter.

    .PARAMETER AdapterType
        Specifies the name of the network adapter type you want to change. example 'Ethernet 802.3'

    .PARAMETER State
        Allows to set the state of the Network Adapter power management settings to disable to enable.
#>
function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $AdapterType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $script:localizedData.CheckingNetAdapterMessage
    ) -join '')

    $currentState = Get-TargetResource @PSBoundParameters

    $nics = Get-CimClass Win32_NetworkAdapter | where-object {$_.AdapterType -eq $AdapterType}
    foreach ($nic in $nics) {
        $powerMgmt = Get-CimClass MSPower_DeviceEnable -Namespace root\wmi | where-object {$_.InstanceName.ToUpper().Contains($nic.PNPDeviceID)}

        if ($State -eq 'Disabled') {
            Write-Verbose "Disabling the NIC power management setting."
            $powerMgmt.Enable = $False #Turn off PowerManagement feature
        }
        else {
            Write-Verbose "Enabling the NIC power management setting."
            $powerMgmt.Enable = $true #Turn on PowerManagement feature
        }

        $powerMgmt.psbase.Put() | Out-Null
    }
}

<#
    .SYNOPSIS
        Tests if the NetPowerManagement resource state is desired state.

    .PARAMETER AdapterType
        Specifies the name of the network adapter type you want to change. example 'Ethernet 802.3'

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
        $AdapterType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State
    )

    Write-Verbose "Checking to see if the power setting on the NIC for Adapter Type $AdapterType."

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.NetPowerManagementMessage -f $AdapterType)
        ) -join '')

    $currentState = Get-TargetResource @PSBoundParameters

    if ($currentState)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.NetPowerManagementMessage -f $AdapterType, $currentState.State)
            ) -join '')

        return $currentState.State -eq $State
    }

    return $false
}


Export-ModuleMember -Function *-TargetResource
