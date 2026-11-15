[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$BinaryPaths,
    [string]$SourceDirectory,
    [string]$ScanRoot,
    [string[]]$AdditionalForbiddenPrefixes = @(),
    [Parameter(Mandatory = $true)][string]$ReportPath
)
$ErrorActionPreference = 'Stop'
$prefixes = @(
    @{ Category = 'WindowsUserDirectory'; Value = $env:USERPROFILE },
    @{ Category = 'CargoHome'; Value = $env:CARGO_HOME },
    @{ Category = 'RustupHome'; Value = $env:RUSTUP_HOME },
    @{ Category = 'SourceCheckout'; Value = $SourceDirectory }
)
$accountName = [IO.Path]::GetFileName($env:USERPROFILE.TrimEnd('\'))
if ($accountName.Length -ge 6 -and $accountName -notin @('Administrator', 'Default', 'Public', 'RunnerAdmin', 'Runner')) {
    $prefixes += @{ Category = 'WindowsAccountName'; Value = $accountName }
}
foreach ($prefix in $AdditionalForbiddenPrefixes) {
    $prefixes += @{ Category = 'AdditionalBuildDirectory'; Value = $prefix }
}
$latin1 = [Text.Encoding]::GetEncoding(28591)
$needles = @()
foreach ($prefix in $prefixes) {
    if ([string]::IsNullOrWhiteSpace($prefix.Value)) { continue }
    foreach ($variant in @($prefix.Value, $prefix.Value.Replace('\', '/'))) {
        foreach ($encoding in @([Text.Encoding]::UTF8, [Text.Encoding]::Unicode)) {
            $needles += @{ Category = $prefix.Category; Text = $latin1.GetString($encoding.GetBytes($variant)) }
        }
    }
}
$overlap = [int](($needles | ForEach-Object { $_.Text.Length } | Measure-Object -Maximum).Maximum) - 1
$buffer = New-Object byte[] (4MB)
$results = @()
foreach ($binaryPath in $BinaryPaths) {
    $resolved = (Resolve-Path -LiteralPath $binaryPath).Path
    $found = @{}
    $stream = [IO.File]::OpenRead($resolved)
    try {
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $text = $latin1.GetString($buffer, 0, $read)
            foreach ($needle in $needles) {
                if (-not $found.ContainsKey($needle.Category) -and
                    $text.IndexOf($needle.Text, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $found[$needle.Category] = $true
                }
            }
            if ($stream.Position -ge $stream.Length) { break }
            $stream.Position -= [math]::Min($overlap, $read - 1)
        }
    } finally {
        $stream.Dispose()
    }
    $label = [IO.Path]::GetFileName($resolved)
    if ($ScanRoot) {
        $root = [IO.Path]::GetFullPath($ScanRoot).TrimEnd('\')
        if ($resolved.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
            $label = $resolved.Substring($root.Length + 1).Replace('\', '/')
        }
    }
    $results += [ordered]@{ File = $label; LocalBuildPathCategories = @($found.Keys | Sort-Object) }
}
$failed = @($results | Where-Object { $_.LocalBuildPathCategories.Count -gt 0 }).Count -gt 0
$report = [ordered]@{
    Check = 'Local account and build path scan (UTF-8 and UTF-16LE, case-insensitive)'
    Passed = (-not $failed)
    CheckedAtUtc = [DateTime]::UtcNow.ToString('o')
    Files = $results
    Note = 'No raw usernames or private directory values are included. This check is not a complete secret scan.'
}
[IO.File]::WriteAllText($ReportPath, ($report | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
if ($failed) { throw 'Local build paths remain in the artifact(s). See the redacted privacy report.' }
Write-Host 'Local build path scan passed.'
