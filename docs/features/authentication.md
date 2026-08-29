# Feature: authentication

## Proposito

La feature de autenticacion permite registrar usuarios, iniciar sesion, cerrar
sesion y ejecutar operaciones basicas de cuenta con Firebase Auth. Tambien
escribe datos basicos del usuario en Firestore mediante `FirestoreService`.

## Archivos principales

```text
lib/features/authentication/view/auth_gate.dart
lib/features/authentication/view/login_screen.dart
lib/features/authentication/view/register_screen.dart
lib/features/authentication/view/forgot_password_screen.dart
lib/features/authentication/viewmodel/auth_viewmodel.dart
lib/data/services/auth_services.dart
```

Archivos relacionados aunque no vivan dentro de la feature:

```text
lib/features/home/view/main_shell.dart
lib/features/settings/view/settings_page.dart
lib/data/services/firestore_services.dart
lib/features/learning_module/data/video_controller_manager.dart
```

## Capas y dependencias

Flujo ideal y mayoritario:

```text
View
  -> AuthViewModel
    -> AuthService
      -> FirebaseAuth
      -> FirestoreService
```

Dependencias reales:

- `AuthViewModel` crea internamente `AuthService`.
- `AuthService` crea internamente `FirebaseAuth.instance`.
- `AuthService` crea internamente `FirestoreService`.
- `AuthService.logout()` llama `VideoControllerManager().disposeAll()` antes de `signOut`.

No hay inyeccion por constructor, por lo que los tests de esta feature no pueden
sustituir facilmente Firebase Auth o Firestore sin refactor.

## AuthViewModel

Archivo:

```text
lib/features/authentication/viewmodel/auth_viewmodel.dart
```

Estado expuesto:

| Getter | Tipo | Descripcion |
| --- | --- | --- |
| `isLoading` | `bool` | Indica operacion en curso. |
| `errorMessage` | `String?` | Mensaje listo para mostrar en UI. |
| `currentUser` | `User?` | Usuario actual segun AuthService. Se siembra en el constructor desde `AuthService.currentUser`, por lo que una sesion persistida por Firebase se restaura sincronicamente. |
| `registrationSuccess` | `bool` | Bandera que indica que el ultimo registro fue exitoso; la consume `LoginScreen` para mostrar un cue. |

Metodos publicos:

| Metodo | Resultado | Detalle |
| --- | --- | --- |
| `login(email, password)` | `Future<bool>` | Actualiza `_currentUser` si Firebase responde usuario. |
| `register(email, password, name)` | `Future<bool>` | Crea usuario y cierra la sesion que Firebase abre automaticamente; marca `registrationSuccess=true` y deja `_currentUser` en `null`. |
| `resetPassword(email)` | `Future<bool>` | Envia correo de restablecimiento. Devuelve `true` para `user-not-found` e `invalid-email` (mensaje generico, sin enumerar usuarios). |
| `logout()` | `Future<void>` | Cierra sesion y limpia `_currentUser`. |
| `clearError()` | `void` | Limpia `errorMessage`. |
| `clearRegistrationSuccess()` | `void` | Limpia la bandera `registrationSuccess` tras mostrar el cue. |
| `updateDisplayName(name)` | `Future<bool>` | Actualiza display name y refresca usuario. |
| `changePassword(newPassword)` | `Future<bool>` | Cambia password del usuario actual. |
| `deleteAccount()` | `Future<bool>` | Marca `deletedAt`, elimina cuenta y limpia `_currentUser`. |

Cada operacion cambia `isLoading`, limpia errores al inicio cuando aplica y usa
`notifyListeners()` despues de cambios de estado.

## AuthService

Archivo:

```text
lib/data/services/auth_services.dart
```

Operaciones reales:

### Registro

`register(email, password, name)` ejecuta:

1. `FirebaseAuth.createUserWithEmailAndPassword`.
2. Si `result.user != null`, llama `updateDisplayName(name)`.
3. Escribe en `users/{uid}` con merge:

```json
{
  "name": "Nombre",
  "email": "correo@example.com",
  "createdAt": "2026-06-11T..."
}
```

4. Ejecuta `user.reload()`.
5. Retorna `result.user`.

Nota: `AuthViewModel.register` cierra la sesion auto-iniciada por Firebase
(`logout()`) justo despues para que el usuario inicie sesion manualmente.

### Restablecimiento de password

`sendPasswordResetEmail(email)` llama:

```text
FirebaseAuth.sendPasswordResetEmail(email: email)
```

Usado por `ForgotPasswordScreen` via `AuthViewModel.resetPassword`.

### Login

`login(email, password)` llama:

```text
FirebaseAuth.signInWithEmailAndPassword(email, password)
```

Retorna `result.user`.

### Logout

`logout()` ejecuta:

1. `VideoControllerManager().disposeAll()`.
2. `FirebaseAuth.signOut()`.

Este orden es intencional: libera controladores nativos de video antes de
destruir la sesion.

### Actualizacion de nombre

`updateDisplayName(name)`:

1. Retorna `false` si no hay usuario actual.
2. Llama `user.updateDisplayName(name)`.
3. Escribe `{ "name": name }` en `users/{uid}` con merge.
4. Ejecuta `user.reload()`.
5. Retorna `true`.

`SettingsPage` ademas sincroniza el nombre del avatar llamando
`AvatarViewModel.updateNombreDesdeDisplayName(result)` si el cambio fue exitoso.

### Cambio de password

`changePassword(newPassword)`:

- Retorna `false` si no hay usuario actual.
- Llama `user.updatePassword(newPassword)`.
- Retorna `true`.

Firebase puede exigir reautenticacion reciente; el codigo actual solo captura
`FirebaseAuthException` en el ViewModel y muestra mensaje generico segun el code.

### Eliminacion de cuenta

`deleteAccount()`:

1. Retorna `false` si no hay usuario actual.
2. Escribe `deletedAt` ISO 8601 en `users/{uid}` con merge.
3. Llama `user.delete()`.
4. Retorna `true`.

No borra subcolecciones `progress`, ni limpia documentos de `modules`.

## AuthGate

Archivo:

```text
lib/features/authentication/view/auth_gate.dart
```

`main.dart` usa `home: const AuthGate()` como pantalla inicial. Es un
`StatefulWidget` que:

- Muestra un `CircularProgressIndicator` centrado hasta el primer post-frame
  callback (evita un flash y cubre la restauracion sincrona de la sesion).
- Usa `Consumer<AuthViewModel>` para escuchar cambios de `currentUser`.
- `currentUser == null` → `LoginScreen`.
- `currentUser != null` → `MainShell`.

Como `AuthViewModel` notifica en cada mutacion de `_currentUser` (login, logout,
deleteAccount, registro), el gate hace el swap automatico y **elimina la
navegacion imperativa** (`pushReplacement` / `pushAndRemoveUntil`) que antes
hacia login, registro, settings y registro.

## LoginScreen

Archivo:

```text
lib/features/authentication/view/login_screen.dart
```

Mecanica real:

- Es `StatefulWidget`.
- Usa `TextEditingController` para email y password.
- Usa `GlobalKey<FormState>` para validacion.
- Limpia errores de `AuthViewModel` cuando el usuario escribe.
- Valida:
  - email no vacio.
  - email contiene `@`.
  - password no vacio.
  - password con minimo 6 caracteres.
- Muestra avatar `assets/images/salute.png` cuando no hay error.
- Cambia a `assets/images/icon-questionmark2x.png` si hay error de Auth o validacion.
- Al hacer login:
  - Oculta teclado.
  - Captura `LoadingService` antes de cualquier `await` (el context puede
    desmontarse cuando `AuthGate` hace swap a `MainShell`).
  - Ejecuta `AuthViewModel.login`.
  - Fuerza una espera minima de 2 segundos con `Future.delayed`.
  - Oculta loading con `finally` (funciona aun si `LoginScreen` fue desmontado).
  - El swap a `MainShell` lo maneja `AuthGate` via `Consumer<AuthViewModel>`.
- Escucha `AuthViewModel.registrationSuccess` con un listener y, si esta activo,
  muestra un cue superior-central "Registro exitoso, puedes iniciar sesión ahora"
  durante 3 segundos y luego llama `clearRegistrationSuccess()`.
- El link "¿Olvidaste tu contraseña?" limpia errores y hace
  `Navigator.push` a `ForgotPasswordScreen`.
- El link "Regístrate" hace `Navigator.push` a `RegisterScreen`.

## RegisterScreen

Archivo:

```text
lib/features/authentication/view/register_screen.dart
```

Mecanica real:

- Es `StatefulWidget`.
- Usa controladores para nombre, email y password.
- Valida:
  - nombre no vacio.
  - email no vacio.
  - email contiene `@`.
  - password no vacio.
  - password con minimo 6 caracteres.
- Llama `AuthViewModel.register`. Como el registro cierra la sesion y marca
  `registrationSuccess`, el `AuthGate` permanece en `LoginScreen` y muestra el
  cue de exito; `RegisterScreen` solo hace `Navigator.pop()`.
- Muestra error de `AuthViewModel.errorMessage`.
- El link "Inicia sesión" hace `Navigator.pop()` (vuelve al `LoginScreen` del gate).
- Usa textos hardcodeados en espanol, no ARB.

## ForgotPasswordScreen

Archivo:

```text
lib/features/authentication/view/forgot_password_screen.dart
```

Mecanica real:

- Es `StatefulWidget` con `_emailController`, `_formKey` y `_showSuccess`.
- Paleta identica a `RegisterScreen` y `AppBar` "Recuperar contraseña".
- Muestra la imagen `assets/images/forgot-password.png`.
- Valida email no vacio y que contenga `@`.
- Llama `AuthViewModel.resetPassword` con indicador de carga.
- En exito muestra un bloque verde con el mensaje generico
  "Si el correo está registrado, recibirás un enlace para restablecer tu
  contraseña." y un boton "Volver a iniciar sesión" que hace `pop()`.
- En error inesperado muestra el bloque rojo de `errorMessage`.

## Mensajes de error

`AuthViewModel._handleAuthError` traduce estos `FirebaseAuthException.code`:

| Code | Mensaje |
| --- | --- |
| `user-not-found` | No existe una cuenta con este correo electronico |
| `wrong-password` | Contrasena incorrecta |
| `email-already-in-use` | Este correo electronico ya esta en uso |
| `weak-password` | La contrasena es demasiado debil |
| `invalid-email` | El correo electronico no es valido |
| `invalid-credential` | Credenciales invalidas. Verifica tu correo y contrasena |
| `operation-not-allowed` | La autenticacion por email/password no esta habilitada. |
| default | `Error de autenticacion (<code>): <message>` |

Otros errores se muestran como:

```text
Error inesperado: ...
Error al cerrar sesion: ...
No se pudo actualizar el nombre: ...
No se pudo actualizar la contrasena: ...
No se pudo eliminar la cuenta: ...
```

En `resetPassword` los codigos `user-not-found` e `invalid-email` **no** se
muestran como error: el ViewModel devuelve `true` para no revelar si el correo
esta registrado. Solo errores inesperados muestran `errorMessage`.

## Settings y cuenta

`SettingsPage` usa `AuthViewModel` para:

- Editar display name.
- Cambiar password.
- Cerrar sesion.
- Eliminar cuenta.

Al cerrar sesion desde Settings:

1. Llama `auth.logout()`.
2. Muestra snackbar.
3. El swap a `LoginScreen` lo maneja `AuthGate` via `Consumer<AuthViewModel>`.

Al eliminar cuenta:

1. Pide escribir `BORRAR` en espanol o `DELETE` en ingles, segun l10n.
2. Si confirma, llama `auth.deleteAccount()`.
3. En exito, `deleteAccount()` limpia `_currentUser` y `AuthGate` hace el swap a
   `LoginScreen` (sin navegacion imperativa).
4. Si falla, muestra snackbar.

## PIN de Ajustes

Aunque no esta dentro de `features/authentication`, el flujo de recuperacion de
PIN usa Firebase Auth.

Archivo:

```text
lib/features/home/view/main_shell.dart
```

Si el usuario toca "Olvide el PIN":

1. Toma `FirebaseAuth.instance.currentUser?.email`.
2. Pide password.
3. Crea credencial con `EmailAuthProvider.credential`.
4. Ejecuta `reauthenticateWithCredential`.
5. Borra `settingsPin` con `PinService.clearPin`.
6. Pide crear PIN nuevo.

## Reglas de mantenimiento

- No agregar proveedores sociales directamente en las pantallas; encapsular en `AuthService`.
- Si un flujo requiere reautenticacion, documentarlo en esta pagina.
- Si se agregan campos a `users/{uid}`, actualizar `docs/data-model.md`.
- Si se cambia logout, revisar `VideoControllerManager.disposeAll()`.
- Mantener los swaps de pantalla reactivos via `AuthGate`; no reintroducir `Navigator.pushReplacement`/`pushAndRemoveUntil` para login/logout/registro.
- Si se cambia el mensaje de exito de `resetPassword`, mantener el enfoque generico (no revelar si el correo existe).
