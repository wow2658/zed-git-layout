$ErrorActionPreference = 'Stop'
$script:ZedPrivateProduct = 'zed-git-layout-private'

function Get-ZedPrivateFullPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'An absolute directory path is required.' }
    if (-not [IO.Path]::IsPathRooted($Path)) { throw 'Relative installation paths are not supported.' }
    return [IO.Path]::GetFullPath($Path).TrimEnd('\')
}

function Assert-ZedPrivateRoot([string]$Path) {
    $resolved = Get-ZedPrivateFullPath $Path
    $forbidden = @([IO.Path]::GetPathRoot($resolved).TrimEnd('\'), $env:USERPROFILE,
        $env:LOCALAPPDATA, (Join-Path $env:LOCALAPPDATA 'Programs'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Zed'), $env:WINDIR, $env:ProgramFiles)
    foreach ($directory in $forbidden) {
        if ($directory -and $resolved.Equals($directory.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) {
            throw "This is not a safe private installation directory: $resolved"
        }
    }
    $ancestor = $resolved
    while ($ancestor) {
        if (Test-Path -LiteralPath $ancestor) {
            $item = Get-Item -LiteralPath $ancestor -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Installation through a junction or symbolic link is not supported: $ancestor"
            }
        }
        $parent = [IO.Directory]::GetParent($ancestor)
        if ($null -eq $parent) { break }
        $ancestor = $parent.FullName
    }
    return $resolved
}

function Get-ZedPrivateReceipt([string]$Root) {
    $marker = Join-Path $Root '.zed-git-layout-install.json'
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { throw "No private installation receipt: $Root" }
    $receipt = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
    if ($receipt.Product -ne $script:ZedPrivateProduct -or
        -not $Root.Equals([string]$receipt.InstallDirectory, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The installation receipt does not match this directory.'
    }
    return $receipt
}

function Assert-ZedPrivateStopped([string]$Root) {
    $prefix = $Root + '\'
    $running = @(Get-Process -Name Zed -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -and $_.Path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
    })
    if ($running.Count -gt 0) { throw 'Close Zed Git Layout before installing or uninstalling it.' }
}

function Test-ZedPrivatePayload([string]$Root) {
    $manifest = Get-Content -LiteralPath (Join-Path $Root 'manifest.json') -Raw | ConvertFrom-Json
    if ($manifest.Product -ne $script:ZedPrivateProduct) { throw 'This is not a Zed Git Layout package.' }
    foreach ($entry in $manifest.Files) {
        $file = [IO.Path]::GetFullPath((Join-Path $Root $entry.Path))
        if (-not $file.StartsWith($Root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw 'The package manifest contains an invalid file path.'
        }
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Package file missing: $($entry.Path)" }
        if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $entry.Sha256) {
            throw "Package file checksum mismatch: $($entry.Path)"
        }
    }
    return $manifest
}

function Write-ZedPrivateUtf8([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($true))
}
