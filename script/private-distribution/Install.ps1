[CmdletBinding()]
param(
    [string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA 'Programs\ZedGitLayout'),
    [string]$DataDirectory = (Join-Path $env:LOCALAPPDATA 'ZedGitLayout\UserData'),
    [switch]$NoIntegration
)
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not [Environment]::Is64BitOperatingSystem) { throw 'This package requires 64-bit Windows.' }
$installRoot = Assert-ZedPrivateRoot $InstallDirectory
$dataRoot = Assert-ZedPrivateRoot $DataDirectory
if ($dataRoot.StartsWith($installRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or $dataRoot -eq $installRoot) {
    throw 'Keep the user-data directory outside the installation directory so uninstall preserves it.'
}
$manifest = Test-ZedPrivatePayload $PSScriptRoot
if ($manifest.Version -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,80}$') { throw 'Invalid package version.' }
if (Test-Path -LiteralPath $installRoot) {
    $oldReceipt = Get-ZedPrivateReceipt $installRoot
    if (-not $dataRoot.Equals([string]$oldReceipt.DataDirectory, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'An existing installation must keep its original user-data directory.'
    }
}
Assert-ZedPrivateStopped $installRoot
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
$versionsRoot = Join-Path $installRoot 'versions'
Assert-ZedPrivateRoot $versionsRoot | Out-Null
New-Item -ItemType Directory -Path $versionsRoot -Force | Out-Null
$versionRoot = Join-Path $versionsRoot $manifest.Version
$stagingRoot = Join-Path $versionsRoot ($manifest.Version + '-staging-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stagingRoot | Out-Null
Get-ChildItem -LiteralPath $PSScriptRoot -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $stagingRoot -Recurse -Force
}
$verified = Test-ZedPrivatePayload $stagingRoot
if (Test-Path -LiteralPath $versionRoot) {
    $backupRoot = Join-Path $versionsRoot ($manifest.Version + '-previous-' + [Guid]::NewGuid().ToString('N'))
    Move-Item -LiteralPath $versionRoot -Destination $backupRoot
}
Move-Item -LiteralPath $stagingRoot -Destination $versionRoot

$configRoot = Join-Path $dataRoot 'config'
Assert-ZedPrivateRoot $configRoot | Out-Null
New-Item -ItemType Directory -Path $configRoot -Force | Out-Null
$settingsPath = Join-Path $configRoot 'settings.json'
if (-not (Test-Path -LiteralPath $settingsPath)) {
    Copy-Item -LiteralPath (Join-Path $versionRoot 'defaults\settings.json') -Destination $settingsPath
}
$receipt = [ordered]@{
    Product = $script:ZedPrivateProduct
    Version = $manifest.Version
    InstallDirectory = $installRoot
    DataDirectory = $dataRoot
    ActiveVersionDirectory = $versionRoot
    InstalledAtUtc = [DateTime]::UtcNow.ToString('o')
    Integrated = (-not $NoIntegration)
}
Write-ZedPrivateUtf8 (Join-Path $installRoot '.zed-git-layout-install.json') ($receipt | ConvertTo-Json)
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Common.ps1') -Destination $installRoot -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Uninstall.ps1') -Destination $installRoot -Force
$launcherExecutable = (Join-Path $versionRoot 'app\Zed.exe').Replace('%', '%%')
$launcherDataRoot = $dataRoot.Replace('%', '%%')
$launcher = "@echo off`r`nchcp 65001 >nul`r`nstart `"`" `"$launcherExecutable`" --user-data-dir `"$launcherDataRoot`" %*`r`n"
[IO.File]::WriteAllText((Join-Path $installRoot 'Run-Zed-Git-Layout.cmd'), $launcher, [Text.UTF8Encoding]::new($false))
$uninstallCommand = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -InstallDirectory "{1}"' -f (Join-Path $installRoot 'Uninstall.ps1'), $installRoot
if (-not $NoIntegration) {
    $shell = New-Object -ComObject WScript.Shell
    $desktop = [Environment]::GetFolderPath('Desktop')
    $startMenu = [Environment]::GetFolderPath('Programs')
    foreach ($directory in @($desktop, $startMenu)) {
        $shortcut = $shell.CreateShortcut((Join-Path $directory 'Zed Git Layout.lnk'))
        $shortcut.TargetPath = Join-Path $versionRoot 'app\Zed.exe'
        $shortcut.Arguments = '--user-data-dir "' + $dataRoot + '"'
        $shortcut.WorkingDirectory = Join-Path $versionRoot 'app'
        $shortcut.Description = 'Unofficial Zed Git Layout private build'
        $shortcut.Save()
    }
    $registryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ZedGitLayoutPrivate'
    New-Item -Path $registryPath -Force | Out-Null
    $properties = @{
        DisplayName = 'Zed Git Layout (private build)'
        DisplayVersion = $manifest.Version
        Publisher = 'Private custom build; based on Zed Industries source'
        InstallLocation = $installRoot
        DisplayIcon = (Join-Path $versionRoot 'app\Zed.exe')
        UninstallString = $uninstallCommand
    }
    foreach ($property in $properties.GetEnumerator()) {
        New-ItemProperty -Path $registryPath -Name $property.Key -Value $property.Value -PropertyType String -Force | Out-Null
    }
    New-ItemProperty -Path $registryPath -Name NoModify -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $registryPath -Name NoRepair -Value 1 -PropertyType DWord -Force | Out-Null
}
Write-Host "Installed Zed Git Layout $($manifest.Version)"
Write-Host "Run: $(Join-Path $installRoot 'Run-Zed-Git-Layout.cmd')"
Write-Host "User data: $dataRoot"
Write-Host 'Close other Zed stable windows before launching this private build.'
