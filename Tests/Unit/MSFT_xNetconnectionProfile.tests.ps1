$DSCResourceName = 'MSFT_xNetConnectionProfile'
$DSCModuleName   = 'xNetworking'

$Splat = @{
    Path = $PSScriptRoot
    ChildPath = "..\..\DSCResources\$DSCResourceName\$DSCResourceName.psm1"
    Resolve = $true
    ErrorAction = 'Stop'
}

$DSCResourceModuleFile = Get-Item -Path (Join-Path @Splat)

$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

if(-not (Test-Path -Path $moduleRoot))
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
}
else
{
    # Copy the existing folder out to the temp directory to hold until the end of the run
    # Delete the folder to remove the old files.
    $tempLocation = Join-Path -Path $env:Temp -ChildPath $DSCModuleName
    Copy-Item -Path $moduleRoot -Destination $tempLocation -Recurse -Force
    Remove-Item -Path $moduleRoot -Recurse -Force
    $null = New-Item -Path $moduleRoot -ItemType Directory
}

Copy-Item -Path $PSScriptRoot\..\..\* -Destination $moduleRoot -Recurse -Force -Exclude '.git'

if (Get-Module -Name $DSCResourceName)
{
    Remove-Module -Name $DSCResourceName
}

Import-Module -Name $DSCResourceModuleFile.FullName -Force

InModuleScope $DSCResourceName {
    Describe 'Get-TargetResource - MSFT_xNetConnectionProfile' {
        Mock Get-NetConnectionProfile {
            return @{
                InterfaceAlias   = 'InterfaceAlias'
                NetworkCategory  = 'Wired'
                IPv4Connectivity = 'IPv4'
                IPv6Connectivity = 'IPv6'
            }
        }
        $expected = Get-NetConnectionProfile | select -first 1
        $result = Get-TargetResource -InterfaceAlias $expected.InterfaceAlias

        It 'Should return the correct values' {
            $expected.InterfaceAlias   | Should Be $result.InterfaceAlias
            $expected.NetworkCategory  | Should Be $result.NetworkCategory
            $expected.IPv4Connectivity | Should Be $result.IPv4Connectivity
            $expected.IPv6Connectivity | Should Be $result.IPv6Connectivity
        }
    }

    Describe 'Test-TargetResource - MSFT_xNetConnectionProfile' {
        $Splat = @{
            InterfaceAlias   = 'Test'
            NetworkCategory  = 'Private'
            IPv4Connectivity = 'Internet'
            IPv6Connectivity = 'Disconnected'
        }

        Context 'IPv4Connectivity is incorrect' {
            $incorrect = $Splat.Clone()
            $incorrect.IPv4Connectivity = 'Disconnected'
            Mock Get-TargetResource {
                return $incorrect
            }

            It 'should return false' {
                Test-TargetResource @Splat | should be $false
            }
        }

        Context 'IPv6Connectivity is incorrect' {
            $incorrect = $Splat.Clone()
            $incorrect.IPv6Connectivity = 'Internet'
            Mock Get-TargetResource {
                return $incorrect
            }

            It 'should return false' {
                Test-TargetResource @Splat | should be $false
            }
        }

        Context 'NetworkCategory is incorrect' {
            $incorrect = $Splat.Clone()
            $incorrect.NetworkCategory = 'Public'
            Mock Get-TargetResource {
                return $incorrect
            }

            It 'should return false' {
                Test-TargetResource @Splat | should be $false
            }
        }
    }

    Describe 'Set-TargetResource - MSFT_xNetConnectionProfile' {
        It 'Should do call all the mocks' {
            $Splat = @{
                InterfaceAlias   = 'Test'
                NetworkCategory  = 'Private'
                IPv4Connectivity = 'Internet'
                IPv6Connectivity = 'Disconnected'
            }

            Mock Set-NetConnectionProfile {}

            Set-TargetResource @Splat

            Assert-MockCalled Set-NetConnectionProfile
        }
    }
}

# Clean up after the test completes.
Remove-Item -Path $moduleRoot -Recurse -Force

# Restore previous versions, if it exists.
if ($tempLocation)
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
    $script:Destination = "${env:ProgramFiles}\WindowsPowerShell\Modules"
    Copy-Item -Path $tempLocation -Destination $script:Destination -Recurse -Force
    Remove-Item -Path $tempLocation -Recurse -Force
}
