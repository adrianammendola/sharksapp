# 🔧 Configurar Firebase para Android (IMPORTANTE)

Tu configuración actual de Android tiene valores "dummy". Necesitas regenerarla con las credenciales reales.

## Pasos para configurar Android correctamente:

### 1. Instalar FlutterFire CLI (si no lo tienes)
```bash
dart pub global activate flutterfire_cli
```

### 2. Regenerar firebase_options.dart con todas las plataformas
```bash
flutterfire configure --project=tenis-shark-app
```

Cuando te pregunte qué plataformas configurar, selecciona:
- ✅ Web
- ✅ Android
- ✅ iOS (opcional)
- ✅ macOS (opcional)

### 3. Verificar que google-services.json esté actualizado
- El comando anterior debería haber actualizado `android/app/google-services.json`
- Si no, descárgalo manualmente desde:
  https://console.firebase.google.com/project/tenis-shark-app/settings/general

### 4. Verificar build.gradle.kts
Asegúrate de que `android/app/build.gradle.kts` tenga:

```kotlin
dependencies {
    // ... otras dependencias
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
```

Y en `android/build.gradle.kts`:
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

Y en `android/settings.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

### 5. Verificar después de configurar
```bash
flutter clean
flutter pub get
flutter build apk --debug  # Probar primero en debug
```

Si funciona en debug, entonces:
```bash
flutter build apk --release
```

## ⚠️ Nota Importante

**ANTES de desplegar a producción, debes:**
1. Ejecutar `flutterfire configure` para tener credenciales reales
2. Verificar que `google-services.json` esté en `android/app/`
3. Probar la app en Android antes de publicar

