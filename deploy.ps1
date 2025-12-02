# Script de Despliegue para Tenis Shark App
# PowerShell Script para Windows

Write-Host "🚀 Iniciando despliegue de Tenis Shark App..." -ForegroundColor Cyan

# Paso 1: Regenerar archivos
Write-Host "`n📦 Paso 1: Regenerando archivos necesarios..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al regenerar archivos" -ForegroundColor Red
    exit 1
}

# Paso 2: Limpiar y obtener dependencias
Write-Host "`n🧹 Paso 2: Limpiando proyecto..." -ForegroundColor Yellow
flutter clean
flutter pub get

# Paso 3: Desplegar reglas de Firestore
Write-Host "`n🔥 Paso 3: Desplegando reglas de Firestore..." -ForegroundColor Yellow
firebase use tenis-shark-app
firebase deploy --only firestore:rules
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al desplegar reglas de Firestore" -ForegroundColor Red
    exit 1
}

# Paso 4: Construir para Web
Write-Host "`n🌐 Paso 4: Construyendo aplicación web..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al construir para web" -ForegroundColor Red
    exit 1
}

# Paso 5: Desplegar a Firebase Hosting
Write-Host "`n📤 Paso 5: Desplegando a Firebase Hosting..." -ForegroundColor Yellow
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al desplegar a hosting" -ForegroundColor Red
    exit 1
}

# Paso 6: Construir para Android
Write-Host "`n📱 Paso 6: Construyendo APK para Android..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al construir APK" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ ¡Despliegue completado exitosamente!" -ForegroundColor Green
Write-Host "`n📋 Resumen:" -ForegroundColor Cyan
Write-Host "  • Web: https://tenis-shark-app.web.app" -ForegroundColor White
Write-Host "  • APK: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor White

