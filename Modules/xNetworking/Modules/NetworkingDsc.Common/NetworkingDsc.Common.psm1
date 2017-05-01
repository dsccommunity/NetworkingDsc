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
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Address
    )

    $Results = @()
    foreach ($Entry in $Address)
    {
        if (-not $Entry.Contains(':') -and -not $Entry.Contains('-'))
        {
            $EntrySplit = $Entry -split '/'
            if (-not [String]::IsNullOrEmpty($EntrySplit[1]))
            {
                # There was a / so this contains a Subnet Mask or CIDR
                $Prefix = $EntrySplit[0]
                $Postfix = $EntrySplit[1]
                if ($Postfix -match '^[0-9]*$')
                {
                    # The postfix contains CIDR notation so convert this to Subnet Mask
                    $Cidr = [Int] $Postfix
                    $SubnetMaskInt64 = ([convert]::ToInt64(('1' * $Cidr + '0' * (32 - $Cidr)), 2))
                    $SubnetMask = @(
                        ([math]::Truncate($SubnetMaskInt64 / 16777216))
                        ([math]::Truncate(($SubnetMaskInt64 % 16777216) / 65536))
                        ([math]::Truncate(($SubnetMaskInt64 % 65536)/256))
                        ([math]::Truncate($SubnetMaskInt64 % 256))
                    )
                }
                else
                {
                    $SubnetMask = $Postfix -split '\.'
                }
                # Apply the Subnet Mast to the IP Address so that we end up with a correctly
                # masked IP Address that will match what the Firewall rule returns.
                $MaskedIp = $Prefix -split '\.'
                for ([int] $Octet = 0; $Octet -lt 4; $Octet++)
                {
                    $MaskedIp[$Octet] = $MaskedIp[$Octet] -band $SubnetMask[$Octet]
                }
                $Entry = '{0}/{1}' -f ($MaskedIp -join '.'),($SubnetMask -join '.')
            }
        }
        $Results += $Entry
    }
    return $Results
}

function Test-DscParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)] 
        [HashTable]$CurrentValues,

        [Parameter(Mandatory)] 
        [Object]
        $DesiredValues,
        
        [string[]]$ValuesToCheck
    )

    $returnValue = $true

    $types = 'System.Management.Automation.PSBoundParametersDictionary', 'System.Collections.Hashtable', 'Microsoft.Management.Infrastructure.CimInstance'
    
    if ($DesiredValues.GetType().FullName -notin $types)
    {
        throw ("Property 'DesiredValues' in Test-SPDscParameterState must be either a Hashtable or CimInstance. Type detected was $($DesiredValues.GetType().Name)")
    }

    if ($DesiredValues.GetType().FullName -eq 'Microsoft.Management.Infrastructure.CimInstance' -and -not $ValuesToCheck)
    {
        throw ("If 'DesiredValues' is a CimInstance then property 'ValuesToCheck' must contain a value")
    }
    
    if ($DesiredValues.ContainsKey('Verbose')) { $null = $DesiredValues.Remove('Verbose') }

    if (-not $ValuesToCheck)
    { $keyList = $DesiredValues.Keys } 
    else
    { $keyList = $ValuesToCheck }

    foreach ($key in $keyList)
    {
        #check for verbose key?
        
        if ($CurrentValues.$key -eq $DesiredValues.$key)
        {
            Write-Verbose -Message "MATCH: $($desiredType.Name) value for property '$key' does match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValues.$key)'"
            continue
        }
                    
        if ($DesiredValues.GetType().Name -in 'HashTable', 'PSBoundParametersDictionary')
        {
            $checkDesiredValue = $DesiredValues.ContainsKey($key)
        } 
        else
        {
            $checkDesiredValue = Test-DSCObjectHasProperty -Object $DesiredValues -PropertyName $key
        }
        
        if (-not $checkDesiredValue)
        {
            Write-Verbose -Message "MATCH: $($desiredType.Name) value for property '$key' does match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValues.$key)'"
            continue
        }
        
 
        $desiredType = $DesiredValues.$key.GetType()
            
        if ($desiredType.IsArray)
        {
            if (-not $CurrentValues.ContainsKey($key) -or -not $CurrentValues.$key)
            {
                Write-Verbose -Message "Expected to find an array value for property '$key' in the current values, but it was either not present or was null. This has caused the test method to return false."
                $returnValue = $false
            } 
            else
            {
                $arrayCompare = Compare-Object -ReferenceObject $CurrentValues.$key -DifferenceObject $DesiredValues.$key
                if (-not $arrayCompare) 
                {
                    Write-Verbose -Message "Found an array for property '$key' in the current values, but this array does not match the desired state. Details of the changes are below."
                    foreach ($entry in $arrayCompare)
                    {
                        #does this work?
                        Write-Verbose -Message "$($entry.InputObject) - $($key.SideIndicator)"
                    }
                    $returnValue = $false
                }
            }
        } 
        else {
            if ($DesiredValues.$key -ne $CurrentValues.$key)
            {
                Write-Verbose -Message "NOTMATCH: $($desiredType.Name) value for property '$key' does not match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValues.$key)'"
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
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)] 
        [object]$Object,

        [Parameter(Mandatory)]
        [string]$PropertyName
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
        [string]$ErrorId,

        [Parameter(Mandatory)]
        [string]$ErrorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory]$ErrorCategory
    )

    $exception = New-Object System.InvalidOperationException $errorMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
}

#Export-ModuleMember -Function Convert-CIDRToSubhetMask
