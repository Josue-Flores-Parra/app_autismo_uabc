# Documentación: Configuración de Firebase de Prueba para T51

## Contexto

Mientras trabajaba en la implementación de la lógica de autenticación (T51), me di cuenta de que no tenía acceso a las credenciales del proyecto Firebase original que se configuró en un issue anterior. Como necesitaba probar que mi código de autenticación funcionara correctamente, decidí crear una rama temporal con mis propias credenciales de Firebase para realizar las pruebas.

## Lo que Hice

### 1. Crear Rama Temporal de Pruebas

Primero creé una rama temporal para aislar los cambios de configuración de Firebase:

```bash
git checkout -b temp/firebase-test-credentials
```

Esta rama me permitió trabajar con mis propias credenciales de Firebase sin afectar la rama principal `T51-auth-logic`.

### 2. Configurar Mi Proyecto Firebase de Prueba

Creé un nuevo proyecto en Firebase Console para poder probar mi implementación:

1. Accedí a [Firebase Console](https://console.firebase.google.com/)
2. Creé un nuevo proyecto llamado `papu123-69750`
3. Registré la aplicación web en el proyecto

### 3. Habilitar Firebase Authentication

Este paso fue **crucial**. Configuré el método de autenticación:

1. En Firebase Console, fui a la sección **Authentication**
2. Hice clic en **"Comenzar"**
3. Habilitamos el método **"Email/Password"**
4. Guardamos los cambios

**Nota importante**: Sin habilitar explícitamente este método de autenticación, las llamadas a `createUserWithEmailAndPassword` y `signInWithEmailAndPassword` fallan con el error "operation-not-allowed".

### 4. Configurar Firestore Database

Como mi implementación guarda datos adicionales del usuario en Firestore (nombre, email, fecha de creación), necesité configurar la base de datos:

1. Accedí a **Firestore Database** en Firebase Console
2. Creé la base de datos en **modo de producción**
3. Seleccioné la región apropiada
4. Configuré las reglas de seguridad para permitir que los usuarios autenticados accedan solo a sus propios datos:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Estas reglas aseguran que cada usuario solo pueda leer y escribir sus propios datos, lo cual es seguro y apropiado para producción.

### 5. Actualizar Credenciales en el Código

Actualicé los archivos de configuración para apuntar a mi proyecto de prueba:

**`lib/firebase_options.dart`**:
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyC5JM0M1bxDncXABxEzAhN53JOqvH_cSvM',
  appId: '1:433424866371:web:02950fadc0e3d6ab4d88f6',
  messagingSenderId: '433424866371',
  projectId: 'papu123-69750',
  authDomain: 'papu123-69750.firebaseapp.com',
  storageBucket: 'papu123-69750.firebasestorage.app',
  measurementId: 'G-SJ4GW3WJK0',
);
```

También actualicé `firebase.json` para reflejar el nuevo proyecto.

### 6. Pruebas Realizadas

Ejecuté la aplicación web y probé las siguientes funcionalidades:

```bash
flutter run -d chrome
```

**Pruebas de Registro:**
- ✅ Creé una cuenta nueva con nombre, email y contraseña
- ✅ Verifiqué que el usuario se creó en Firebase Authentication
- ✅ Confirmé que los datos del usuario se guardaron correctamente en Firestore
- ✅ La navegación a `MainShell` funcionó correctamente

**Pruebas de Login:**
- ✅ Inicié sesión con las credenciales creadas
- ✅ El flujo de autenticación funcionó correctamente
- ✅ La navegación post-login funcionó como esperado

## Resultados

La implementación de autenticación funciona correctamente. Los siguientes componentes fueron probados exitosamente:

- `AuthService` - Registro, login y logout
- `AuthViewModel` - Manejo de estados y errores
- `LoginScreen` - UI y validaciones
- `RegisterScreen` - UI y validaciones
- Integración con Firebase Auth y Firestore

## Próximos Pasos

- Subire la rama temporal como `TEST-T51-auth-logic` para referencia
- Subir`T51-auth-logic` para iniciar el pull request

---

**Nota**: Este proyecto Firebase (`papu123-69750`) es temporal (mio) y **solo fue para pruebas**.  Las credenciales aquí mostradas solo fueron utilizadas para la rama de pruebas, la rama principal `T51-auth-logic` tiene las credenciales orginales.

