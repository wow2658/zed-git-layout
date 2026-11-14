[CmdletBinding()]
param([string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA 'Programs\ZedGitLayout'))
. (Join-Path $PSScriptRoot 'Common.ps1')
$installRoot = Assert-ZedPrivateRoot $InstallDirectory
$receipt = Get-ZedPrivateReceipt $installRoot
Assert-ZedPrivateStopped $installRoot
$links = @(Get-ChildItem -LiteralPath $installRoot -Force -Recurse | Where-Object {
    ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
})
if ($links.Count -gt 0) { throw 'Remove links/junctions from the installation before uninstalling it.' }
if ($receipt.Integrated) {
    $shell = New-Object -ComObject WScript.Shell
    foreach ($directory in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
        $shortcutPath = Join-Path $directory 'Zed Git Layout.lnk'
        if (Test-Path -LiteralPath $shortcutPath) {
            $shortcut = $shell.CreateShortcut($shortcutPath)
            if ($shortcut.TargetPath.StartsWith($installRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
                Remove-Item -LiteralPath $shortcutPath -Force
            }
        }
    }
    $registryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ZedGitLayoutPrivate'
    if (Test-Path -LiteralPath $registryPath) {
        $entry = Get-ItemProperty -LiteralPath $registryPath
        if ($entry.InstallLocation -eq $installRoot) { Remove-Item -LiteralPath $registryPath -Force }
    }
}
# The resolved root and ownership receipt are checked above; user data is outside this root.
Remove-Item -LiteralPath $installRoot -Recurse -Force
Write-Host 'Zed Git Layout was uninstalled.'
Write-Host "Settings, extensions and user data were preserved at: $($receipt.DataDirectory)"
