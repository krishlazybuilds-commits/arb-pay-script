# ARBPay Bot - Build and deploy to emulator

$ADB  = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$APK  = "e:\ARB Pay Script\arbpay_apk\build\app\outputs\flutter-apk\app-release.apk"
$PKG  = "com.arbpay.bot"
$PROJ = "e:\ARB Pay Script\arbpay_apk"

Write-Host ">>> [1/5] Force-deleting build cache..." -ForegroundColor Cyan
Set-Location $PROJ
# Forcefully remove build artifacts that flutter clean sometimes can't delete
if (Test-Path "$PROJ\build") {
    Remove-Item -Recurse -Force "$PROJ\build" -ErrorAction SilentlyContinue
}
if (Test-Path "$PROJ\.dart_tool") {
    Remove-Item -Recurse -Force "$PROJ\.dart_tool" -ErrorAction SilentlyContinue
}
flutter clean

Write-Host ">>> [2/5] Building APK..." -ForegroundColor Cyan
flutter build apk --release

Write-Host ">>> [3/5] Killing + wiping old app data..." -ForegroundColor Cyan
& $ADB shell am force-stop $PKG
& $ADB shell pm clear $PKG

Write-Host ">>> [4/5] Uninstalling old APK..." -ForegroundColor Cyan
& $ADB uninstall $PKG

Write-Host ">>> [5/6] Installing new APK..." -ForegroundColor Cyan
& $ADB install $APK

Write-Host ">>> [6/6] Saving snapshot + launching..." -ForegroundColor Cyan
# Force-stop any stale running process before launching the new build
& $ADB shell am force-stop $PKG
Start-Sleep -Seconds 2
# Save emulator snapshot NOW so Quick Boot loads the new APK on next start
& $ADB emu avd snapshot save default_boot
# -S = force-stop before start, guarantees new process loads the new APK
& $ADB shell am start -S -n "$PKG/.MainActivity"

Write-Host "`nDone!" -ForegroundColor Green
