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
    Gets the current state of NetAdapterRss for a adapter.

.PARAMETER NetworkAdapterName
    Specifies the Name of the network adapter to check.

.PARAMETER RegistryKeyword
    Specifies the settings registrykeyword that should be in desired state.

.PARAMETER RegistryValue
    Specifies the value of the settings.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $NetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("*FlowControl","*InterruptModeration","*IPChecksumOffloadIPv4","*JumboPacket","*LsoV2IPv4","*LsoV2IPv6","*MaxRssProcessors","*NumaNodeId","*NumRssQueues","*PriorityVLANTag","*ReceiveBuffers","*RSS","*RssBaseProcNumber","*RssMaxProcNumber","*RSSProfile","*SpeedDuplex","*TCPChecksumOffloadIPv4","*TCPChecksumOffloadIPv6","*TransmitBuffers","*UDPChecksumOffloadIPv4","*UDPChecksumOffloadIPv6","AdaptiveIFS","ITR","LogLinkStateEvent","MasterSlave","NetworkAddress","WaitAutoNegComplete")]
        [String]
        $RegistryKeyword,

        [Parameter(Mandatory = $true)]
        [String]
        $RegistryValue
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapteradvprop = Get-NetAdapterAdvancedProperty -Name $networkAdapterName  -RegistryKeyword $RegistryKeyword -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapteradvprop)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NetAdapterTestingStateMessage -f $NetworkAdapterName, $RegistryKeyword)
            ) -join '')

        $result = @{
            Name            = $NetworkAdapterName
            RegistryKeyword = $RegistryKeyword
            DisplayValue    = $netadapteradvprop.DisplayValue
            RegistryValue   = $netadapteradvprop.RegistryValue
        }

        return $result
    }
}

<#
.SYNOPSIS
    Gets the current state of NetAdapterRss for a adapter.

.PARAMETER NetworkAdapterName
    Specifies the Name of the network adapter to check.

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
        [String]
        $NetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("*FlowControl","*InterruptModeration","*IPChecksumOffloadIPv4","*JumboPacket","*LsoV2IPv4","*LsoV2IPv6","*MaxRssProcessors","*NumaNodeId","*NumRssQueues","*PriorityVLANTag","*ReceiveBuffers","*RSS","*RssBaseProcNumber","*RssMaxProcNumber","*RSSProfile","*SpeedDuplex","*TCPChecksumOffloadIPv4","*TCPChecksumOffloadIPv6","*TransmitBuffers","*UDPChecksumOffloadIPv4","*UDPChecksumOffloadIPv6","AdaptiveIFS","ITR","LogLinkStateEvent","MasterSlave","NetworkAddress","WaitAutoNegComplete")]
        [String]
        $RegistryKeyword,

        [Parameter(Mandatory = $true)]
        [String]
        $RegistryValue
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')

    try
    {
        $netAdapteradvprop = Get-NetAdapterAdvancedProperty -Name $networkAdapterName  -RegistryKeyword $RegistryKeyword -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapteradvprop)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.NetAdapterTestingStateMessage -f $NetworkAdapterName, $RegistryKeyword)
            ) -join '')

        if ($RegistryValue -ne $netadapteradvprop.RegistryValue)
        {
            $netadapterRegistryValue = $netadapteradvprop.RegistryValue
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.NetAdapterApplyingChangesMessage -f `
                            $NetworkAdapterName, $RegistryKeyword, "$netadapterRegistryValue", $RegistryValue )
                ) -join '')

            Set-NetAdapterAdvancedProperty -RegistryValue $RegistryValue -Name $networkAdapterName  -RegistryKeyword $RegistryKeyword
        }
    }
}

<#
.SYNOPSIS
    Gets the current state of NetAdapterRss for a adapter.

.PARAMETER NetworkAdapterName
    Specifies the Name of the network adapter to check.

.PARAMETER RegistryKeyword
    Specifies the settings registrykeyword that should be in desired state.

.PARAMETER RegistryValue
    Specifies the value of the settings.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $NetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("*FlowControl","*InterruptModeration","*IPChecksumOffloadIPv4","*JumboPacket","*LsoV2IPv4","*LsoV2IPv6","*MaxRssProcessors","*NumaNodeId","*NumRssQueues","*PriorityVLANTag","*ReceiveBuffers","*RSS","*RssBaseProcNumber","*RssMaxProcNumber","*RSSProfile","*SpeedDuplex","*TCPChecksumOffloadIPv4","*TCPChecksumOffloadIPv6","*TransmitBuffers","*UDPChecksumOffloadIPv4","*UDPChecksumOffloadIPv6","AdaptiveIFS","ITR","LogLinkStateEvent","MasterSlave","NetworkAddress","WaitAutoNegComplete")]
        [String]
        $RegistryKeyword,

        [Parameter(Mandatory = $true)]
        [String]
        $RegistryValue
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $localizedData.CheckingNetAdapterMessage
        ) -join '')



    try
    {
        $netAdapteradvprop = Get-NetAdapterAdvancedProperty -Name $networkAdapterName  -RegistryKeyword $RegistryKeyword -ErrorAction Stop
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundMessage)
    }

    if ($netAdapteradvprop)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $localizedData.NetAdapterTestingStateMessage -f `
                    $NetworkAdapterName, $RegistryKeyword
            ) -join '')

        If ($RegistryValue -eq $netadapteradvprop.RegistryValue)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
}
