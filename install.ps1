# CodeCrew Windows installer.
# Usage: powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/aichargelabs/codecrew-releases/main/install.ps1 | iex"
# CODECREW_VERSION: optional version such as 1.0.0; installs tag v1.0.0.
# CODECREW_DRY_RUN: set to 1 to resolve and print the release without downloading.
# Generated for aichargelabs/codecrew-releases. Author: aichargelabs.

function Install-CodeCrew {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $headers = @{ 'User-Agent' = 'codecrew-installer' }
        $requestedVersion = $env:CODECREW_VERSION
        if ([string]::IsNullOrWhiteSpace($requestedVersion)) {
            $releaseUrl = 'https://api.github.com/repos/aichargelabs/codecrew-releases/releases/latest'
        }
        else {
            $requestedVersion = $requestedVersion.Trim()
            $releaseUrl = 'https://api.github.com/repos/aichargelabs/codecrew-releases/releases/tags/v' + $requestedVersion
        }

        Write-Host 'Resolving CodeCrew release...'
        $release = Invoke-RestMethod -Uri $releaseUrl -Headers $headers -Method Get
        $tagName = [string]$release.tag_name
        if ([string]::IsNullOrWhiteSpace($tagName)) {
            throw 'The release response did not include a tag name.'
        }

        $version = $tagName
        if ($version.StartsWith('v')) {
            $version = $version.Substring(1)
        }
        if ([string]::IsNullOrWhiteSpace($version)) {
            throw 'The release tag did not contain a version.'
        }

        $assetName = 'CodeCrew-win32-x64-' + $version + '.exe'
        $asset = @($release.assets) | Where-Object { $_.name -ceq $assetName } | Select-Object -First 1
        if ($null -eq $asset) {
            throw ('Asset "' + $assetName + '" was not found. See https://github.com/aichargelabs/codecrew-releases/releases')
        }

        $downloadUrl = [string]$asset.browser_download_url
        if ([string]::IsNullOrWhiteSpace($downloadUrl)) {
            throw ('Asset "' + $assetName + '" did not include a download URL.')
        }

        if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
            Write-Host 'ARM64 builds are not yet available; x64 will be installed via emulation.'
        }

        if ($env:CODECREW_DRY_RUN -eq '1') {
            Write-Host ('Version: ' + $version)
            Write-Host ('Download URL: ' + $downloadUrl)
            return
        }

        $downloadDirectory = Join-Path $env:TEMP 'codecrew-install'
        New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null
        $installerPath = Join-Path $downloadDirectory $assetName

        Write-Host ('Downloading CodeCrew ' + $version + '...')
        Invoke-WebRequest -Uri $downloadUrl -Headers $headers -OutFile $installerPath -UseBasicParsing
        if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
            throw ('Download did not create the installer at ' + $installerPath)
        }
        $fileSize = (Get-Item -LiteralPath $installerPath).Length
        Write-Host ('Downloaded: ' + $fileSize + ' bytes')

        Write-Host 'Installing CodeCrew...'
        $process = Start-Process -FilePath $installerPath -ArgumentList '/S' -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw ('The installer exited with code ' + $process.ExitCode)
        }

        $installLocation = Join-Path $env:LOCALAPPDATA 'Programs\CodeCrew'
        if (Test-Path -LiteralPath $installLocation -PathType Container) {
            Write-Host ('Installed to: ' + (Get-Item -LiteralPath $installLocation).FullName)
        }
        else {
            Write-Host ('Install completed. Expected per-user location: ' + $installLocation)
        }
        Remove-Item -LiteralPath $installerPath -Force
        Write-Host 'CodeCrew installed successfully.'
        Write-Host 'Launch it from the Start Menu: CodeCrew'
    }
    catch {
        Write-Error ('CodeCrew installation failed: ' + $_.Exception.Message)
        if ($installerPath -and (Test-Path -LiteralPath $installerPath)) {
            Write-Error ('The downloaded installer was left at: ' + $installerPath)
        }
        exit 1
    }
}

Install-CodeCrew
