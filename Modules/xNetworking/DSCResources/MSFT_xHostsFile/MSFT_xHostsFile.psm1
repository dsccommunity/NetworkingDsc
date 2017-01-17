# Get the path to the shared modules folder
$script:ModulesFolderPath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent)) `
                                      -ChildPath 'Modules'

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $script:ModulesFolderPath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.ResourceHelper' `
                                                     -ChildPath 'NetworkingDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xHostsFile' `
    -ResourcePath $PSScriptRoot

# Import the common networking functions
Import-Module -Name (Join-Path -Path $script:ModulesFolderPath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
                                                     -ChildPath 'NetworkingDsc.Common.psm1'))

<#
    .SYNOPSIS
    Returns the current state of a hosts file entry.

    .PARAMETER HostName
    Specifies the name of the computer that will be mapped to an IP address.

    .PARAMETER IPAddress
    Specifies the IP Address that should be mapped to the host name.

    .PARAMETER Ensure
    Specifies if the hosts file entry should be created or deleted.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $HostName,

        [System.String]
        $IPAddress,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message ($LocalizedData.StartingGet -f $HostName)

    $hosts = Get-Content -Path "$env:windir\System32\drivers\etc\hosts"
    $allHosts = $hosts `
           | Where-Object { [System.String]::IsNullOrEmpty($_) -eq $false -and $_.StartsWith('#') -eq $false } `
           | ForEach-Object {
                $data = $_ -split '\s+'
                if ($data.Length -gt 2)
                {
                    # Account for host entries that have multiple entries on a single line
                    $result = @()
                    for ($i = 1; $i -lt $data.Length; $i++)
                    {
                        $result += @{
                            Host = $data[$i]
                            IP = $data[0]
                        }
                    }
                    return $result
                }
                else
                {
                    return @{
                        Host = $data[1]
                        IP = $data[0]
                    }
                }
        } | Select-Object @{ Name="Host"; Expression={$_.Host}}, @{Name="IP"; Expression={$_.IP}}

    $hostEntry = $allHosts | Where-Object { $_.Host -eq $HostName }

    if ($null -eq $hostEntry)
    {
        return @{
            HostName = $HostName
            IPAddress = $null
            Ensure = "Absent"
        }
    }
    else
    {
        return @{
            HostName = $hostEntry.Host
            IPAddress = $hostEntry.IP
            Ensure = "Present"
        }
    }
}

<#
    .SYNOPSIS
    Adds, updates or removes a hosts file entry.

    .PARAMETER HostName
    Specifies the name of the computer that will be mapped to an IP address.

    .PARAMETER IPAddress
    Specifies the IP Address that should be mapped to the host name.

    .PARAMETER Ensure
    Specifies if the hosts file entry should be created or deleted.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $HostName,

        [System.String]
        $IPAddress,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    $currentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message ($LocalizedData.StartingSet -f $HostName)

    if ($Ensure -eq "Present" -and $PSBoundParameters.ContainsKey("IPAddress") -eq $false)
    {
        $errorId = 'IPAddressNotPresentError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.UnableToEnsureWithoutIP) -f $Address,$AddressFamily
        $exception = New-Object -TypeName System.InvalidOperationException `
                                -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                                  -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    if ($currentValues.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message ($LocalizedData.CreateNewEntry -f $HostName)
        Add-Content -Path "$env:windir\System32\drivers\etc\hosts" -Value "`r`n$IPAddress`t$HostName"
    }
    else
    {
        $hosts = Get-Content -Path "$env:windir\System32\drivers\etc\hosts"
        $replace = $hosts | Where-Object {
            [System.String]::IsNullOrEmpty($_) -eq $false -and $_.StartsWith('#') -eq $false
        } | Where-Object { $_ -like "*$HostName" }

        $multiLineEntry = $false
        $data = $replace -split '\s+'
        if ($data.Length -gt 2)
        {
            $multiLineEntry = $true
        }

        if ($currentValues.Ensure -eq "Present" -and $Ensure -eq "Present")
        {
            Write-Verbose -Message ($LocalizedData.UpdateExistingEntry -f $HostName)
            if ($multiLineEntry -eq $true)
            {
                $newReplaceLine = $replace -replace $HostName, ""
                $hosts = $hosts -replace $replace, $newReplaceLine
                $hosts += "$IPAddress`t$HostName"
            }
            else
            {
                $hosts = $hosts -replace $replace, "$IPAddress`t$HostName"
            }
        }
        if ($Ensure -eq "Absent")
        {
            Write-Verbose -Message ($LocalizedData.RemoveEntry -f $HostName)
            if ($multiLineEntry -eq $true)
            {
                $newReplaceLine = $replace -replace $HostName, ""
                $hosts = $hosts -replace $replace, $newReplaceLine
            }
            else
            {
                $hosts = $hosts -replace $replace, ""
            }
        }
        $hosts | Set-Content -Path "$env:windir\System32\drivers\etc\hosts"
    }
}

<#
    .SYNOPSIS
    Tests the current state of a hosts file entry.

    .PARAMETER HostName
    Specifies the name of the computer that will be mapped to an IP address.

    .PARAMETER IPAddress
    Specifies the IP Address that should be mapped to the host name.

    .PARAMETER Ensure
    Specifies if the hosts file entry should be created or deleted.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $HostName,

        [System.String]
        $IPAddress,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    $currentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message ($LocalizedData.StartingTest -f $HostName)

    if ($Ensure -ne $currentValues.Ensure)
    {
        return $false
    }

    if ($Ensure -eq "Present" -and $IPAddress -ne $currentValues.IPAddress)
    {
        return $false
    }
    return $true
}
