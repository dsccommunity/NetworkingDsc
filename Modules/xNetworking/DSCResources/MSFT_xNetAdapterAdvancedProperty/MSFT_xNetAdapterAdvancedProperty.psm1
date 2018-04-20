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
    -ResourceName 'MSFT_xNetAdapterAdvancedProperty' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
.SYNOPSIS
    Gets the current value of an advanced property.

.PARAMETER NetworkAdapterName
    Specifies the Name of the network adapter to get the advanced property for.

.PARAMETER RegistryKeyword
    Specifies the settings registrykeyword that should be in desired state.

.PARAMETER RegistryValue
    Specifies the value of the settings.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $NetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("*DcbxMode","*EncapsulatedPacketTaskOffload","*FlowControl","*InterruptModeration","*IPChecksumOffloadIPv4","*JumboPacket","*LsoV2IPv4","*LsoV2IPv6","*MaxRssProcessors","*NetworkDirect","*NumaNodeId","*NumRssQueues","*PacketDirect","*PriorityVLANTag","*QOS","*ReceiveBuffers","*RecvCompletionMethod","*RoceMaxFrameSize","*RscIPv4","*RSS","*RssBaseProcNumber","*RssMaxProcNumber","*RssOnHostVPorts","*RSSProfile","RxIntModeration","RxIntModerationProfile","*SpeedDuplex","*Sriov","*TCPChecksumOffloadIPv4","*TCPChecksumOffloadIPv6","*TCPUDPChecksumOffloadIPv4","*TCPUDPChecksumOffloadIPv6","*TransmitBuffers","TxIntModerationProfile","*UDPChecksumOffloadIPv4","*UDPChecksumOffloadIPv6","VlanID","*VMQ","*VMQVlanFiltering","AdaptiveIFS","ITR","LogLinkStateEvent","MasterSlave","NetworkAddress","WaitAutoNegComplete")]
        [System.String]
        $RegistryKeyword,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RegistryValue
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapterAdvancedProperty = Get-NetAdapterAdvancedProperty `
            -Name $networkAdapterName `
            -RegistryKeyword $RegistryKeyword `
            -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapterAdvancedProperty)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NetAdapterTestingStateMessage -f $NetworkAdapterName, $RegistryKeyword)
            ) -join '')

        $result = @{
            Name            = $NetworkAdapterName
            RegistryKeyword = $RegistryKeyword
            DisplayValue    = $netAdapterAdvancedProperty.DisplayValue
            RegistryValue   = $netAdapterAdvancedProperty.RegistryValue
        }

        return $result
    }
}

<#
.SYNOPSIS
    Gets the current value of an advanced property.

.PARAMETER NetworkAdapterName
    Specifies the Name of the network adapter to get the advanced property for.

.PARAMETER RegistryKeyword
    Specifies the settings registrykeyword that should be in desired state.

.PARAMETER RegistryValue
    Specifies the value of the settings.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $NetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("*DcbxMode","*EncapsulatedPacketTaskOffload","*FlowControl","*InterruptModeration","*IPChecksumOffloadIPv4","*JumboPacket","*LsoV2IPv4","*LsoV2IPv6","*MaxRssProcessors","*NetworkDirect","*NumaNodeId","*NumRssQueues","*PacketDirect","*PriorityVLANTag","*QOS","*ReceiveBuffers","*RecvCompletionMethod","*RoceMaxFrameSize","*RscIPv4","*RSS","*RssBaseProcNumber","*RssMaxProcNumber","*RssOnHostVPorts","*RSSProfile","RxIntModeration","RxIntModerationProfile","*SpeedDuplex","*Sriov","*TCPChecksumOffloadIPv4","*TCPChecksumOffloadIPv6","*TCPUDPChecksumOffloadIPv4","*TCPUDPChecksumOffloadIPv6","*TransmitBuffers","TxIntModerationProfile","*UDPChecksumOffloadIPv4","*UDPChecksumOffloadIPv6","VlanID","*VMQ","*VMQVlanFiltering","AdaptiveIFS","ITR","LogLinkStateEvent","MasterSlave","NetworkAddress","WaitAutoNegComplete")]
        [System.String]
        $RegistryKeyword,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RegistryValue
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapterAdvancedProperty = Get-NetAdapterAdvancedProperty `
            -Name $networkAdapterName `
            -RegistryKeyword $RegistryKeyword `
            -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapterAdvancedProperty)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NetAdapterTestingStateMessage -f $NetworkAdapterName, $RegistryKeyword)
            ) -join '')

        if ($RegistryValue -ne $netAdapterAdvancedProperty.RegistryValue)
        {
            $netadapterRegistryValue = $netAdapterAdvancedProperty.RegistryValue
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.NetAdapterApplyingChangesMessage -f `
                            $NetworkAdapterName, $RegistryKeyword, "$netadapterRegistryValue", $RegistryValue )
                ) -join '')

            Set-NetAdapterAdvancedProperty `
                -RegistryValue $RegistryValue `
                -Name $networkAdapterName `
                -RegistryKeyword $RegistryKeyword
        }
    }
}

<#
.SYNOPSIS
    Sets the current value of an advanced property.

.PARAMETER NetworkAdapterName
    Specifies the Name of the network adapter to get the advanced property for.

.PARAMETER RegistryKeyword
    Specifies the settings registrykeyword that should be in desired state.

.PARAMETER RegistryValue
    Specifies the value of the settings.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $NetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("*DcbxMode","*EncapsulatedPacketTaskOffload","*FlowControl","*InterruptModeration","*IPChecksumOffloadIPv4","*JumboPacket","*LsoV2IPv4","*LsoV2IPv6","*MaxRssProcessors","*NetworkDirect","*NumaNodeId","*NumRssQueues","*PacketDirect","*PriorityVLANTag","*QOS","*ReceiveBuffers","*RecvCompletionMethod","*RoceMaxFrameSize","*RscIPv4","*RSS","*RssBaseProcNumber","*RssMaxProcNumber","*RssOnHostVPorts","*RSSProfile","RxIntModeration","RxIntModerationProfile","*SpeedDuplex","*Sriov","*TCPChecksumOffloadIPv4","*TCPChecksumOffloadIPv6","*TCPUDPChecksumOffloadIPv4","*TCPUDPChecksumOffloadIPv6","*TransmitBuffers","TxIntModerationProfile","*UDPChecksumOffloadIPv4","*UDPChecksumOffloadIPv6","VlanID","*VMQ","*VMQVlanFiltering","AdaptiveIFS","ITR","LogLinkStateEvent","MasterSlave","NetworkAddress","WaitAutoNegComplete")]
        [System.String]
        $RegistryKeyword,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RegistryValue
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapterAdvancedProperty = Get-NetAdapterAdvancedProperty `
            -Name $networkAdapterName `
            -RegistryKeyword $RegistryKeyword `
            -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapterAdvancedProperty)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $localizedData.NetAdapterTestingStateMessage -f `
                    $NetworkAdapterName, $RegistryKeyword
            ) -join '')

        if ($RegistryValue -eq $netAdapterAdvancedProperty.RegistryValue)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
}
