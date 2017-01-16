# Get the path to the shared modules folder
$script:ModulesFolderPath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent)) `
                                      -ChildPath 'Modules'

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $script:ModulesFolderPath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.ResourceHelper' `
                                                     -ChildPath 'NetworkingDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xNetAdapterBinding' `
    -ResourcePath $PSScriptRoot

# Import the common networking functions
Import-Module -Name (Join-Path -Path $script:ModulesFolderPath `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.Common' `
                                                     -ChildPath 'NetworkingDsc.Common.psm1'))

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ComponentId,

        [ValidateSet('Enabled', 'Disabled')]
        [String]$State = 'Enabled'
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingNetAdapterBindingMessage -f `
            $InterfaceAlias,$ComponentId)
        ) -join '')

    $CurrentNetAdapterBinding = Get-Binding @PSBoundParameters

    $AdaptersState = $CurrentNetAdapterBinding.Enabled |
        Sort-Object -Unique

    If ( $AdaptersState.Count -eq 2)
    {
        $CurrentEnabled = 'Mixed'
    }
    ElseIf ( $AdaptersState -eq $true )
    {
        $CurrentEnabled = 'Enabled'
    }
    Else
    {
        $CurrentEnabled = 'Disabled'
    }

    $returnValue = @{
        InterfaceAlias = $InterfaceAlias
        ComponentId    = $ComponentId
        State          = $State
        CurrentState   = $CurrentEnabled
    }

    $returnValue
} # Get-TargetResource

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ComponentId,

        [ValidateSet('Enabled', 'Disabled')]
        [String]$State = 'Enabled'
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.ApplyingNetAdapterBindingMessage -f `
            $InterfaceAlias,$ComponentId)
        ) -join '')

    $CurrentNetAdapterBinding = Get-Binding @PSBoundParameters

    # Remove the State so we can splat
    $null = $PSBoundParameters.Remove('State')

    if ($State -eq 'Enabled')
    {
        Enable-NetAdapterBinding @PSBoundParameters
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.NetAdapterBindingEnabledMessage -f `
                $InterfaceAlias,$ComponentId)
            ) -join '' )
    }
    else
    {
        Disable-NetAdapterBinding @PSBoundParameters
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.NetAdapterBindingDisabledMessage -f `
                $InterfaceAlias,$ComponentId)
            ) -join '' )
    } # if
} # Set-TargetResource

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ComponentId,

        [ValidateSet('Enabled', 'Disabled')]
        [String]$State = 'Enabled'
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.CheckingNetAdapterBindingMessage -f `
            $InterfaceAlias,$ComponentId)
        ) -join '')

    $CurrentNetAdapterBinding = Get-Binding @PSBoundParameters

    $AdaptersState = $CurrentNetAdapterBinding.Enabled |
        Sort-Object -Unique

    If ( $AdaptersState.Count -eq 2)
    {
        $CurrentEnabled = 'Mixed'
    }
    ElseIf ( $AdaptersState -eq $true )
    {
        $CurrentEnabled = 'Enabled'
    }
    Else
    {
        $CurrentEnabled = 'Disabled'
    }

    # Test if the binding is in the correct state
    if ($CurrentEnabled -ne $State)
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.NetAdapterBindingDoesNotMatchMessage -f `
                $InterfaceAlias,$ComponentId,$State,$CurrentEnabled)
            ) -join '' )
        return $false
    }
    else
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.NetAdapterBindingMatchMessage -f `
                $InterfaceAlias,$ComponentId)
            ) -join '' )
        return $true
    } # if
} # Test-TargetResource

function Get-Binding {
    # Function ensures the interface and component Id exists and
    # returns the Net Adapter binding object.
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ComponentId,

        [ValidateSet('Enabled', 'Disabled')]
        [String]$State = 'Enabled'
    )

    if (-not (Get-NetAdapter -Name $InterfaceAlias -ErrorAction SilentlyContinue))
    {
        $errorId = 'InterfaceNotAvailable'
        $errorCategory = [System.Management.Automation.ErrorCategory]::DeviceError
        $errorMessage = $($LocalizedData.InterfaceNotAvailableError) -f $InterfaceAlias
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    } # if

    $Binding = Get-NetAdapterBinding `
        -InterfaceAlias $InterfaceAlias `
        -ComponentId $ComponentId `
        -ErrorAction Stop

    return $Binding
} # Get-Binding

Export-ModuleMember -function *-TargetResource
