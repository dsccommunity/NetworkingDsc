<#
    .SYNOPSIS
    Returns the current state of a Network Power Management.

    .PARAMETER AdapterType
    Specifies the name of the network adapter type you want to change. example 'Ethernet 802.3'

#>

function Get-TargetResource
{
     [CmdletBinding()]
     [OutputType([System.Collections.Hashtable])]
     param
     (
          [parameter(Mandatory = $true)]
          [System.String]
          $AdapterType
     )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    $nic = Get-WmiObject Win32_NetworkAdapter | where {$_.AdapterType -eq 'Ethernet 802.3'}
    $powerMgmt = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | where {$_.InstanceName.ToUpper().Contains($nic.PNPDeviceID)}

    If ($powerMgmt.Enable -eq $true){
        $State = $False
    }ELSE{
        $State = $true
    }


    $returnValue = @{
        NICPowerSaving = $powerMgmt.Enable
        AdapterType = $AdapterType
        State = $State
    }

    $returnValue
}

<#
    .SYNOPSIS
    Sets the current state of a Network Power Management.

    .PARAMETER AdapterType
    Specifies the name of the network adapter type you want to change. example 'Ethernet 802.3'

    .PARAMETER State
    Allows to set the state of the Network Adapter power management settings to disable to enable. 
#>
function Set-TargetResource
{
     [CmdletBinding()]
     param
     (
          [parameter(Mandatory = $true)]
          [System.String]
          $AdapterType,

          [ValidateSet("Enabled","Disabled")]
          [System.String]
          $State
     )


    $nics = Get-WmiObject Win32_NetworkAdapter | where {$_.AdapterType -eq $AdapterType}
    foreach ($nic in $nics)
    {
        $powerMgmt = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | where {$_.InstanceName.ToUpper().Contains($nic.PNPDeviceID)}
            
        If ($State -eq 'Disabled'){
            Write-Verbose "Disabling the NIC power management setting."
            $powerMgmt.Enable = $False #Turn off PowerManagement feature
        }ELSE{
            Write-Verbose "Enabling the NIC power management setting."
            $powerMgmt.Enable = $true #Turn on PowerManagement feature
        }
            
        $powerMgmt.psbase.Put() | Out-Null
    }


}

<#
    .SYNOPSIS
    Test the current state of a Network Power Management.

    .PARAMETER AdapterType
    Specifies the name of the network adapter type you want to change. example 'Ethernet 802.3'

    .PARAMETER State
    Allows to Check the state of the Network Adapter power management settings to disable to enable to see if it needs to be changed. 
#>
function Test-TargetResource
{
     [CmdletBinding()]
     [OutputType([System.Boolean])]
     param
     (
          [parameter(Mandatory = $true)]
          [System.String]
          $AdapterType,

          [ValidateSet("Enabled","Disabled")]
          [System.String]
          $State
     )

    Write-Verbose "Checking to see if the power setting on the NIC for Adapter Type $AdapterType."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    $nic = Get-WmiObject Win32_NetworkAdapter | where {$_.AdapterType -eq 'Ethernet 802.3'}
    $powerMgmt = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | where {$_.InstanceName.ToUpper().Contains($nic.PNPDeviceID)}

    If ($State -eq 'Disabled'){
        If ($powerMgmt.Enable -eq $false){
            Write-Verbose "NIC Power Management setting is disabled."
            $result = $true
        }ELSE{
            Write-Verbose "NIC Power Management setting is not disabled. - Disabling"
            $result = $false
        }
    }

    If ($State -eq 'Enabled'){
        If ($powerMgmt.Enable -eq $false) {
            Write-Verbose "NIC Power Management setting is disabled. - Enabling."
            $result = $false
        }ELSE{
            Write-Verbose "NIC Power Management setting is not disabled."
            $result = $true
        }
    }

$result
}


Export-ModuleMember -Function *-TargetResource

