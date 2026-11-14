[CmdletBinding()]
param([string]$SourceDirectory = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $SourceDirectory
if (-not (Test-Path -LiteralPath 'Cargo.toml')) {
    throw 'Extract the source ZIP and pass its directory with -SourceDirectory.'
}
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere)) { throw 'Install Visual Studio with C++ desktop tools and a Windows SDK first.' }
$visualStudio = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $visualStudio) { throw 'Visual Studio C++ desktop tools were not found.' }
$developerShell = Join-Path $visualStudio 'Common7\Tools\Launch-VsDevShell.ps1'
& $developerShell -Arch amd64 -HostArch amd64 -SkipAutomaticLocation
$env:ZED_RELEASE_CHANNEL = 'stable'
$env:CARGO_PROFILE_DEV_DEBUG = '0'
$env:CARGO_PROFILE_DEV_BUILD_OVERRIDE_DEBUG = '0'
$env:CARGO_BUILD_JOBS = '6'
$env:CARGO_NET_GIT_FETCH_WITH_CLI = 'true'
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'core.longpaths'
$env:GIT_CONFIG_VALUE_0 = 'true'
cargo +1.98.1 build --locked -p zed -p cli --features util/debug-embed
if ($LASTEXITCODE -ne 0) { throw 'Zed/CLI build failed.' }
Write-Host 'Binaries: target\debug\zed.exe and target\debug\cli.exe'
Write-Host 'Run the package builder with matching runtime DLLs and generated dependency licenses.'
