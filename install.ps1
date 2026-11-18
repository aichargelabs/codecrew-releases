# CodeCrew Windows installer.
# Usage: powershell -ExecutionPolicy Bypass -Command "irm https://codecrew.aichargelabs.com/install.ps1 | iex"
# CODECREW_INSTALL_VERSION: optional version such as 1.0.0; installs tag v1.0.0.
# CODECREW_VERSION: same, honoured only outside a CodeCrew terminal (which exports the app's own version).
# CODECREW_DRY_RUN: set to 1 to resolve and print the release without downloading.
# Generated for aichargelabs/codecrew-releases. Author: aichargelabs.

function Install-CodeCrew {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $headers = @{ 'User-Agent' = 'codecrew-installer' }
        $requestedVersion = $env:CODECREW_INSTALL_VERSION
        if ([string]::IsNullOrWhiteSpace($requestedVersion) -and $env:CODECREW -ne '1') {
            $requestedVersion = $env:CODECREW_VERSION
        }

        Write-Host 'Resolving CodeCrew release...'
        if ([string]::IsNullOrWhiteSpace($requestedVersion)) {
            # Releases are published per platform, so the newest one can carry only macOS
            # assets and /releases/latest cannot answer "newest Windows build". Walk the
            # list newest-first and take the first full release that has the installer.
            $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/aichargelabs/codecrew-releases/releases?per_page=30' -Headers $headers -Method Get
            $release = $null
            foreach ($candidate in @($releases)) {
                if ($candidate.draft -or $candidate.prerelease) { continue }
                $candidateAsset = 'CodeCrew-win32-x64-' + (([string]$candidate.tag_name) -replace '^v', '') + '.exe'
                if (@($candidate.assets) | Where-Object { $_.name -ceq $candidateAsset }) {
                    $release = $candidate
                    break
                }
            }
            if ($null -eq $release) {
                throw 'No published CodeCrew release includes a Windows x64 installer. See https://github.com/aichargelabs/codecrew-releases/releases'
            }
        }
        else {
            $requestedVersion = $requestedVersion.Trim() -replace '^v', ''
            $releaseUrl = 'https://api.github.com/repos/aichargelabs/codecrew-releases/releases/tags/v' + $requestedVersion
            $release = Invoke-RestMethod -Uri $releaseUrl -Headers $headers -Method Get
        }
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

        # Per-run directory: a fixed path collides when two installs overlap (the first
        # installer still holds the file open while the second tries to overwrite it).
        $downloadDirectory = Join-Path (Join-Path $env:TEMP 'codecrew-install') ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null
        $installerPath = Join-Path $downloadDirectory $assetName

        # A dropped connection can end Invoke-WebRequest early without an error, and NSIS
        # then fails on the cut-off file with a bare exit code. Check the byte count against
        # the release asset and the SHA-256 against SHA256SUMS.txt, and retry before giving up.
        $expectedSize = [long]$asset.size
        $expectedHash = $null
        $sumsAsset = @($release.assets) | Where-Object { $_.name -ceq 'SHA256SUMS.txt' } | Select-Object -First 1
        if ($null -ne $sumsAsset) {
            try {
                $sums = Invoke-WebRequest -Uri ([string]$sumsAsset.browser_download_url) -Headers $headers -UseBasicParsing
                $sumsText = $sums.Content
                if ($sumsText -is [byte[]]) { $sumsText = [Text.Encoding]::ASCII.GetString($sumsText) }
                foreach ($line in ([string]$sumsText -split "`n")) {
                    $parts = $line.Trim() -split '\s+'
                    if ($parts.Count -ge 2 -and $parts[-1].TrimStart('*') -ceq $assetName) {
                        $expectedHash = $parts[0].ToLowerInvariant()
                        break
                    }
                }
            }
            catch {
                Write-Host 'Checksum list not reachable; checking the file size only.'
            }
        }

        $maxAttempts = 3
        $downloadOk = $false
        $problem = ''
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            if ($attempt -eq 1) {
                Write-Host ('Downloading CodeCrew ' + $version + '...')
            }
            else {
                Write-Host ('Retrying the download (' + $attempt + ' of ' + $maxAttempts + ')...')
            }
            Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
            try {
                Invoke-WebRequest -Uri $downloadUrl -Headers $headers -OutFile $installerPath -UseBasicParsing
            }
            catch {
                $problem = 'the download stopped: ' + $_.Exception.Message
                Write-Host ('Download attempt ' + $attempt + ' failed: ' + $problem)
                continue
            }
            if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
                $problem = 'the download did not create the installer file'
                continue
            }
            $fileSize = (Get-Item -LiteralPath $installerPath).Length
            Write-Host ('Downloaded: ' + $fileSize + ' bytes')
            if ($expectedSize -gt 0 -and $fileSize -ne $expectedSize) {
                $problem = 'the download was cut off (' + $fileSize + ' of ' + $expectedSize + ' bytes)'
                Write-Host ('Download attempt ' + $attempt + ': ' + $problem)
                continue
            }
            if ($expectedHash) {
                # .NET directly: Get-FileHash fails to load when PSModulePath is inherited from pwsh 7.
                $sha = [Security.Cryptography.SHA256]::Create()
                $stream = [IO.File]::OpenRead($installerPath)
                try { $actualHash = -join ($sha.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) }
                finally { $stream.Dispose(); $sha.Dispose() }
                if ($actualHash -ne $expectedHash) {
                    $problem = 'the downloaded file does not match its published SHA-256'
                    Write-Host ('Download attempt ' + $attempt + ': ' + $problem)
                    continue
                }
                Write-Host 'Checksum OK.'
            }
            $downloadOk = $true
            break
        }
        if (-not $downloadOk) {
            Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
            $installerPath = $null
            throw ('Could not get a complete installer after ' + $maxAttempts + ' tries: ' + $problem + '. Check your internet connection and run the same line again.')
        }

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
        Remove-Item -LiteralPath $downloadDirectory -Recurse -Force
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
