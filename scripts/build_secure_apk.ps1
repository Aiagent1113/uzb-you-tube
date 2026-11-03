# =======================================================================
# UzDub YouTube AI - Secure Release APK Compilation Script
# Enforces Dart symbol obfuscation and separate debug symbol stripping
# =======================================================================

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path "$PSScriptRoot\..\flutter_app"
$SymbolsDir = "$PSScriptRoot\..\build\symbols"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   UZDUB YOUTUBE AI - SECURE COMPILATION PIPELINE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Ensure symbols directory exists (saved off-device to prevent reverse-engineering)
if (-not (Test-Path $SymbolsDir)) {
    New-Item -ItemType Directory -Path $SymbolsDir -Force | Out-Null
    Write-Host "[+] Created secure symbols directory: $SymbolsDir" -ForegroundColor Green
}

# 2. Re-obfuscate JavaScript injection core
Write-Host "[*] Compiling & obfuscating JavaScript injection payload..." -ForegroundColor Yellow
Push-Location "$PSScriptRoot\..\injection\scripts"
node obfuscate.js
Pop-Location

# 3. Compile Flutter release APK with strict obfuscation flags
Write-Host "[*] Compiling Flutter APK with --obfuscate and --split-debug-info..." -ForegroundColor Yellow
Push-Location $ProjectRoot
flutter build apk --release `
    --obfuscate `
    --split-debug-info=$SymbolsDir `
    --target-platform=android-arm64,android-arm

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Obfuscated APK successfully created!" -ForegroundColor Green
    Write-Host "[!] Debug symbols isolated in: $SymbolsDir (DO NOT DISTRIBUTE THIS FOLDER)" -ForegroundColor Red
} else {
    Write-Host "[!] Build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
}
Pop-Location
