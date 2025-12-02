# Configuración de Firebase para Tenis Sharks App

## Pasos para configurar Firebase

### 1. Crear un proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Crear un proyecto"
3. Nombra tu proyecto (ej: "tenis-shark-app")
4. Habilita Google Analytics (opcional)
5. Crea el proyecto

### 2. Configurar Android

1. En Firebase Console, haz clic en "Agregar app" y selecciona Android
2. Ingresa el nombre del paquete: `com.example.tenis_shark_app`
3. Descarga el archivo `google-services.json`
4. Reemplaza el archivo `android/app/google-services.json` con el descargado

### 3. Configurar iOS (opcional)

1. En Firebase Console, haz clic en "Agregar app" y selecciona iOS
2. Ingresa el ID del bundle: `com.example.tenisSharkApp`
3. Descarga el archivo `GoogleService-Info.plist`
4. Colócalo en `ios/Runner/GoogleService-Info.plist`

### 4. Habilitar Firestore

1. En Firebase Console, ve a "Firestore Database"
2. Haz clic en "Crear base de datos"
3. Selecciona "Iniciar en modo de prueba" (para desarrollo)
4. Elige una ubicación para tu base de datos

### 5. Configurar reglas de Firestore

En la pestaña "Reglas" de Firestore, usa estas reglas para desarrollo:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir acceso solo a usuarios autenticados
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 6. Habilitar autenticación anónima

1. En Firebase Console, ve a "Authentication"
2. Haz clic en "Comenzar"
3. Ve a la pestaña "Sign-in method"
4. Habilita "Anónimo"

### 7. Actualizar las opciones de Firebase

1. Instala FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Configura Firebase para tu proyecto:
   ```bash
   flutterfire configure
   ```

3. Esto actualizará automáticamente el archivo `lib/firebase_options.dart`

### 8. Probar la aplicación

1. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

2. Ve a la pantalla de configuración (ícono de engranaje)
3. Verifica que aparezca "Conectado a Internet"
4. Prueba la sincronización de datos

## Características implementadas

- ✅ **Almacenamiento local**: Los datos se guardan localmente con Hive
- ✅ **Sincronización automática**: Los datos se sincronizan con Firebase cuando hay internet
- ✅ **Modo offline**: La app funciona sin internet, sincroniza cuando se conecta
- ✅ **Autenticación anónima**: Cada usuario tiene sus propios datos
- ✅ **Interfaz de configuración**: Pantalla para gestionar la sincronización
- ✅ **Estado de conexión**: Muestra si hay conexión a internet
- ✅ **Respaldo en la nube**: Los datos se respaldan automáticamente

## Estructura de datos en Firestore

```
users/{userId}/
├── jugadores/{nombreJugador}
│   ├── nombre: string
│   ├── partidosGanados: number
│   ├── partidosPerdidos: number
│   └── estadisticas: array
└── partidos/{partidoId}
    ├── fecha: timestamp
    ├── jugadores: array
    ├── sets: map
    ├── esDobles: boolean
    └── estadisticas: map
```

## Notas importantes

- Los datos se sincronizan automáticamente cuando hay conexión a internet
- Cada usuario tiene sus propios datos privados (autenticación anónima)
- La app funciona completamente offline
- Los datos se respaldan automáticamente en Firebase
- Puedes usar la app en múltiples dispositivos con la misma cuenta

