# CodeCrew

Agentic code terminal by aichargelabs.

## Install

### Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/aichargelabs/codecrew-releases/main/install.ps1 | iex"
```

### macOS / Linux

```sh
curl -fsSL https://raw.githubusercontent.com/aichargelabs/codecrew-releases/main/install.sh | sh
```

macOS and Linux binaries are coming soon. The script exits gracefully until they are published.

## Pin a version

Windows:

```powershell
$env:CODECREW_VERSION = "v1.0.1"
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/aichargelabs/codecrew-releases/main/install.ps1 | iex"
```

macOS / Linux:

```sh
CODECREW_VERSION=v1.0.1 curl -fsSL https://raw.githubusercontent.com/aichargelabs/codecrew-releases/main/install.sh | sh
```

## Manual download

See the [latest CodeCrew release](https://github.com/aichargelabs/codecrew-releases/releases/latest).

| Name | Platform | Format |
| --- | --- | --- |
| [CodeCrew-win32-x64-1.0.1.exe](https://github.com/aichargelabs/codecrew-releases/releases/download/v1.0.1/CodeCrew-win32-x64-1.0.1.exe) | Windows x64 | Installer (EXE) |
| [CodeCrew-win32-x64-1.0.1.msi](https://github.com/aichargelabs/codecrew-releases/releases/download/v1.0.1/CodeCrew-win32-x64-1.0.1.msi) | Windows x64 | Installer (MSI) |
| [CodeCrew-win32-x64-1.0.1.zip](https://github.com/aichargelabs/codecrew-releases/releases/download/v1.0.1/CodeCrew-win32-x64-1.0.1.zip) | Windows x64 | Portable archive (ZIP) |

## What the installer does

Windows:

- Downloads the latest matching release from this repository.
- Runs the installer silently when installation requires it.
- Does not install telemetry.
- Does not request administrator access unless Windows requires it.

macOS:

- Downloads the latest matching release when macOS builds are available.
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

Builds are unsigned for now. SHA256 sums will be published as release assets in the future. Verify that downloads come only from this repository's Releases.

CodeCrew is developed by aichargelabs and built on the shoulders of the open-source Wave Terminal project.
