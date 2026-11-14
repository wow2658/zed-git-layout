[CmdletBinding()]
param(
    [string]$Version = '1.28.1-custom.1',
    [string]$OutputDirectory = 'C:\dev\zed-private-releases',
    [string]$ExecutablePath,
    [string]$RuntimeDirectory = (Join-Path $env:LOCALAPPDATA 'Programs\Zed'),
    [Parameter(Mandatory = $true)][string]$DependencyLicenses,
    [string]$ExpectedExecutableSha256 = 'DEC3EF302CCB700833553D8D1D2D11107B31C5E5CB3577E9DBA85CC40FFC1C8E'
)
. (Join-Path $PSScriptRoot 'Common.ps1')
$repository = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
if (-not $ExecutablePath) { $ExecutablePath = Join-Path $repository 'target\debug\zed.exe' }
if ($Version -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,80}$') { throw 'Invalid release version.' }
if ((Get-FileHash -LiteralPath $ExecutablePath -Algorithm SHA256).Hash -ne $ExpectedExecutableSha256) {
    throw 'The executable differs from the expected private build. Verify it and supply the correct hash.'
}
if (-not (Test-Path -LiteralPath $DependencyLicenses -PathType Leaf)) { throw 'Generate dependency license notices first.' }
Push-Location -LiteralPath $repository
try {
    $sourceCommit = (& git rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Cannot identify the source checkpoint.' }
    $changes = @(& git status --porcelain --untracked-files=all -- script/private-distribution crates/git_ui/src/git_panel.rs crates/git_ui/src/git_graph.rs crates/zed/src/main.rs)
    if ($changes.Count -gt 0) { throw 'Commit the private build and packaging sources before bundling.' }
    $outputRoot = Get-ZedPrivateFullPath $OutputDirectory
    $name = "Zed-Git-Layout-$Version-win-x64"
    $packageRoot = Join-Path $outputRoot $name
    if (Test-Path -LiteralPath $packageRoot) { throw 'This release directory already exists. Use a new version or a different output directory.' }
    New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null
    foreach ($directory in @('app\bin', 'app\x64', 'app\arm64', 'defaults', 'licenses', 'source')) {
        New-Item -ItemType Directory -Path (Join-Path $packageRoot $directory) -Force | Out-Null
    }
    Copy-Item -LiteralPath $ExecutablePath -Destination (Join-Path $packageRoot 'app\Zed.exe')
    foreach ($file in @('bin\Zed.exe', 'conpty.dll', 'OpenConsole.exe', 'x64\OpenConsole.exe', 'arm64\OpenConsole.exe', 'amd_ags_x64.dll')) {
        Copy-Item -LiteralPath (Join-Path $RuntimeDirectory $file) -Destination (Join-Path $packageRoot ('app\' + $file))
    }
    foreach ($file in @('Install.ps1', 'Uninstall.ps1', 'Common.ps1', 'Install.cmd', 'Uninstall.cmd', 'README.ko.txt')) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination $packageRoot
    }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Build.ps1') -Destination (Join-Path $packageRoot 'source\Build.ps1')
    foreach ($file in @('LICENSE-GPL', 'LICENSE-APACHE')) {
        Copy-Item -LiteralPath (Join-Path $repository $file) -Destination (Join-Path $packageRoot ('licenses\' + $file))
    }
    Copy-Item -LiteralPath $DependencyLicenses -Destination (Join-Path $packageRoot 'licenses\RUST-DEPENDENCIES.md')
    Copy-Item -LiteralPath (Join-Path $repository 'assets\icons\LICENSES') -Destination (Join-Path $packageRoot 'licenses\ICONS.txt')
    Copy-Item -LiteralPath (Join-Path $repository 'assets\themes\LICENSES') -Destination (Join-Path $packageRoot 'licenses\THEMES.txt')
    $runtimeLicenses = @{
        'AMD-AGS.txt' = 'https://raw.githubusercontent.com/GPUOpen-LibrariesAndSDKs/AGS_SDK/v6.3.0/LICENSE.txt'
        'CONPTY-TERMINAL.txt' = 'https://raw.githubusercontent.com/microsoft/terminal/main/LICENSE'
    }
    foreach ($license in $runtimeLicenses.GetEnumerator()) {
        Invoke-WebRequest -UseBasicParsing -Uri $license.Value -OutFile (Join-Path $packageRoot ('licenses\' + $license.Key))
    }
    $sourceArchive = Join-Path $packageRoot 'source\zed-source.zip'
    & git archive --format=zip --prefix=zed-source/ "--output=$sourceArchive" $sourceCommit
    if ($LASTEXITCODE -ne 0) { throw 'Source archive creation failed.' }
    $customPatch = Join-Path $packageRoot 'source\custom-changes.patch'
    & git diff --binary "--output=$customPatch" e8bc16a $sourceCommit -- crates/git_ui/src/git_panel.rs crates/git_ui/src/git_graph.rs crates/zed/src/main.rs
    if ($LASTEXITCODE -ne 0) { throw 'Custom patch creation failed.' }
    $defaults = [ordered]@{
        auto_update = $false
        git_panel = [ordered]@{ dock = 'right'; starts_open = $true; tree_view = $true; commit_editor = 'collapsed' }
    }
    Write-ZedPrivateUtf8 (Join-Path $packageRoot 'defaults\settings.json') ($defaults | ConvertTo-Json -Depth 5)
    $buildInfo = @"
Product: Zed Git Layout (unofficial private build)
Package version: $Version
Upstream version: 1.28.1
Upstream source: https://github.com/zed-industries/zed/tree/e8bc16acee5ae1937600d571d441c4b5d7b0d288
Private source checkpoint: $sourceCommit
Modification date: 2026-11-15
Target: x86_64-pc-windows-msvc
Rust: 1.98.1
Build: ZED_RELEASE_CHANNEL=stable cargo +1.98.1 build -p zed --locked --features util/debug-embed
Profile: dev; debug=0; build-override.debug=0; embedded assets; static MSVC CRT
Executable SHA256: $ExpectedExecutableSha256
Signing: unsigned
CLI: unmodified official Zed 1.28.1 CLI; its --version reports the upstream base commit
ConPTY/OpenConsole: Microsoft.Windows.Console.ConPTY 1.25.260710002-preview
AMD AGS: 6.3.0
Dependency notices: cargo-about 0.8.2; Windows x64; zed package with util/debug-embed
Source ZIP includes the complete tracked modified Zed checkout and packaging scripts.
Runtime dependency source references and copyright notices are in licenses/ and Cargo.lock.
No personal settings, login databases, projects, extension caches or credentials are included.
This is a development build; it is not bit-for-bit reproducible or a signed official release.
"@
    Write-ZedPrivateUtf8 (Join-Path $packageRoot 'BUILD-INFO.txt') $buildInfo
    $files = @(Get-ChildItem -LiteralPath $packageRoot -File -Recurse | Sort-Object FullName | ForEach-Object {
        [ordered]@{
            Path = $_.FullName.Substring($packageRoot.Length + 1).Replace('\', '/')
            Size = $_.Length
            Sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        }
    })
    $manifest = [ordered]@{
        Product = $script:ZedPrivateProduct
        Version = $Version
        SourceCommit = $sourceCommit
        CreatedAtUtc = [DateTime]::UtcNow.ToString('o')
        Files = $files
    }
    Write-ZedPrivateUtf8 (Join-Path $packageRoot 'manifest.json') ($manifest | ConvertTo-Json -Depth 6)
    $verified = Test-ZedPrivatePayload $packageRoot
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zipPath = Join-Path $outputRoot ($name + '.zip')
    [IO.Compression.ZipFile]::CreateFromDirectory($packageRoot, $zipPath, [IO.Compression.CompressionLevel]::Optimal, $false)
    $checksum = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + [IO.Path]::GetFileName($zipPath)
    [IO.File]::WriteAllText(($zipPath + '.sha256'), $checksum + "`r`n", [Text.Encoding]::ASCII)
    Write-Host "Created: $zipPath"
    Write-Host "SHA256: $checksum"
} finally {
    Pop-Location
}
