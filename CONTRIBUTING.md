# Guía para Contribuir al Proyecto: App Autismo

¡Gracias por tu interés en contribuir a esta aplicación educativa para personas con autismo! Este documento describe cómo colaborar de manera efectiva y ordenada.

---

## Requisitos previos

Antes de empezar, asegúrate de tener:

- Cuenta en GitHub.
- Flutter instalado en tu equipo: https://docs.flutter.dev/get-started/install
- Editor de código recomendado: Visual Studio Code.
- Conocimientos básicos de Git y GitHub.

---

## ¿Cómo colaborar?

1. Revisa los [issues](https://github.com/TU_USUARIO/TU_REPO/issues) disponibles.
2. Comenta en el issue que quieres trabajar y espera asignación.
3. Crea una nueva rama desde `dev` con un nombre descriptivo. Ejemplo:

   ```
   git checkout dev
   git pull origin dev
   git checkout -b feat/login-ui
   ```

4. Trabaja en tus cambios localmente.
5. Haz commits claros siguiendo las convenciones (ver abajo).
6. Envía un Pull Request a la rama `dev`.
7. Espera revisión y comentarios del equipo.

---

## Issues y etiquetas

Usamos issues para planear y dar seguimiento a tareas. Por favor:

- Comenta en el issue antes de comenzar a trabajar.
- Respeta los siguientes tipos de etiquetas:

| Etiqueta           | Uso                                         |
|--------------------|----------------------------------------------|
| `feat`             | Nueva funcionalidad                         |
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

- `feat: agregar pantalla de login`
- `fix: corregir validación en formulario`
- `docs: actualizar README`
- `refactor: simplificar lógica de navegación`

Recomendación: no pases de 50 caracteres en el título del commit. Si necesitas más contexto, agrega una segunda línea como cuerpo del commit.

---

## Flujo de trabajo con ramas (branches)

- Siempre parte desde la rama `dev`, **nunca desde `main`**.
- Usa prefijos en el nombre de la rama:

  - `feat/` para nuevas funciones
  - `fix/` para corrección de errores
  - `docs/` para documentación
  - `chore/` para tareas generales o configuración

Ejemplo:

```
feat/login-form
fix/navbar-error
docs/estructura-proyecto
```

---

## Pull requests (PRs)

Cuando termines tu tarea:

1. Asegúrate de estar en tu rama.
2. Haz push de los cambios: `git push origin nombre-de-tu-rama`
3. Desde GitHub, crea un Pull Request **de tu rama hacia `dev`**.
4. El título del PR debe ser claro, por ejemplo: `feat: pantalla de configuración`
5. Espera revisión de tus compañeros o profesor antes de hacer merge.

---

## Contacto

Si tienes dudas o necesitas ayuda, contacta con el profesor responsable o crea un issue con la etiqueta `discussion`.

---

¡Gracias por colaborar en este proyecto con impacto social positivo!
