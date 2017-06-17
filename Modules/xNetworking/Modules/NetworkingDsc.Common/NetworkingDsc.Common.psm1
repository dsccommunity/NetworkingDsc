# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath (Join-Path -Path 'NetworkingDsc.ResourceHelper' `
            -ChildPath 'NetworkingDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'NetworkingDsc.Common' `
    -ResourcePath $PSScriptRoot

<#
.SYNOPSIS
Converts any IP Addresses containing cIDR notation filters in an array to use Subnet Mask
notation.

.PARAMETER Address
The array of addresses to that need to be converted.
#>
function Convert-CidrToSubhetMask
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Address
    )

    $results = @()
    
    foreach ($entry in $Address)
    {
        if (-not $entry.Contains(':') -and -not $entry.Contains('-'))
        {
            $entrySplit = $entry -split '/'
            if (-not [String]::IsNullOrEmpty($entrySplit[1]))
            {
                # There was a / so this contains a Subnet Mask or cIDR
                $prefix = $entrySplit[0]
                $postfix = $entrySplit[1]
                if ($postfix -match '^[0-9]*$')
                {
                    # The postfix contains cIDR notation so convert this to Subnet Mask
                    $cidr = [Int] $postfix
                    $subnetMaskInt64 = ([convert]::ToInt64(('1' * $cidr + '0' * (32 - $cidr)), 2))
                    $subnetMask = @(
                        ([System.Math]::Truncate($subnetMaskInt64 / 16777216))
                        ([System.Math]::Truncate(($subnetMaskInt64 % 16777216) / 65536))
                        ([System.Math]::Truncate(($subnetMaskInt64 % 65536) / 256))
                        ([System.Math]::Truncate($subnetMaskInt64 % 256))
                    )
                }
                else
                {
                    $subnetMask = $postfix -split '\.'
                }
                # Apply the Subnet Mast to the IP Address so that we end up with a correctly
                # masked IP Address that will match what the Firewall rule returns.
                $maskedIp = $prefix -split '\.'
                for ([int] $octet = 0; $octet -lt 4; $octet++)
                {
                    $maskedIp[$octet] = $maskedIp[$octet] -band $subnetMask[$octet]
                }
                $entry = '{0}/{1}' -f ($maskedIp -join '.'), ($subnetMask -join '.')
            }
        }
        $results += $entry
    }
    return $results
} # Convert-cIDRToSubhetMask

<#
.SYNOPSIS
This function will find a network adapter based on the provided
search parameters.

.PARAMETER Name
This is the name of network adapter to find.

.PARAMETER PhysicalMediaType
This is the media type of the network adapter to find.

.PARAMETER Status
This is the status of the network adapter to find.

.PARAMETER MacAddress
This is the MAC address of the network adapter to find.

.PARAMETER InterfaceDescription
This is the interface description of the network adapter to find.

.PARAMETER InterfaceIndex
This is the interface index of the network adapter to find.

.PARAMETER InterfaceGuid
This is the interface GUID of the network adapter to find.

.PARAMETER DriverDescription
This is the driver description of the network adapter.

.PARAMETER InterfaceNumber
This is the interface number of the network adapter if more than one
are returned by the parameters.

.PARAMETER IgnoreMultipleMatchingAdapters
This switch will suppress an error occurring if more than one matching
adapter matches the parameters passed.
#>
function Find-NetworkAdapter
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $PhysicalMediaType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Up', 'Disconnected', 'Disabled')]
        [System.String]
        $Status = 'Up',

        [Parameter()]
        [System.String]
        $MacAddress,

        [Parameter()]
        [System.String]
        $InterfaceDescription,

        [Parameter()]
        [System.UInt32]
        $InterfaceIndex,

        [Parameter()]
        [System.String]
        $InterfaceGuid,

        [Parameter()]
        [System.String]
        $DriverDescription,

        [Parameter()]
        [System.UInt32]
        $InterfaceNumber = 1,

        [Parameter()]
        [System.Boolean]
        $IgnoreMultipleMatchingAdapters = $false
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($localizedData.FindingNetAdapterMessage)
        ) -join '')

    $adapterFilters = @()
    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $adapterFilters += @('($_.Name -eq $Name)')
    } # if

    if ($PSBoundParameters.ContainsKey('PhysicalMediaType'))
    {
        $adapterFilters += @('($_.PhysicalMediaType -eq $PhysicalMediaType)')
    } # if

    if ($PSBoundParameters.ContainsKey('Status'))
    {
        $adapterFilters += @('($_.Status -eq $Status)')
    } # if

    if ($PSBoundParameters.ContainsKey('MacAddress'))
    {
        $adapterFilters += @('($_.MacAddress -eq $MacAddress)')
    } # if

    if ($PSBoundParameters.ContainsKey('InterfaceDescription'))
    {
        $adapterFilters += @('($_.InterfaceDescription -eq $InterfaceDescription)')
    } # if

    if ($PSBoundParameters.ContainsKey('InterfaceIndex'))
    {
        $adapterFilters += @('($_.InterfaceIndex -eq $InterfaceIndex)')
    } # if

    if ($PSBoundParameters.ContainsKey('InterfaceGuid'))
    {
        $adapterFilters += @('($_.InterfaceGuid -eq $InterfaceGuid)')
    } # if

    if ($PSBoundParameters.ContainsKey('DriverDescription'))
    {
        $adapterFilters += @('($_.DriverDescription -eq $DriverDescription)')
    } # if

    if ($adapterFilters.Count -eq 0)
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($localizedData.AllNetAdaptersFoundMessage)
            ) -join '')

        $matchingAdapters = @(Get-NetAdapter)
    }
    else
    {
        # Join all the filters together
        $adapterFilterScript = '(' + ($adapterFilters -join ' -and ') + ')'
        $matchingAdapters = @(Get-NetAdapter |
                Where-Object -FilterScript ([ScriptBlock]::Create($adapterFilterScript)))
    }

    # Were any adapters found matching the criteria?
    if ($matchingAdapters.Count -eq 0)
    {
        New-InvalidOperationException `
            -Message ($localizedData.NetAdapterNotFoundError)

        # Return a null so that ErrorAction SilentlyContinue works correctly
        return $null
    }
    else
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($localizedData.NetAdapterFoundMessage -f $matchingAdapters.Count)
            ) -join '')

        if ($matchingAdapters.Count -gt 1)
        {
            if ($IgnoreMultipleMatchingAdapters)
            {
                # Was the number of matching adapters found matching the adapter number?
                if (($InterfaceNumber -gt 1) -and ($InterfaceNumber -gt $matchingAdapters.Count))
                {
                    New-InvalidOperationException `
                        -Message ($localizedData.InvalidNetAdapterNumberError `
                            -f $matchingAdapters.Count, $InterfaceNumber)

                    # Return a null so that ErrorAction SilentlyContinue works correctly
                    return $null
                } # if
            }
            else
            {
                New-InvalidOperationException `
                    -Message ($localizedData.MultipleMatchingNetAdapterFound `
                        -f $matchingAdapters.Count)

                # Return a null so that ErrorAction SilentlyContinue works correctly
                return $null
            } # if
        } # if
    } # if

    # Identify the exact adapter from the adapters that match
    $exactAdapter = $matchingAdapters[$InterfaceNumber - 1]

    $returnValue = [PSCustomObject] @{
        Name                 = $exactAdapter.Name
        PhysicalMediaType    = $exactAdapter.PhysicalMediaType
        Status               = $exactAdapter.Status
        MacAddress           = $exactAdapter.MacAddress
        InterfaceDescription = $exactAdapter.InterfaceDescription
        InterfaceIndex       = $exactAdapter.InterfaceIndex
        InterfaceGuid        = $exactAdapter.InterfaceGuid
        MatchingAdapterCount = $matchingAdapters.Count
    }

    return $returnValue
} # Find-NetworkAdapter

<#
.SYNOPSIS
Remove all common parameters form a hashtable

.DESCRIPTION
Remove all common parameters form a hashtable

.PARAMETER Hashtable
The hashtable with the parameters

.EXAMPLE
$DesiredValuesClean = Remove-CommonParameter -Hashtable $DesiredValues
#>

function Remove-CommonParameter
{
    [OutputType([hashtable])]
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Hashtable
    )

    $inputClone = $Hashtable.Clone()
    $commonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
    $commonParameters += [System.Management.Automation.PSCmdlet]::OptionalCommonParameters

    $Hashtable.Keys | Where-Object { $_ -in $commonParameters } | ForEach-Object {
        $inputClone.Remove($_)
    }

    $inputClone
}

<#
.SYNOPSIS
This function compares the current and the desired state

.DESCRIPTION
This function compares the current and the desired state.

.PARAMETER CurrentValues
The current state that is taken from Get-TargetResource

.PARAMETER DesiredValues
The desired state that is taken from PSBoundParameters

.PARAMETER ValuesToCheck
If you provide a CIM instance as the DesiredValues, you need to specify the properties to compare

.PARAMETER TurnOffTypeChecking
By default this function compares the values and the types. If you do not want to compare types, you can turn it off here.

.EXAMPLE
$currentState = Get-TargetResource @PSBoundParameters
$result = Test-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters
return $result
#>
function Test-DscParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)] 
        [hashtable]
        $CurrentValues,

        [Parameter(Mandatory = $true)] 
        [object]
        $DesiredValues,

        [Parameter()]
        [string[]]
        $ValuesToCheck,

        [Parameter()]
        [switch]
        $TurnOffTypeChecking
    )

    $returnValue = $true

    $types = 'System.Management.Automation.PSBoundParametersDictionary', 'System.Collections.Hashtable', 'Microsoft.Management.Infrastructure.CimInstance'

    if ($DesiredValues.GetType().FullName -notin $types)
    {
        throw ($localizedData.TestDscParameterState_DesiredValueWrongType -f $DesiredValues.GetType().Name)
    }

    if ($DesiredValues.GetType().FullName -eq 'Microsoft.Management.Infrastructure.CimInstance' -and -not $ValuesToCheck)
    {
        throw $localizedData.TestDscParameterState_DesiredValueIsCimInstanceAndNotValueToCheck
    }

    $DesiredValuesClean = Remove-CommonParameter -Hashtable $DesiredValues

    if (-not $ValuesToCheck)
    {
        $keyList = $DesiredValuesClean.Keys
    } 
    else
    {
        $keyList = $ValuesToCheck
    }

    foreach ($key in $keyList)
    {
        if ($null -ne $DesiredValuesClean.$key)
        {
            $desiredType = $DesiredValuesClean.$key.GetType()
        }
        else
        {
            $desiredType = [psobject]@{ Name = 'Unknown' }
        }

        if ($null -ne $CurrentValues.$key)
        {
            $currentType = $CurrentValues.$key.GetType()
        }
        else
        {
            $currentType = [psobject]@{ Name = 'Unknown' }
        }

        if (-not $TurnOffTypeChecking)
        {   
            if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and 
                $desiredType.FullName -ne $currentType.FullName)
            {
                Write-Verbose -Message ($localizedData.TestDscParameterState_NotMatchTypeMismatch -f $key, $currentType.Name, $desiredType.Name)
                continue
            }
        }

        if ($CurrentValues.$key -eq $DesiredValuesClean.$key -and -not $desiredType.IsArray)
        {
            Write-Verbose -Message ($localizedData.TestDscParameterState_Match -f $desiredType.Name, $key, $CurrentValues.$key, $DesiredValuesClean.$key)
            continue
        }

        if ($DesiredValuesClean.GetType().Name -in 'HashTable', 'PSBoundParametersDictionary')
        {
            $checkDesiredValue = $DesiredValuesClean.ContainsKey($key)
        } 
        else
        {
            $checkDesiredValue = Test-DSCObjectHasProperty -Object $DesiredValuesClean -PropertyName $key
        }

        if (-not $checkDesiredValue)
        {
            Write-Verbose -Message ($localizedData.TestDscParameterState_Match -f $desiredType.Name, $key, $CurrentValues.$key, $DesiredValuesClean.$key)
            continue
        }

        if ($desiredType.IsArray)
        {
            Write-Verbose "Comparing values in property '$key'"
            if (-not $CurrentValues.ContainsKey($key) -or -not $CurrentValues.$key)
            {
                Write-Verbose -Message ($localizedData.TestDscParameterState_NotMatch -f $desiredType.Name, $key, $CurrentValues.$key, $DesiredValuesClean.$key)
                $returnValue = $false
                continue
            }
            elseif ($CurrentValues.$key.Count -ne $DesiredValues.$key.Count)
            {
                Write-Verbose -Message ($localizedData.TestDscParameterState_NotMatchDifferentCount -f $desiredType.Name, $key, $CurrentValues.$key.Count, $DesiredValuesClean.$key.Count)
                $returnValue = $false
                continue
            }
            else
            {
                $desiredArrayValues = $DesiredValues.$key
                $currentArrayValues = $CurrentValues.$key

                for ($i = 0; $i -lt $desiredArrayValues.Count; $i++)
                {
                    if ($null -ne $desiredArrayValues[$i])
                    {
                        $desiredType = $desiredArrayValues[$i].GetType()
                    }
                    else
                    {
                        $desiredType = [psobject]@{ Name = 'Unknown' }
                    }

                    if ($null -ne $currentArrayValues[$i])
                    {
                        $currentType = $currentArrayValues[$i].GetType()
                    }
                    else
                    {
                        $currentType = [psobject]@{ Name = 'Unknown' }
                    }

                    if (-not $TurnOffTypeChecking)
                    {
                        if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and 
                            $desiredType.FullName -ne $currentType.FullName)
                        {
                            Write-Verbose -Message ($localizedData.TestDscParameterState_NotMatchArrayElementTypeMismatch -f $key, $i, $currentType.Name, $desiredType.Name)
                            $returnValue = $false
                            continue
                        }
                    }

                    if ($desiredArrayValues[$i] -ne $currentArrayValues[$i])
                    {
                        Write-Verbose -Message ($localizedData.TestDscParameterState_NotMatchArrayElement -f $i, $desiredType.Name, $key, $currentArrayValues[$i], $desiredArrayValues[$i])
                        $returnValue = $false
                        continue
                    }
                    else
                    {
                        Write-Verbose -Message ($localizedData.TestDscParameterState_MatchArrayElement -f $i, $desiredType.Name, $key, $currentArrayValues[$i], $desiredArrayValues[$i])
                        continue
                    }
                }
            }
        } 
        else
        {
            if ($DesiredValuesClean.$key -ne $CurrentValues.$key)
            {
                Write-Verbose -Message ($localizedData.TestDscParameterState_NotMatch -f $desiredType.Name, $key, $CurrentValues.$key, $DesiredValuesClean.$key)
                $returnValue = $false
            }
        } 
    }

    Write-Verbose "Result is '$returnValue'"
    return $returnValue
}

<#
.SYNOPSIS
Tests if an object has a property

.DESCRIPTION
Tests if an object has a property

.PARAMETER Object
The object to look for the property

.PARAMETER PropertyName
The name of the property to look for

.EXAMPLE
$checkDesiredValue = Test-DSCObjectHasProperty -Object $DesiredValuesClean -PropertyName $key
#>
function Test-DSCObjectHasProperty
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)] 
        [object]
        $Object,

        [Parameter(Mandatory = $true)]
        [string]
        $PropertyName
    )

    if ($Object.PSObject.Properties.Name -contains $PropertyName)
    {
        return [bool]$Object.$PropertyName
    }

    return $false
}

<#
.SYNOPSIS
Throws a terminating error

.DESCRIPTION
Throws a terminating error

.PARAMETER ErrorId
The error ID

.PARAMETER ErrorMessage
The error desciption

.PARAMETER ErrorCategory
The error category

.EXAMPLE
$errorParam = @{
    ErrorId = 'NicNotFound'
    ErrorMessage = ($localizedData.NicNotFound -f $InterfaceAlias)
    ErrorCategory = 'ObjectNotFound'
    ErrorAction = 'Stop'
}
New-TerminatingError @errorParam
#>

function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ErrorId,

        [Parameter(Mandatory)]
        [string]
        $ErrorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )

    $exception = New-Object System.InvalidOperationException $errorMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
}

Export-ModuleMember -Function Convert-cIDRToSubhetMask,
Find-NetworkAdapter,
Test-DSCObjectHasProperty,
Test-DscParameterState,
Remove-CommonParameter,
New-TerminatingError
