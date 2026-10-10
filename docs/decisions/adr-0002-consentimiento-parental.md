# ADR 0002: Consentimiento parental con "email plus"

## Estado

Aceptado (octubre de 2026).

## Contexto

Appy se publica en la categoría infantil de App Store y en el programa de
familias de Google Play, para menores de 13 años, y está disponible en Estados
Unidos. Google Play pide certificar el cumplimiento de COPPA y del GDPR, y la
categoría Kids de Apple exige lo mismo.

Hasta la versión 1 de los documentos legales, el consentimiento era una casilla
en la que la persona adulta declaraba ser mayor de edad y tutora del menor, y su
correo nunca se verificaba. Para la FTC, esa autodeclaración no es un método
válido de consentimiento parental verificable.

Los datos de los perfiles infantiles (avance, avatar, preferencias y métricas
opcionales) solo se usan dentro del proyecto: no se venden, no hay publicidad ni
se comparten con terceros. Para ese caso, la regla de COPPA acepta el método
"email plus".

## Decisión

Usar "email plus":

1. **Correo verificado.** `AuthGate` muestra `VerifyEmailScreen` hasta que
   Firebase Auth marca el correo como verificado. Ningún perfil infantil se
   crea ni se usa antes.
2. **Aceptación expresa.** La persona adulta lee y acepta los documentos. Se
   guarda `users/{uid}.legal` con `consentMethod: 'email_plus'`, una hora de
   servidor y `confirmationPending: true`.
3. **Confirmación diferida.** La función programada
   `sendConsentConfirmations` (`functions/`) envía, al menos 24 horas después,
   un correo bilingüe que confirma el consentimiento y explica cómo revocarlo
   (eliminar la cuenta o escribir al correo de privacidad). Luego apaga la marca
   y registra `confirmationSentAt` y `confirmationVersion`.

Las reglas de Firestore impiden que el cliente escriba los campos de
confirmación. Aceptar una versión nueva de los documentos vuelve a encender la
marca, así que cada versión recibe su propio correo.

## Consecuencias

- Se introducen Cloud Functions en el proyecto. Requieren el plan Blaze, un
  proveedor SMTP y un secreto (`SMTP_PASSWORD`). El proveedor de correo se
  declara como encargado en el aviso de privacidad.
- Las cuentas existentes deben verificar su correo en el siguiente inicio de
  sesión y aceptar la versión 2 de los documentos.
- El correo de confirmación no menciona nombres de perfiles infantiles.
- Si el proyecto llegara a compartir datos de menores con terceros, "email plus"
  deja de bastar y habría que adoptar un método más fuerte (por ejemplo, una
  verificación con tarjeta o con identificación oficial).
