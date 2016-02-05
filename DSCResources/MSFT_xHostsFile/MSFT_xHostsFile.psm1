$Script:hostsFilePath = "${env:windir}\system32\drivers\etc\hosts"

Import-LocalizedData -BindingVariable LocalizedData -filename MSFT_xHostsFile.psd1 -BaseDirectory $PSScriptRoot -Verbose

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [string]
        $HostName,
        [parameter(Mandatory = $true)]
        [string]
        $IPAddress
    )

    $configuration = @{
        HostName = $HostName
        IPAddress = $IPAddress
    }

    Write-Verbose $localizedData.checkingHostsFileEntry
    try {
        if (Test-HostEntry -IPAddress $IPAddress -HostName $HostName) {
            Write-Verbose ($localizedData.hostsFileEntryFound -f $HostName, $IPAddress)
            $configuration.Add('Ensure','Present')
        } else {
            Write-Verbose ($localizedData.hostsFileEntryNotFound -f $HostName, $IPAddress)
            $configuration.Add('Ensure','Absent')
        }
        return $configuration
    } catch {
        $exception = $_
        Write-Verbose ($LocalizedData.anErrorOccurred -f $name, $exception.message)
        while ($null -ne $exception.InnerException)
        {
            $exception = $exception.innerException
            Write-Verbose ($LocalizedData.innerException -f $name, $exception.message)
        }
    }
}

function Set-TargetResource
{
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
            Write-Verbose ($localizedData.creatingHostsFileEntry -f $HostName, $IPAddress)
            Add-HostEntry -IPAddress $IPAddress -HostName $HostName
            Write-Verbose ($localizedData.hostsFileEntryAdded -f $HostName, $IPAddress)
        } else {
            Write-Verbose ($localizedData.removingHostsFileEntry -f $HostName, $IPAddress)
            Remove-HostEntry -IPAddress $IPAddress -HostName $HostName
            Write-Verbose ($localizedData.hostsFileEntryRemoved -f $HostName, $IPAddress)
        }
    } catch {
        $exception = $_
        Write-Verbose ($LocalizedData.anErrorOccurred -f $name, $exception.message)
        while ($null -ne $exception.innerException) {
            $exception = $exception.innerException
            Write-Verbose ($LocalizedData.innerException -f $name, $exception.message)
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
        Write-Verbose $localizedData.checkingHostsFileEntry
        $entryExist = Test-HostEntry -IPAddress $IPAddress -HostName $HostName

        if ($Ensure -eq "Present") {
            if ($entryExist) {
                Write-Verbose ($localizedData.hostsFileEntryFound -f $HostName, $IPAddress)
                return $true
            } else {
                Write-Verbose ($localizedData.hostsFileEntryShouldExist -f $HostName, $IPAddress)
                return $false
            }
        } else {
            if ($entryExist) {
                Write-Verbose $localizedData.hostsFileShouldNotExist
                return $false
            } else {
                Write-Verbose $localizedData.hostsFileEntryNotFound
                return $true
            }
        }
    } catch {
        $exception = $_
        Write-Verbose ($LocalizedData.anErrorOccurred -f $name, $exception.message)
        while ($null -ne $exception.innerException) {
            $exception = $exception.innerException
            Write-Verbose ($LocalizedData.innerException -f $name, $exception.message)
        }
    }
}

function Test-HostEntry
{
    param (
        [string] $IPAddress,
        [string] $HostName
    )

    foreach ($line in Get-Content $script:HostsFilePath) {
        $parsed = Parse-EntryLine -Line $line
        if ($parsed.IPAddress -eq $IPAddress) {
            return $parsed.HostNames -contains $HostName
        }
    }

    return $false
}

function Add-HostEntry
{
    param (
        [string] $IPAddress,
        [string] $HostName
    )

    $content = @(Get-Content $script:HostsFilePath)
    $length = $content.Length

    $foundMatch = $false
    $dirty = $false

    for ($i = 0; $i -lt $length; $i++) {
        $parsed = Parse-EntryLine -Line $content[$i]

        if ($parsed.IPAddress -ne $IPAddress) { continue }
        
        $foundMatch = $true

        if ($parsed.HostNames -notcontains $HostName) {
            $parsed.HostNames += $HostName
            $content[$i] = Reconstruct-Line -ParsedLine $parsed
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

function Remove-HostEntry
{
    param (
        [string] $IPAddress,
        [string] $HostName
    )

    $content = @(Get-Content $script:HostsFilePath)
    $length = $content.Length

    $placeholder = New-Object psobject
    $dirty = $false

    for ($i = 0; $i -lt $length; $i++) {
        $parsed = Parse-EntryLine -Line $content[$i]

        if ($parsed.IPAddress -ne $IPAddress) { continue }
        
        if ($parsed.HostNames -contains $HostName) {
            $dirty = $true

            if ($parsed.HostNames.Count -eq 1) {
                # We're removing the only HostName from this line; just remove the whole line
                $content[$i] = $placeholder
            } else {
                $parsed.HostNames = $parsed.HostNames -ne $HostName
                $content[$i] = Reconstruct-Line -ParsedLine $parsed
            }
        }
    }

    if ($dirty) {
        $content = $content -ne $placeholder
        Set-Content $script:HostsFilePath -Value $content
    }
}

function Parse-EntryLine
{
    param ([string] $Line)

    $indent    = ''
    $ipAddress = ''
    $hostNames = @()
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
        $ipAddress = $matches['ipAddress']
        $hostNames = $matches['hostNames'] -split '\s+' -match '\S'
        $comment   = $matches['comment']
    }

    return [pscustomobject] @{
        Indent    = $indent
        IPAddress = $IPAddress
        HostNames = $HostNames
        Comment   = $comment
    }
}

function Reconstruct-Line
{
    param ([object] $ParsedLine)

    if ($ParsedLine.Comment) {
        $comment = " # $($ParsedLine.Comment)"
    } else {
        $comment = ''
    }

    return '{0}{1} {2}{3}' -f $ParsedLine.Indent, $ParsedLine.IPAddress, ($ParsedLine.HostNames -join ' '), $comment
}

Export-ModuleMember -Function Test-TargetResource,Set-TargetResource,Get-TargetResource
