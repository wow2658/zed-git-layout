[CmdletBinding()]
param(
    [string]$SourceDirectory = $PSScriptRoot,
    [string]$TargetDirectory,
    [switch]$UseExistingToolchain
)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $SourceDirectory
if (-not (Test-Path -LiteralPath 'Cargo.toml')) {
    throw 'Extract the source ZIP and pass its directory with -SourceDirectory.'
}
$SourceDirectory = (Resolve-Path -LiteralPath $SourceDirectory).Path
if (-not $TargetDirectory) { $TargetDirectory = Join-Path $SourceDirectory 'target\private' }
$TargetDirectory = [IO.Path]::GetFullPath($TargetDirectory)
if (-not $UseExistingToolchain) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) { throw 'Install Visual Studio with C++ desktop tools and a Windows SDK first.' }
    $visualStudio = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $visualStudio) { throw 'Visual Studio C++ desktop tools were not found.' }
    $developerShell = Join-Path $visualStudio 'Common7\Tools\Launch-VsDevShell.ps1'
    & $developerShell -Arch amd64 -HostArch amd64 -SkipAutomaticLocation
}
if ($env:RUSTFLAGS -or $env:CARGO_ENCODED_RUSTFLAGS) {
    throw 'Unset RUSTFLAGS and CARGO_ENCODED_RUSTFLAGS so Cargo can apply the checked-in flags and path remapping together.'
}
$env:ZED_RELEASE_CHANNEL = 'stable'
$packageManifest = Get-Content -LiteralPath (Join-Path $SourceDirectory 'crates\zed\Cargo.toml') -Raw
$versionMatch = [regex]::Match($packageManifest, '(?m)^version\s*=\s*"([^"]+)"')
if (-not $versionMatch.Success) { throw 'Cannot determine the upstream Zed version.' }
$env:RELEASE_VERSION = $versionMatch.Groups[1].Value
$env:CARGO_PROFILE_DEV_DEBUG = '0'
$env:CARGO_PROFILE_DEV_BUILD_OVERRIDE_DEBUG = '0'
$env:CARGO_BUILD_JOBS = '6'
$env:CARGO_NET_GIT_FETCH_WITH_CLI = 'true'
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'core.longpaths'
$env:GIT_CONFIG_VALUE_0 = 'true'
$cargoDirectory = if ($env:CARGO_HOME) { $env:CARGO_HOME } else { Join-Path $env:USERPROFILE '.cargo' }
$rustupDirectory = if ($env:RUSTUP_HOME) { $env:RUSTUP_HOME } else { Join-Path $env:USERPROFILE '.rustup' }
$mappings = @(
    @{ From = $env:USERPROFILE; To = '/build/user' },
    @{ From = $cargoDirectory; To = '/cargo' },
    @{ From = $rustupDirectory; To = '/rustup' },
    @{ From = $env:TEMP; To = '/build/temp' },
    @{ From = $env:VCToolsInstallDir; To = '/toolchain/msvc' },
    @{ From = $env:WindowsSdkDir; To = '/toolchain/windows-sdk' },
    @{ From = $SourceDirectory; To = '/zed/source' },
    @{ From = $TargetDirectory; To = '/zed/target' }
)
$remappingFlags = @()
$nativeMappings = @()
foreach ($mapping in $mappings) {
    if (-not $mapping.From) { continue }
    $prefix = [IO.Path]::GetFullPath($mapping.From).TrimEnd('\')
    foreach ($variant in @($prefix, $prefix.Replace('\', '/'), ('\\?\' + $prefix))) {
        $flag = '--remap-path-prefix=' + $variant + '=' + $mapping.To
        $remappingFlags += ConvertTo-Json -InputObject $flag -Compress
    }
    $nativeMappings += '/pathmap:"' + $prefix + '=' + $mapping.To + '"'
}
# MSVC uses the first matching mapping; rustc uses the last matching mapping.
[array]::Reverse($nativeMappings)
$nativeFlags = @('/experimental:deterministic') + $nativeMappings
$configuration = @"
[target.'cfg(all())']
rustflags = [ $($remappingFlags -join ', ') ]
[profile.release-fast]
debug = 0
[profile.release-fast.build-override]
debug = 0
"@
$configurationPath = [IO.Path]::GetTempFileName()
$previousCFlags = $env:CFLAGS
$previousCxxFlags = $env:CXXFLAGS
try {
    [IO.File]::WriteAllText($configurationPath, $configuration, [Text.UTF8Encoding]::new($false))
    $env:CFLAGS = ($previousCFlags + ' ' + ($nativeFlags -join ' ')).Trim()
    $env:CXXFLAGS = ($previousCxxFlags + ' ' + ($nativeFlags -join ' ')).Trim()
    cargo +1.98.1 --config $configurationPath build --profile release-fast --target-dir $TargetDirectory --locked -p zed -p cli --features util/debug-embed
    if ($LASTEXITCODE -ne 0) { throw 'Zed/CLI build failed.' }
} finally {
    $env:CFLAGS = $previousCFlags
    $env:CXXFLAGS = $previousCxxFlags
    Remove-Item -LiteralPath $configurationPath -Force
}
Write-Host "Binaries: $TargetDirectory\release-fast\zed.exe and cli.exe"
Write-Host 'Run the package builder with matching runtime DLLs and generated dependency licenses.'
