#######################################################################################
#  xNetworkAdapterName : DSC Resource that will set/test/get a network adapter name,
#  by accepting existing properties (given in xNetworkAdapterName.schema.mof)
#  other than the name and ensuring the name matches for that adapter
#######################################################################################

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
GettingNetAdapetrMessage=Getting the NetAdapter.
ApplyingNetAdapterMessage=Applying the NetAdapter.
NetAdapterSetStateMessage=NetAdapter was set to the desired state.
CheckingNetAdapterMessage=Checking the NetAdapter.
NetAdapterNotFoundError=A NetAdapter matching the properties was not found. Please correct the properties and try again.
MultipleMatchingNetAdapterFound=Multiple matching NetAdapters where found for the properties. Please correct the properties or specify IgnoreMultipleMatchingAdapters to only use the first and try again.
ApplyingWhileInDesiredStateMessage=
'@
}

######################################################################################
# The Get-TargetResource cmdlet.
# This function will get the present network adapter name based on the provided properties
######################################################################################
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateNotNullOrEmpty()]
        [String]$PhysicalMediaType = '802.3',

        [ValidateNotNullOrEmpty()]
        [ValidateSet('Up','Disconnected','Disabled')]
        [String]$Status = 'Up',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Bool] $IgnoreMultipleMatchingAdapters
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingNetAdapetrMessage)
        ) -join '')

    Test-ResourceProperty @PSBoundParameters
    
    $Adapter  =  @(Get-NetAdapter | Where-Object {$_.PhysicalMediaType -eq $PhysicalMediaType -and $_.Status -eq $Status})
    $exactAdapter = @($Adapter | Where-Object {$_.Name -eq $Name} )
    if($exactAdapter.Count -eq 0)
    {
        $exactAdapter = $Adapter
    }
    
    
    if($Adapter.Count -gt 0)
    {
        $returnValue = @{
            PhysicalMediaType    = $PhysicalMediaType
            Status               = $Status
            Name                 = $exactAdapter[0].Name
            InterfaceAlias       = $InterfaceAlias
            MatchingAdapterCount = $Adapter.Count
        }
    }
    else
    {
        $returnValue = @{
            PhysicalMediaType    = $PhysicalMediaType
            Status               = $Status
            Name                 = $null
            InterfaceAlias       = $InterfaceAlias
            MatchingAdapterCount = 0
        }
    }

    $returnValue
}

######################################################################################
# The Set-TargetResource cmdlet.
# This function will set a new network adapter name of the adapter found
# based on the provided properites
######################################################################################
function Set-TargetResource
{
    param
    (
        [ValidateNotNullOrEmpty()]
        [String]$PhysicalMediaType = '802.3',

        [ValidateNotNullOrEmpty()]
        [ValidateSet('Up','Disconnected','Disabled')]
        [String]$Status = 'Up',


        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Bool] $IgnoreMultipleMatchingAdapters
    )
    
    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.ApplyingNetAdapterMessage)
        ) -join '')

    # Get the current NetAdapter based on the parameters given.
    $getResults = Get-TargetResource @PSBoundParameters
    
    # Test if no adapter was found, if so return false
    if(!$getResults.Name)
    {
        $errorId = 'NetAdapterNotFound'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $LocalizedData.NetAdapterNotFoundError
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)        
    }
    elseif($getResults.MatchingAdapterCount -ne 1 -and !$IgnoreMultipleMatchingAdapters) # Test if a found adapter name mismatches, if so return false
    {
        $errorId = 'MultipleMatchingNetAdapterFound'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $LocalizedData.MultipleMatchingNetAdapterFound
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)        
    }
    elseif($getResults.name -ne $Name)
    {
        Rename-NetAdapter -Name $getResults.Name -NewName $Name
    }
    else
    {
        Write-Verbose -Message 'Already in desired state'
    }

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.NetAdapterSetStateMessage)
        ) -join '' )
} # Set-TargetResource

######################################################################################
# The Test-TargetResource cmdlet.
# This will test if the given Network adapter is named correctly
######################################################################################
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [ValidateNotNullOrEmpty()]
        [String]$PhysicalMediaType = '802.3',

        [ValidateNotNullOrEmpty()]
        [ValidateSet('Up','Disconnected','Disabled')]
        [String]$Status = 'Up',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Bool] $IgnoreMultipleMatchingAdapters
    )
    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.CheckingNetAdapterMessage)
        ) -join '')

    Test-ResourceProperty @PSBoundParameters

    # Get the current NetAdapter based on the parameters given.
    $getResults = Get-TargetResource @PSBoundParameters
    
    # Test if no adapter was found, if so return false
    if(!$getResults.Name)
    {
        $desiredConfigurationMatch = $false
    }
    elseif($getResults.Name -ne $Name) # Test if a found adapter name mismatches, if so return false
    {
        $desiredConfigurationMatch = $false
    }
    
    # return desiredConfigurationMatch     
    return $desiredConfigurationMatch
} # Test-TargetResource

#######################################################################################
#  Helper functions
#######################################################################################
function Test-ResourceProperty {
    # Function will check the propertes to find a network adapter 
    # are valid.
    # If any problems are detected an exception will be thrown.
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$PhysicalMediaType,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Up','Disconnected','Disabled')]
        [String]$Status,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Bool] $IgnoreMultipleMatchingAdapters
    )
    
    # TODO add any parameter validation

} # Test-ResourceProperty
#######################################################################################

#  FUNCTIONS TO BE EXPORTED
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
