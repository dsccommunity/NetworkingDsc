# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
ConvertFrom-StringData @'    
    getTeamInfo=Getting network team information for {0}.
    foundTeam=Found a network team with name {0}.
    teamMembersExist=Members in the network team {0} exist as per the configuration.
    teamNotFound=Network team with name {0} not found.
    lbAlgoDifferent=Load Balancing Algo is different from the requested {0} algo.
    teamingModeDifferent=Teaming mode is different from the requested {0} mode.
    modifyTeam=Modifying the network team named {0}.
    membersDifferent=Members within the team named {0} are different from that requested in the configuration.
    removingMembers=Removing members {0} not specified in the configuration.
    addingMembers=Adding members {0} that are not a part of the team configuration.
    createTeam=Creating a network team with the name {0}.
    removeTeam=Removing a network team with the name {0}.
    teamExistsNoAction=Network team with name {0} exists. No action needed.
    teamExistsWithDifferentConfig=Network team with name {0} exists but with different configuration. This will be modified.
    teamDoesNotExistShouldCreate=Network team with name {0} does not exist. It will be created.
    teamExistsShouldRemove=Network team with name {0} exists. It will be removed.
    teamDoesNotExistNoAction=Network team with name {0} does not exist. No action needed.
    waitingForTeam=Waiting for network team status to change to up.
    createdNetTeam=Network Team was created successfully.
    failedToCreateTeam=Network team with specific configuration failed to changed to up state within timeout period of 120 seconds.
'@
}

if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename MSFT_NetworkTeam.psd1 -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}

Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])] 
    Param
    (
        [Parameter(Mandatory)]
        [string]$name,

        [Parameter(Mandatory)]
        [String[]]$teamMembers
    )
    
    $configuration = @{
        name = $name
        teamMembers = $teamMembers
    }

    Write-Verbose ($localizedData.GetTeamInfo -f $name)
    $networkTeam = Get-NetLBFOTeam -Name $name -ErrorAction SilentlyContinue

    if ($networkTeam) 
    {
        Write-Verbose ($localizedData.FoundTeam -f $name)
        if ($null -eq (Compare-Object -ReferenceObject $teamMembers -DifferenceObject $networkTeam.Members))
        {
            Write-Verbose ($localizedData.teamMembersExist -f $name)
            $configuration.Add('loadBalancingAlgorithm', $networkTeam.loadBalancingAlgorithm)
            $configuration.Add('teamingMode', $networkTeam.teamingMode)
            $configuration.Add('ensure','Present')
        }
    }
    else
    {
        Write-Verbose ($localizedData.TeamNotFound -f $name)
        $Configuration.Add('ensure','Absent')
    }
    $Configuration
}

Function Set-TargetResource 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$name,

        [Parameter(Mandatory)]
        [String[]]$teamMembers,
    
        [Parameter()]
        [ValidateSet("SwitchIndependent", "LACP", "Static")]
        [String]$teamingMode = "SwitchIndependent",

        [Parameter()]
        [ValidateSet("Dynamic", "HyperVPort", "IPAddresses", "MacAddresses", "TransportPorts")]
        [String]$loadBalancingAlgorithm = "HyperVPort",

        [ValidateSet('Present', 'Absent')]
        [String]$ensure = 'Present'
    )
    Write-Verbose ($localizedData.GetTeamInfo -f $name)
    $networkTeam = Get-NetLBFOTeam -Name $name -ErrorAction SilentlyContinue

    if ($Ensure -eq 'Present')
    {
        if ($networkTeam)
        {
            Write-Verbose ($localizedData.foundTeam -f $name)
            $setArguments = @{
                'name' = $name
            }

            if ($networkTeam.loadBalancingAlgorithm -ne $loadBalancingAlgorithm)
            {
                Write-Verbose ($localizedData.lbAlgoDifferent -f $loadBalancingAlgorithm)
                $SetArguments.Add('loadBalancingAlgorithm', $loadBalancingAlgorithm)
                $isNetModifyRequired = $true
            }

            if ($networkTeam.TeamingMode -ne $teamingMode)
            {
                Write-Verbose ($localizedData.teamingModeDifferent -f $teamingMode)
                $setArguments.Add('teamingMode', $teamingMode)
                $isNetModifyRequired = $true
            }
            
            if ($isNetModifyRequired)
            {
                Write-Verbose ($localizedData.modifyTeam -f $name)
                Set-NetLbfoTeam @setArguments -ErrorAction Stop -Confirm:$false
            }

            $netTeamMembers = Compare-Object -ReferenceObject $teamMembers -DifferenceObject $networkTeam.Members
            if ($null -ne $netTeamMembers)
            {
                Write-Verbose ($localizedData.membersDifferent -f $name)
                $membersToRemove = ($netTeamMembers | Where-Object {$_.SideIndicator -eq '=>'}).InputObject
                if ($membersToRemove)
                {
                    Write-Verbose ($localizedData.removingMembers -f ($membersToRemove -join ','))
                    $null = Remove-NetLbfoTeamMember -Name $membersToRemove -Team $name -ErrorAction Stop -Confirm:$false
                }

                $membersToAdd = ($netTeamMembers | Where-Object {$_.SideIndicator -eq '<='}).InputObject
                if ($membersToAdd)
                {
                    Write-Verbose ($localizedData.addingMembers -f ($membersToAdd -join ','))
                    $null = Add-NetLbfoTeamMember -Name $membersToAdd -Team $name -ErrorAction Stop -Confirm:$false
                }
            }
            
        } 
        else 
        {
            Write-Verbose ($localizedData.createTeam -f $name)
            $null = New-NetLbfoTeam -Name $name -TeamMembers $teamMembers -TeamingMode $teamingMode -LoadBalancingAlgorithm $loadBalancingAlgorithm -ErrorAction Stop -Confirm:$false
            $timeout = 0
            While ((Get-NetLbfoTeam -Name $name).status -ne 'Up')
            {
                Write-Verbose $localizedData.waitingForTeam
                if ($timeout -ge 120)
                {
                    throw $localizedData.failedToCreateTeam   
                }
                Start-Sleep -Seconds 2
                $timeout += 2
            }

            if ((Get-NetLbfoTeam -Name $name).status -eq 'Up')
            {
                Write-Verbose $localizedData.createdNetTeam
            }
        }
    }
    else
    {
        Write-Verbose ($localizedData.removeTeam -f $name)
        $null = Remove-NetLbfoTeam -Name $name -ErrorAction Stop -Confirm:$false
    }
}

Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        [Parameter(Mandatory)]
        [string]$name,

        [Parameter(Mandatory)]
        [String[]]$teamMembers,
    
        [Parameter()]
        [ValidateSet("SwitchIndependent", "LACP", "Static")]
        [String]$teamingMode = "SwitchIndependent",

        [Parameter()]
        [ValidateSet("Dynamic", "HyperVPort", "IPAddresses", "MacAddresses", "TransportPorts")]
        [String]$loadBalancingAlgorithm = "HyperVPort",

        [ValidateSet('Present', 'Absent')]
        [String]$ensure = 'Present'
    )
    
    Write-Verbose ($localizedData.GetTeamInfo -f $name)
    $networkTeam = Get-NetLBFOTeam -Name $name -ErrorAction SilentlyContinue
    
    if ($ensure -eq 'Present')
    {
        if ($networkTeam)
        {
            Write-Verbose ($localizedData.foundTeam -f $name)
            if (
                ($networkTeam.LoadBalancingAlgorithm -eq $loadBalancingAlgorithm) -and 
                ($networkTeam.teamingMode -eq $teamingMode) -and 
                ($null -eq (Compare-Object -ReferenceObject $teamMembers -DifferenceObject $networkTeam.Members))
            )
            {
                Write-Verbose ($localizedData.teamExistsNoAction -f $name)
                return $true
            }
            else
            {
                Write-Verbose ($localizedData.teamExistsWithDifferentConfig -f $name)
                return $false
            }
        }
        else
        {
            Write-Verbose ($localizedData.teamDoesNotExistShouldCreate -f $name)
            return $false
        }
    }
    else
    {
        if ($networkTeam)
        {
            Write-Verbose ($localizedData.teamExistsShouldRemove -f $name)
            return $false
        }
        else
        {
            Write-Verbose ($localizedData.teamDoesNotExistNoAction -f $name)
            return $true
        }
    }
}
