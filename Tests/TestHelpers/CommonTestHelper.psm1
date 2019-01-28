<#
    .SYNOPSIS
        Returns an invalid argument exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
function Get-InvalidArgumentRecord
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' -ArgumentList @( $Message,
        $ArgumentName )
    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $argumentException, $ArgumentName, 'InvalidArgument', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
        Returns an invalid operation exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error
#>
function Get-InvalidOperationRecord
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $Message)
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException'
    }
    elseif ($null -eq $ErrorRecord)
    {
        $invalidOperationException =
            New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message )
    }
    else
    {
        $invalidOperationException =
            New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message,
                $ErrorRecord.Exception )
    }

    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $invalidOperationException.ToString(), 'MachineStateIncorrect',
            'InvalidOperation', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
        Determines if Network Team integration tests can be executed.

    .PARAMETER NetworkAdapters
        The network adapters that should be used for integration testing.
#>
function Test-NetworkTeamIntegrationEnvironment
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String[]]
        $NetworkAdapters
    )

    $executeTests = $true

    if ($env:APPVEYOR -eq $true)
    {
        Write-Warning -Message 'Performing Network Teaming integration tests on AppVeyor is not possible.'
        $executeTests = $false
    }

    if ($NetworkAdapters.Count -lt 2)
    {
        Write-Warning -Message (@(
            'Performing Network Teaming integration tests requires at least two compatible'
            'network adapters to be specified.'
            'Please see the comment based help in the header of the integration tests for'
            'instruction on how to specify the network adapters to use.'
        ) -join ' ')
        $executeTests = $false
    }

    foreach ($NetworkAdapter in $NetworkAdapters)
    {
        $adapter = Get-NetAdapter -Name $NetworkAdapter -ErrorAction SilentlyContinue
        if (-not $adapter)
        {
            Write-Warning -Message ('Network Teaming integration test adapter ''{0}'' could not be found.' -f $NetworkAdapter)
            $executeTests = $false
        }
    }

    return $executeTests
}

Export-ModuleMember -Function `
    Get-InvalidArgumentRecord, `
    Get-InvalidOperationRecord, `
    Test-NetworkTeamIntegrationEnvironment
