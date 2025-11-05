# Guía para Contribuir al Proyecto: App Autismo

¡Gracias por tu interés en contribuir a esta aplicación educativa para personas con autismo! Este documento describe cómo colaborar de manera efectiva y ordenada.

---

## Requisitos previos

Antes de empezar, asegúrate de tener:

- Cuenta en GitHub.
- Flutter instalado en tu equipo: https://docs.flutter.dev/get-started/install
- Editor de código recomendado: Android Studio ó Visual Studio Code.
- Conocimientos básicos de Git y GitHub.

---

## Arquitectura del Proyecto: MVVM

Para mantener el código organizado, escalable y fácil de probar, utilizamos la arquitectura **MVVM (Model-View-ViewModel)**. Cada pieza de código tiene una responsabilidad única.

### Los 4 Roles Principales

1.  **Model (`/data/models`):** Define la **estructura de nuestros datos**. Son clases simples de Dart que no contienen lógica, solo propiedades (ej. `UserModel` con `id`, `email`, `monedas`).
2.  **View (`/features/.../view`):** Es la **interfaz de usuario (UI)** que el usuario ve. Su único trabajo es mostrar el estado que le provee el ViewModel y notificarle las interacciones del usuario (como presionar un botón).
3.  **ViewModel (`/features/.../viewmodel`):** Es el **cerebro de la View**. Contiene toda la lógica de la UI (estados de carga, mensajes de error) y se comunica con los `Services` para obtener o guardar datos.
4.  **Service (`/data/services`):** Es el **único que habla con el mundo exterior** (Firebase, APIs, etc.). El ViewModel le pide al Service que realice las operaciones de datos.

### Estructura de Carpetas (Nuestro Mapa)

Todo el código debe organizarse según esta estructura:

```
lib/
├── core/                 # Configuración central (rutas, tema visual).
├── features/             # Cada funcionalidad de la app vive aquí en su propia carpeta.
│   └── authentication/
│       ├── view/         # Las pantallas (ej. login_screen.dart).
│       ├── viewmodel/    # La lógica de las pantallas (ej. auth_viewmodel.dart).
│       └── widgets/      # Widgets reutilizables solo para esta funcionalidad.
├── data/                 # La capa de acceso a datos.
│   ├── models/           # Las clases que definen nuestros datos.
│   └── services/         # Las clases que hablan con Firebase.
├── shared/               # Widgets y utilidades que se usan en MÚLTIPLES funcionalidades.
└── l10n/                 # Archivos para la traducción de la app.
```

---

## Modelo de Ramificación

Utilizamos un modelo simplificado de GitFlow con dos ramas principales: `main` (estable) y `develop` (desarrollo).

-   **Todo el trabajo nuevo parte de `develop` y vuelve a `develop` a través de un Pull Request.**
-   **Nomenclatura de Ramas:** `tipo/T<numero_issue>-descripcion-corta`
    -   *Ejemplos:* `feature/T5-ui-autenticacion`, `fix/T16-teclado-oculta-input`.

---

## Flujo de Trabajo

1.  **Sincroniza `develop`:** `git checkout develop` y `git pull origin develop`.
2.  **Crea tu rama de trabajo:** `git checkout -b feature/T5-ui-autenticacion`.
3.  **Programa y haz commits:** Usa **Commits Convencionales** para tus mensajes (ej. `feature(auth): añadir validación de email`).
    -   **Tipos comunes:** `feature`, `fix`, `docs`, `style`, `refactor`, `test`.
4.  **Sube tus cambios:** `git push origin feature/T5-ui-autenticacion`.
5.  **Abre un Pull Request (PR)** en GitHub desde tu rama hacia `develop`.
    -   En la descripción, enlaza el issue que resuelves con `Closes #5`.
6. Espera revisión y comentarios del equipo.

---

## Issues y etiquetas

Usamos issues para planear y dar seguimiento a tareas. Por favor:

- Comenta en el issue antes de comenzar a trabajar.
- Respeta los siguientes tipos de etiquetas:

| Etiqueta           | Uso                                         |
|--------------------|----------------------------------------------|
| `feature`          | Nueva funcionalidad                         |
| `bug`              | Reporte de errores o fallos                 |
| `docs`             | Documentación                               |
| `enhancement`      | Mejora de funcionalidades existentes        |
| `good first issue` | Ideal para nuevos colaboradores             |
| `in progress`      | Tarea que ya está siendo trabajada          |
| `help wanted`      | Se requiere apoyo de otros colaboradores    |
| `discussion`       | Tema abierto para análisis o decisiones     |

---

## Buenas prácticas para commits

Usamos convenciones para mantener un historial limpio. Ejemplos:

- `feature: agregar pantalla de login`
- `fix: corregir validación en formulario`
- `docs: actualizar README`
- `refactor: simplificar lógica de navegación`

Recomendación: no pases de 50 caracteres en el título del commit. Si necesitas más contexto, agrega una segunda línea como cuerpo del commit.

---

## Flujo de trabajo con ramas (branches)

- Siempre parte desde la rama `develop`, **nunca desde `main`**.
- Usa prefijos en el nombre de la rama, usando la nomenclatura `tipo/T<numero_issue>-descripcion-corta`
  
  - `feature/` para nuevas funciones
  - `fix/` para corrección de errores
  - `docs/` para documentación
  - `chore/` para tareas generales o configuración

Ejemplo:

```
   `feature/T5-ui-autenticacion`, `fix/T16-teclado-oculta-input`.
```

---

## Pull requests (PRs)

Cuando termines tu tarea:

1. Asegúrate de estar en tu rama.
2. Haz push de los cambios: `git push origin nombre-de-tu-rama`
3. Desde GitHub, crea un Pull Request **de tu rama hacia `develop`**.
4. El título del PR debe ser claro y seguir la nomenclatura antes mencionada.
5. Espera revisión de tus compañeros o profesor antes de hacer merge.
   
---

## Estilo de Código y Calidad

-   **Formato:** Antes de hacer commit, formatea tu código con `dart format .`.
-   **Linting:** Asegúrate de que no haya advertencias ni errores del linter (`analysis_options.yaml`).

---

## Contacto

Si tienes dudas o necesitas ayuda, contacta con el profesor responsable o crea un issue con la etiqueta `discussion`.

---

¡Gracias por colaborar en este proyecto con impacto social positivo!
