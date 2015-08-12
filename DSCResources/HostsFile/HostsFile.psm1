#Includes changes from Steven Murawski and Dave Wyatt
#https://github.com/PowerShellOrg/rchaganti/tree/master/DSCResources/HostsFile

#Japanese language translation as ja-JP by @guitarrapc

$script:HostsFilePath = "${env:windir}\system32\drivers\etc\hosts"

# Fallback message strings in en-US
DATA localizedData {
    # same as culture = "en-US"
ConvertFrom-StringData @'
    CheckingHostsFileEntry=Checking if the hosts file entry exists.
    HostsFileEntryFound=Found a hosts file entry for {0} and {1}.
    HostsFileEntryNotFound=Did not find a hosts file entry for {0} and {1}.
    HostsFileShouldNotExist=Hosts file entry exists while it should not.
    HostsFileEntryShouldExist=Hosts file entry does not exist while it should.
    CreatingHostsFileEntry=Creating a hosts file entry with {0} and {1}.
    RemovingHostsFileEntry=Removing a hosts file entry with {0} and {1}.
    HostsFileEntryAdded=Created the hosts file entry for {0} and {1}.
    HostsFileEntryRemoved=Removed the hosts file entry for {0} and {1}.
    AnErrorOccurred=An error occurred while creating hosts file entry: {1}.
    InnerException=Nested error trying to create hosts file entry: {1}.
'@
}

if (Test-Path "${PSScriptRoot}\${PSCulture}") {
    Import-LocalizedData LocalizedData -filename "${PSScriptRoot}\${PSCulture}\HostsFileMessages.psd1"
}

function Get-TargetResource {
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [string]
        $HostName,
        [parameter(Mandatory = $true)]
        [string]
        $IPAddress
    )

    $Configuration = @{
        HostName = $HostName
        IPAddress = $IPAddress
    }

    Write-Verbose $localizedData.CheckingHostsFileEntry
    try {
        if (HostsEntryExists -IPAddress $IPAddress -HostName $HostName) {
            Write-Verbose ($localizedData.HostsFileEntryFound -f $HostName, $IPAddress)
            $Configuration.Add('Ensure','Present')
        } else {
            Write-Verbose ($localizedData.HostsFileEntryNotFound -f $HostName, $IPAddress)
            $Configuration.Add('Ensure','Absent')
        }
        return $Configuration
    } catch {
        $exception = $_
        Write-Verbose ($LocalizedData.AnErrorOccurred -f $name, $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($LocalizedData.InnerException -f $name, $exception.message)
        }
    }
}

function Set-TargetResource {
    param (
        [parameter(Mandatory = $true)]
        [string]
        $HostName,
        [parameter(Mandatory = $true)]
        [string]
        $IPAddress,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    try {
        if ($Ensure -eq 'Present') {
            Write-Verbose ($localizedData.CreatingHostsFileEntry -f $HostName, $IPAddress)
            AddHostsEntry -IPAddress $IPAddress -HostName $HostName
            Write-Verbose ($localizedData.HostsFileEntryAdded -f $HostName, $IPAddress)
        } else {
            Write-Verbose ($localizedData.RemovingHostsFileEntry -f $HostName, $IPAddress)
            RemoveHostsEntry -IPAddress $IPAddress -HostName $HostName
            Write-Verbose ($localizedData.HostsFileEntryRemoved -f $HostName, $IPAddress)
        }
    } catch {
        $exception = $_
        Write-Verbose ($LocalizedData.AnErrorOccurred -f $name, $exception.message)
        while ($exception.InnerException -ne $null) {
            $exception = $exception.InnerException
            Write-Verbose ($LocalizedData.InnerException -f $name, $exception.message)
        }
    }
}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [parameter(Mandatory = $true)]
        [string]
        $HostName,
        [parameter(Mandatory = $true)]
        [string]
        $IPAddress,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    try {
        Write-Verbose $localizedData.CheckingHostsFileEntry
        $entryExist = HostsEntryExists -IPAddress $IPAddress -HostName $HostName

        if ($Ensure -eq "Present") {
            if ($entryExist) {
                Write-Verbose ($localizedData.HostsFileEntryFound -f $HostName, $IPAddress)
                return $true
            } else {
                Write-Verbose ($localizedData.HostsFileEntryShouldExist -f $HostName, $IPAddress)
                return $false
            }
        } else {
            if ($entryExist) {
                Write-Verbose $localizedData.HostsFileShouldNotExist
                return $false
            } else {
                Write-Verbose $localizedData.HostsFileEntryNotFound
                return $true
            }
        }
    } catch {
        $exception = $_
        Write-Verbose ($LocalizedData.AnErrorOccurred -f $name, $exception.message)
        while ($exception.InnerException -ne $null) {
            $exception = $exception.InnerException
            Write-Verbose ($LocalizedData.InnerException -f $name, $exception.message)
        }
    }
}

function HostsEntryExists {
    param (
        [string] $IPAddress,
        [string] $HostName
    )

    foreach ($line in Get-Content $script:HostsFilePath) {
        $parsed = ParseEntryLine -Line $line
        if ($parsed.IPAddress -eq $IPAddress) {
            return $parsed.HostNames -contains $HostName
        }
    }

    return $false
}

function AddHostsEntry {
    param (
        [string] $IPAddress,
        [string] $HostName
    )

    $content = @(Get-Content $script:HostsFilePath)
    $length = $content.Length

    $foundMatch = $false
    $dirty = $false

    for ($i = 0; $i -lt $length; $i++) {
        $parsed = ParseEntryLine -Line $content[$i]

        if ($parsed.IPAddress -ne $IPAddress) { continue }
        
        $foundMatch = $true

        if ($parsed.HostNames -notcontains $HostName) {
            $parsed.HostNames += $HostName
            $content[$i] = ReconstructLine -ParsedLine $parsed
            $dirty = $true
            # Hosts files shouldn't strictly have the same IP address on multiple lines; should we just break here?
            # Or is it better to search for all matching lines in a malformed file, and modify all of them?
        }
    }

    if (-not $foundMatch) {
        $content += "$IPAddress $HostName"
        $dirty = $true
    }

    if ($dirty) {
        Set-Content $script:HostsFilePath -Value $content
    }
}

function RemoveHostsEntry {
    param (
        [string] $IPAddress,
        [string] $HostName
    )

    $content = @(Get-Content $script:HostsFilePath)
    $length = $content.Length

    $placeholder = New-Object psobject
    $dirty = $false

    for ($i = 0; $i -lt $length; $i++) {
        $parsed = ParseEntryLine -Line $content[$i]

        if ($parsed.IPAddress -ne $IPAddress) { continue }
        
        if ($parsed.HostNames -contains $HostName) {
            $dirty = $true

            if ($parsed.HostNames.Count -eq 1) {
                # We're removing the only HostName from this line; just remove the whole line
                $content[$i] = $placeholder
            } else {
                $parsed.HostNames = $parsed.HostNames -ne $HostName
                $content[$i] = ReconstructLine -ParsedLine $parsed
            }
        }
    }

    if ($dirty) {
        $content = $content -ne $placeholder
        Set-Content $script:HostsFilePath -Value $content
    }
}

function ParseEntryLine {
    param ([string] $Line)

    $indent    = ''
    $IPAddress = ''
    $HostNames = @()
    $comment   = ''

    $regex = '^' +
             '(?<indent>\s*)' +
             '(?<IPAddress>\S+)' +
             '(?:' +
                 '\s+' +
                 '(?<HostNames>[^#]*)' +
                 '(?:#\s*(?<comment>.*))?' +
             ')?' +
             '\s*' +
             '$'

    if ($line -match $regex)
    {
        $indent    = $matches['indent']
        $IPAddress = $matches['IPAddress']
        $HostNames = $matches['HostNames'] -split '\s+' -match '\S'
        $comment   = $matches['comment']
    }

    return [pscustomobject] @{
        Indent    = $indent
        IPAddress = $IPAddress
        HostNames = $HostNames
        Comment   = $comment
    }
}

function ReconstructLine {
    param ([object] $ParsedLine)

    if ($ParsedLine.Comment) {
        $comment = " # $($ParsedLine.Comment)"
    } else {
        $comment = ''
    }

    return '{0}{1} {2}{3}' -f $ParsedLine.Indent, $ParsedLine.IPAddress, ($ParsedLine.HostNames -join ' '), $comment
}

Export-ModuleMember -Function Test-TargetResource,Set-TargetResource,Get-TargetResource