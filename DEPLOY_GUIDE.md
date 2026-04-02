# Guía de Despliegue - Tenis Shark App

Esta guía te ayudará a desplegar tu aplicación a Firebase Hosting (Web) y generar el APK/AAB para Android.

## 📋 Prerrequisitos

1. **Flutter instalado** y funcionando
2. **Firebase CLI instalado**: 
   ```bash
   npm install -g firebase-tools
   ```
3. **Cuenta de Firebase** con el proyecto `tenis-shark-app` creado
4. **Android Studio** (para generar APK/AAB)

## 🚀 Paso 1: Preparar el Proyecto

### 1.1 Regenerar archivos necesarios
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 1.2 Verificar configuración de Firebase
- Asegúrate de tener `google-services.json` en `android/app/`
- Verifica que `firebase_options.dart` tenga configuración para web y Android

## 🌐 Paso 2: Desplegar para Web (Firebase Hosting)

### 2.1 Construir la aplicación para web
```bash
flutter build web --release
```

### 2.2 Iniciar sesión en Firebase CLI
```bash
firebase login
```

### 2.3 Seleccionar el proyecto
```bash
firebase use tenis-shark-app
```

### 2.4 Desplegar reglas de Firestore
```bash
firebase deploy --only firestore:rules
```

### 2.5 Desplegar a Firebase Hosting
```bash
firebase deploy --only hosting
```

### 2.6 Verificar despliegue
- Tu app web estará disponible en: `https://tenis-shark-app.web.app`
- También puedes verla en: `https://tenis-shark-app.firebaseapp.com`

## 📱 Paso 3: Generar APK/AAB para Android

### 3.1 Configurar para producción

#### Opción A: Generar APK (para testing)
```bash
flutter build apk --release
```
El APK estará en: `build/app/outputs/flutter-apk/app-release.apk`

#### Opción B: Generar AAB (para Google Play Store)
```bash
flutter build appbundle --release
```
El AAB estará en: `build/app/outputs/bundle/release/app-release.aab`

### 3.2 Verificar que google-services.json está actualizado
- Descarga el archivo más reciente desde Firebase Console
- Reemplaza `android/app/google-services.json`
- Reconstruye: `flutter build apk --release`

## 🔧 Paso 4: Verificar Configuración

### 4.1 Verificar Reglas de Firestore
1. Ve a: https://console.firebase.google.com/project/tenis-shark-app/firestore/rules
2. Confirma que las reglas estén desplegadas correctamente

### 4.2 Verificar Autenticación
1. Ve a: https://console.firebase.google.com/project/tenis-shark-app/authentication
2. Verifica que Email/Password esté habilitado

### 4.3 Verificar Hosting
1. Ve a: https://console.firebase.google.com/project/tenis-shark-app/hosting
2. Deberías ver tu sitio desplegado

## 📝 Checklist de Despliegue

- [ ] Reglas de Firestore desplegadas
- [ ] Aplicación web construida (`flutter build web --release`)
- [ ] Hosting desplegado (`firebase deploy --only hosting`)
- [ ] APK/AAB generado para Android
- [ ] google-services.json actualizado
- [ ] Probado en web
- [ ] Probado en Android (APK instalado)

## 🔄 Actualizaciones Futuras

Para actualizar la aplicación:

**Web:**
```bash
flutter build web --release
firebase deploy --only hosting
```


**Android:**
```bash
# Actualizar versión en pubspec.yaml (ej: 1.0.0+1 -> 1.0.1+2)
flutter build apk --release  # o appbundle --release
```

**Firestore Rules:**
```bash
firebase deploy --only firestore:rules
```

## 🆘 Solución de Problemas

### Error: "Firebase project not found"
- Verifica que estés usando el proyecto correcto: `firebase use tenis-shark-app`
- Verifica que tengas permisos en el proyecto

### Error: "Build failed"
- Limpia el proyecto: `flutter clean`
- Obtén dependencias: `flutter pub get`
- Reconstruye: `flutter build web --release`

### La app web no carga
- Verifica que `firebase_options.dart` tenga la configuración correcta para web
- Revisa la consola del navegador para errores
- Verifica que las reglas de Firestore permitan acceso

### El APK no funciona en Android
- Verifica que `google-services.json` esté en `android/app/`
- Revisa que la configuración de Android esté correcta en `android/app/build.gradle.kts`
- Verifica los logs: `flutter logs`

## 📚 Recursos Adicionales

- [Firebase Hosting Docs](https://firebase.google.com/docs/hosting)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)

