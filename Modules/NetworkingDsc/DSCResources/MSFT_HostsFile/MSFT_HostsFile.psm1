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
    -ResourceName 'MSFT_HostsFile' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

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
        [System.String[]]
        $IPAddress,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($LocalizedData.StartingGet -f $HostName)

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
        [System.String[]]
        $IPAddress,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $hostPath = "$env:windir\System32\drivers\etc\hosts"
    $currentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message ($LocalizedData.StartingSet -f $HostName)

    if ($Ensure -eq 'Present' -and $PSBoundParameters.ContainsKey('IPAddress') -eq $false)
    {
        New-InvalidArgumentException `
            -Message $($($LocalizedData.UnableToEnsureWithoutIP) -f $Address, $AddressFamily) `
            -ArgumentName 'IPAddress'
    }

    if ($currentValues.Ensure -eq 'Absent' -and $Ensure -eq 'Present')
    {
        Write-Verbose -Message ($LocalizedData.CreateNewEntry -f $HostName)
        foreach ($desiredIp in $IPAddress)
        {
            Add-Content -Path $hostPath -Value "`r`n$desiredIp`t$HostName"
        }
    }
    else
    {
        $hosts = Get-Content -Path $hostPath

        <#
          Remove all entries. If Ensure is set to present,
          add the desired host name entries again.
        #>
        foreach ($hostAddress in (Get-HostEntry -HostName $HostName).IPAddress)
        {
            <#
              Replace all occurrences of $HostName
              as well as lines with a (now) lone IP address.
            #>
            $hosts = $hosts -replace "$($HostName -replace '\.','\.')"
            $hosts = $hosts -replace "^\s*[0-9.:]+\s+$"
        }

        if ($Ensure -eq 'Present')
        {
            foreach ($desiredIp in $IPAddress)
            {
                $hosts += "$desiredIp`t$HostName"
            }
        }

        $hosts = $hosts | Where-Object {-not [System.String]::IsNullOrWhiteSpace($_)}

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
        [System.String[]]
        $IPAddress,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $currentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message ($LocalizedData.StartingTest -f $HostName)

    if ($Ensure -ne $currentValues.Ensure)
    {
        return $false
    }

    # If Compare-Object returns anything, the list of entries is different from the desired state
    if ($Ensure -eq 'Present' -and (Compare-Object -ReferenceObject $IPAddress -DifferenceObject $currentValues.IPAddress))
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
    $hostContent = Get-Content -Encoding Ascii -Path $hostPath

    $allHosts = foreach ($line in $hostContent)
    {
        if ($line -match '^\s*(?<IpAddress>[0-9.:]+)\s+(?<HostName>[\w\s\.]+)')
        {
            if ([System.String]::IsNullOrWhiteSpace($Matches.HostName))
            {
                # If, for some reason, $Matches.HostName is empty, .Trim() will throw, so we skip the entry.
                Write-Verbose -Message ($LocalizedData.SkippingEmptyHost -f $Matches.IPAddress,$line)
                continue
            }

            $hostEntry = ($Matches.HostName).Trim()
            $ipEntry = $Matches.IpAddress

            [string[]] $multiLineHosts = $hostEntry -split '\s+'

            foreach ($multiLineHost in $multiLineHosts)
            {
                [PSCustomObject] @{
                    HostName = $multiLineHost
                    IpAddress = $Matches.IpAddress
                }
            }
        }
    }

    $filteredHosts = $allHosts | Where-Object HostName -eq $HostName

    if ($filteredHosts)
    {
        return ([PSCustomObject] @{
            HostName = $HostName
            IPAddress = [string[]] $filteredHosts.IpAddress
        })
    }
}
