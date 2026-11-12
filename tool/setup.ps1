$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$tmp = Join-Path $env:TEMP ("klarwave-scaffold-" + [guid]::NewGuid().ToString('N'))

flutter create --platforms=android,ios --org com.klarwave --project-name music $tmp
if ($LASTEXITCODE -ne 0) { throw "flutter create gagal" }

Copy-Item -Recurse -Force (Join-Path $tmp 'android') .
Copy-Item -Recurse -Force (Join-Path $tmp 'ios') .
Remove-Item -Recurse -Force $tmp

Copy-Item -Force 'platform_overrides/android/app/src/main/AndroidManifest.xml' 'android/app/src/main/AndroidManifest.xml'
New-Item -ItemType Directory -Force 'android/app/src/main/kotlin/com/klarwave/music' | Out-Null
Copy-Item -Force 'platform_overrides/android/app/src/main/kotlin/com/klarwave/music/MainActivity.kt' 'android/app/src/main/kotlin/com/klarwave/music/MainActivity.kt'
Copy-Item -Force 'platform_overrides/ios/Runner/Info.plist' 'ios/Runner/Info.plist'

# Lint rilis AGP bisa crash saat menganalisis plugin (mis. url_launcher).
# Lint tidak memengaruhi APK, jadi lewati untuk build release.
$lintBlock = @'

android {
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}
'@
Add-Content -Path 'android/app/build.gradle.kts' -Value $lintBlock

Write-Host 'Folder android/ dan ios/ siap dipakai.'
