Import-Module (Join-Path $PSScriptRoot "..\Tests\xNetworking.TestHarness.psm1" -Resolve)
$dscTestsPath = Join-Path -Path $PSScriptRoot `
                    -ChildPath "..\Modules\xNetworking\DscResource.Tests\Meta.Tests.ps1"
Invoke-xNetworkingTest -DscTestsPath $dscTestsPath
