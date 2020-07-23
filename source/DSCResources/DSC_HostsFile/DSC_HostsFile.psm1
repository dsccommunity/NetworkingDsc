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

        [Parameter()]
        [System.String]
        $IPAddress,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.StartingGet -f $HostName)

    $result = Get-HostEntry -HostName $HostName

    if ($null -ne $result)
    {
        return @{
            HostName  = $result.HostName
            IPAddress = $result.IPAddress
            Ensure    = 'Present'
        }
    }
    else
    {
        return @{
            HostName  = $HostName
            IPAddress = $null
            Ensure    = 'Absent'
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

        [Parameter()]
        [System.String]
        $IPAddress,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $hostPath = "$env:windir\System32\drivers\etc\hosts"
    $currentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message ($script:localizedData.StartingSet -f $HostName)

    if ($Ensure -eq 'Present' -and $PSBoundParameters.ContainsKey('IPAddress') -eq $false)
    {
        New-InvalidArgumentException `
            -Message $($($script:localizedData.UnableToEnsureWithoutIP) -f $Address, $AddressFamily) `
            -ArgumentName 'IPAddress'
    }

    if ($currentValues.Ensure -eq 'Absent' -and $Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.CreateNewEntry -f $HostName)
        Add-Content -Path $hostPath -Value "`r`n$IPAddress`t$HostName"
    }
    else
    {
        $hosts = Get-Content -Path $hostPath
        $replace = $hosts | Where-Object -FilterScript {
            [System.String]::IsNullOrEmpty($_) -eq $false -and $_.StartsWith('#') -eq $false -and $_ -like "*$HostName*"
        }

        $multiLineEntry = $false
        $data = $replace -split '\s+'

        if ($data.Length -gt 2)
        {
            $multiLineEntry = $true
        }

        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.UpdateExistingEntry -f $HostName)

            if ($multiLineEntry -eq $true)
            {
                $newReplaceLine = $replace -replace $HostName, ''
                $hosts = $hosts -replace $replace, $newReplaceLine
                $hosts += "$IPAddress`t$HostName"
            }
            else
            {
                $hosts = $hosts -replace $replace, "$IPAddress`t$HostName"
            }
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.RemoveEntry -f $HostName)

            if ($multiLineEntry -eq $true)
            {
                $newReplaceLine = $replace -replace $HostName, ''
                $hosts = $hosts -replace $replace, $newReplaceLine
            }
            else
            {
                $hosts = $hosts -replace $replace, ''
            }
        }

        Set-Content -Path $hostPath -Value $hosts
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

        [Parameter()]
        [System.String]
        $IPAddress,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $currentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message ($script:localizedData.StartingTest -f $HostName)

    if ($Ensure -ne $currentValues.Ensure)
    {
        return $false
    }

    if ($Ensure -eq 'Present' -and $IPAddress -ne $currentValues.IPAddress)
    {
        return $false
    }

    return $true
}

function Get-HostEntry
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $HostName
    )

    $hostPath = "$env:windir\System32\drivers\etc\hosts"

    $allHosts = Get-Content -Path $hostPath | Where-Object -FilterScript {
        [System.String]::IsNullOrEmpty($_) -eq $false -and $_.StartsWith('#') -eq $false
    }

    foreach ($hosts in $allHosts)
    {
        $data = $hosts -split '\s+'

        if ($data.Length -gt 2)
        {
            # Account for host entries that have multiple entries on a single line
            $result = @()
            $array = @()

            for ($i = 1; $i -lt $data.Length; $i++)
            {
                <#
                    Filter commments on the line.
                    Example: 0.0.0.0 s.gateway.messenger.live.com # breaks Skype GH-183
                    becomes:
                    0.0.0.0 s.gateway.messenger.live.com
                #>
                if ($data[$i] -eq '#')
                {
                    break
                }

                $array += $data[$i]
            }

            $result = @{
                Host      = $array
                IPAddress = $data[0]
            }
        }
        else
        {
            $result = @{
                Host      = $data[1]
                IPAddress = $data[0]
            }
        }

        if ($result.Host -eq $HostName)
        {
            return @{
                HostName  = $result.Host
                IPAddress = $result.IPAddress
            }
        }
    }
}
