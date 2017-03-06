﻿# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
    -ChildPath (Join-Path -Path 'NetworkingDsc.ResourceHelper' `
-ChildPath 'NetworkingDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
-ResourceName 'NetworkingDsc.Common' `
-ResourcePath $PSScriptRoot

<#
        .SYNOPSIS
        Converts any IP Addresses containing CIDR notation filters in an array to use Subnet Mask
        notation.

        .PARAMETER Address
        The array of addresses to that need to be converted.
#>
function Convert-CIDRToSubhetMask
{
    [CmdletBinding()]
    [OutputType([ Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Address
    )

    $results = @()
    foreach ($entry in $Address)
    {
        if (-not $entry.Contains(':') -and -not $entry.Contains('-'))
        {
            $entrySplit = $entry -split '/'
            if (-not [String]::IsNullOrEmpty($entrySplit[1]))
            {
                # There was a / so this contains a Subnet Mask or CIDR
                $prefix = $entrySplit[0]
                $postfix = $entrySplit[1]
                if ($postfix -match '^[0-9]*$')
                {
                    # The postfix contains CIDR notation so convert this to Subnet Mask
                    $cidr = [Int] $postfix
                    $subnetMaskInt64 = ([convert]::ToInt64(('1' * $cidr + '0' * (32 - $cidr)), 2))
                    $subnetMask = @(
                        ([math]::Truncate($subnetMaskInt64 / 16777216))
                        ([math]::Truncate(($subnetMaskInt64 % 16777216) / 65536))
                        ([math]::Truncate(($subnetMaskInt64 % 65536)/256))
                        ([math]::Truncate($subnetMaskInt64 % 256))
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
                $entry = '{0}/{1}' -f ($maskedIp -join '.'),($subnetMask -join '.')
            }
        }
        $results += $entry
    }
    return $results
}

function Remove-CommonParameter
{
    [OutputType([hashtable])]
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
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

function Test-DscParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)] 
        [hashtable]
        $CurrentValues,

        [Parameter(Mandatory)] 
        [object]
        $DesiredValues,
        
        [string[]]
        $ValuesToCheck,
        
        [switch]$TurnOffTypeChecking
    )

    $returnValue = $true

    $types = 'System.Management.Automation.PSBoundParametersDictionary', 'System.Collections.Hashtable', 'Microsoft.Management.Infrastructure.CimInstance'
    
    if ($DesiredValues.GetType().FullName -notin $types)
    {
        throw ("Property 'DesiredValues' in Test-DscParameterState must be either a Hashtable or CimInstance. Type detected was $($DesiredValues.GetType().Name)")
    }

    if ($DesiredValues.GetType().FullName -eq 'Microsoft.Management.Infrastructure.CimInstance' -and -not $ValuesToCheck)
    {
        throw ("If 'DesiredValues' is a CimInstance then property 'ValuesToCheck' must contain a value")
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
                Write-Verbose -Message "NOTMATCH: Type mismatch for property '$key' Current state type is '$($currentType.Name)' and desired type is '$($desiredType.Name)'"
                continue
            }
        }

        if ($CurrentValues.$key -eq $DesiredValuesClean.$key -and -not $desiredType.IsArray)
        {
            Write-Verbose -Message "MATCH: Value (type $($desiredType.Name)) for property '$key' does match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
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
            Write-Verbose -Message "MATCH: Value (type $($desiredType.Name)) for property '$key' does match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
            continue
        }
        
        if ($desiredType.IsArray)
        {
            Write-Verbose "Comparing values in property '$key'"
            if (-not $CurrentValues.ContainsKey($key) -or -not $CurrentValues.$key)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does not match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
                $returnValue = $false
                continue
            }
            elseif ($CurrentValues.$key.Count -ne $DesiredValues.$key.Count)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does have a different count. Current state count is '$($CurrentValues.$key.Count)' and desired state count is '$($DesiredValuesClean.$key.Count)'"
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
                            Write-Verbose -Message "`tNOTMATCH: Type mismatch for property '$key' Current state type of element [$i] is '$($currentType.Name)' and desired type is '$($desiredType.Name)'"
                            $returnValue = $false
                            continue
                        }
                    }
                        
                    if ($desiredArrayValues[$i] -ne $currentArrayValues[$i])
                    {
                        Write-Verbose -Message "`tNOTMATCH: Value [$i] (type $($desiredType.Name)) for property '$key' does match. Current state is '$($currentArrayValues[$i])' and desired state is '$($desiredArrayValues[$i])'"
                        $returnValue = $false
                        continue
                    }
                    else
                    {
                        Write-Verbose -Message "`tMATCH: Value [$i] (type $($desiredType.Name)) for property '$key' does match. Current state is '$($currentArrayValues[$i])' and desired state is '$($desiredArrayValues[$i])'"
                        continue
                    }
                }
                
            }
        } 
        else {
            if ($DesiredValuesClean.$key -ne $CurrentValues.$key)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does not match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
                $returnValue = $false
            }
        
        } 
    }
    
    Write-Verbose "Result is '$returnValue'"
    return $returnValue
}

function Test-DSCObjectHasProperty
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory)] 
        [object]
        $Object,

        [Parameter(Mandatory)]
        [string]
        $PropertyName
    )

    if ($Object.PSObject.Properties.Name -contains $PropertyName) 
    {
        return [bool]$Object.$PropertyName
    }
    
    return $false
}

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
