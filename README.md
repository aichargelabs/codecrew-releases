# CodeCrew

Agentic code terminal by aichargelabs.

## Install

### Windows (PowerShell)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm https://codecrew.aichargelabs.com/install.ps1)"
```

### macOS / Linux

```sh
curl -fsSL https://codecrew.aichargelabs.com/install.sh | sh
```

macOS builds are published for Apple silicon (arm64). Linux binaries are not published yet; the script exits gracefully on Linux.

## Pin a version

Windows:

```powershell
$env:CODECREW_VERSION = "v2.1.0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm https://codecrew.aichargelabs.com/install.ps1)"
```

macOS / Linux:

```sh
CODECREW_VERSION=v2.1.0 curl -fsSL https://codecrew.aichargelabs.com/install.sh | sh
```

## Manual download

See the [latest CodeCrew release](https://github.com/aichargelabs/codecrew-releases/releases/latest).

| Name | Platform | Format |
| --- | --- | --- |
| [CodeCrew-win32-x64-2.1.0.exe](https://github.com/aichargelabs/codecrew-releases/releases/download/v2.1.0/CodeCrew-win32-x64-2.1.0.exe) | Windows x64 | Installer (EXE) |
| [CodeCrew-win32-x64-2.1.0.msi](https://github.com/aichargelabs/codecrew-releases/releases/download/v2.1.0/CodeCrew-win32-x64-2.1.0.msi) | Windows x64 | Installer (MSI) |
| [CodeCrew-win32-x64-2.1.0.zip](https://github.com/aichargelabs/codecrew-releases/releases/download/v2.1.0/CodeCrew-win32-x64-2.1.0.zip) | Windows x64 | Portable archive (ZIP) |
| [CodeCrew-darwin-arm64-2.1.0.dmg](https://github.com/aichargelabs/codecrew-releases/releases/download/v2.1.0/CodeCrew-darwin-arm64-2.1.0.dmg) | macOS arm64 | Disk image (DMG) |
| [CodeCrew-darwin-arm64-2.1.0.zip](https://github.com/aichargelabs/codecrew-releases/releases/download/v2.1.0/CodeCrew-darwin-arm64-2.1.0.zip) | macOS arm64 | Portable archive (ZIP) |

## What the installer does

Windows:

- Downloads the latest matching release from this repository.
- Runs the installer silently when installation requires it.
- Does not install telemetry.
- Does not request administrator access unless Windows requires it.

macOS:

- Downloads the latest matching release for Apple silicon (arm64).
- Copies CodeCrew.app to `/Applications`.
- Does not install telemetry.
- Does not request administrator access unless macOS requires it.

Linux:

- Downloads the latest matching release when Linux builds are available.
- Installs the AppImage at `~/.local/bin/codecrew` and its desktop entry.
- Does not install telemetry.
- Does not request administrator access.

## Package managers

- winget: PLANNED
- Homebrew: PLANNED
- apt: PLANNED

No package manager IDs are published yet.

## Uninstall

- Windows: use Apps > Installed apps, or the NSIS uninstaller in the install directory.
- macOS: delete `/Applications/CodeCrew.app`.
- Linux: remove `~/.local/bin/codecrew` and the CodeCrew `.desktop` file.

## Security

Builds are unsigned for now. On macOS, right-click the app and choose Open the first time. Every release publishes a `SHA256SUMS.txt` asset; verify your download against it, and only download from this repository's Releases.

CodeCrew is developed by aichargelabs.
