# Diagramas de telemetría — Appy

**Proyecto:** Appy · **Fecha:** Septiembre 2026

---

## 1. Qué registraba la app antes

El único dato que se guardaba al terminar una actividad era si el niño ganó
estrellas. No había forma de saber cómo llegó a ese resultado.

```mermaid
flowchart TD
    A[El niño elige\nuna actividad] --> B[Juega]
    B --> C{¿Completó?}
    C -->|Sí| D[Se guardan\nlas estrellas]
    C -->|No| E[No se guarda nada]

    style D fill:#1a3d52,color:#fff
    style E fill:#555,color:#fff
```

**Lo que no se podía medir:**
- Cuánto tiempo pasó el niño realmente jugando.
- Si salió antes de terminar, y por qué.
- Cuántos intentos le tomó llegar al resultado.
- Si repitió un video varias veces.

---

## 2. Qué registra la app ahora

Se añadió un servicio de telemetría que observa cada sesión de juego en
paralelo, sin modificar la experiencia del niño ni los minijuegos en sí.

```mermaid
flowchart TD
    A[El niño elige\nuna actividad] --> B[Juega]
    B --> C[Se guardan\nlas estrellas]
    B --> D[El servicio de telemetría\nregistra cómo jugó]

    C --> E[(Progreso\ndel niño)]
    D --> F[(Historial de\nsesiones)]

    style E fill:#1a3d52,color:#fff
    style F fill:#1a3d52,color:#fff
    style D fill:#174060,color:#fff
```

---

## 3. Qué guarda el servicio de telemetría

Cada vez que un niño juega, se crea un registro único que va tomando datos
a medida que avanza la actividad.

```mermaid
flowchart TD
    R[Registro\nde sesión] --> A[Qué actividad fue\ny a qué módulo pertenece]
    R --> B[Cuánto tiempo\nestuvo jugando activamente]
    R --> C[Cuántos intentos\nrealizó]
    R --> D[Si completó, abandonó\no no pudo iniciar]
    R --> E[Cuántas veces\nrepitió el video]
    R --> F[Desde qué dispositivo\ny versión de la app]

    style R fill:#174060,color:#fff
```

---

## 4. Ciclo de vida de una sesión

Cada sesión pasa por etapas bien definidas. Una vez que termina —de
cualquier forma— el registro queda cerrado y no puede modificarse.

```mermaid
flowchart TD
    A[El niño confirma\nque quiere jugar] --> B[La actividad\ncarga y arranca]
    A --> X[No pudo\niniciarse]

    B --> C[Completada]
    B --> D[Abandonada\nel niño salió antes]
    B --> E[Fallida\nagotó los intentos]

    C --> Z[Registro cerrado\nde forma permanente]
    D --> Z
    E --> Z
    X --> Z

    style C fill:#1a6640,color:#fff
    style D fill:#7a4800,color:#fff
    style E fill:#7a1a00,color:#fff
    style X fill:#555,color:#fff
    style Z fill:#1a3d52,color:#fff
```

---

## 5. Cómo se conecta la telemetría con los minijuegos

Los minijuegos no saben que existe la telemetría. Solo avisan tres momentos
clave; el servicio decide qué registrar en cada uno.

### 5a. Los tres momentos que avisa cualquier actividad

```mermaid
flowchart TD
    M1[La actividad\nestá lista para jugar] -->|arranca el cronómetro| S[Servicio\nde telemetría]
    M2[El niño alcanzó\nel objetivo] -->|detiene el cronómetro| S
    M3[La actividad\nterminó o fue abandonada] -->|cierra el registro| S

    S --> DB[(Historial\nguardado)]

    style S fill:#174060,color:#fff
    style DB fill:#1a3d52,color:#fff
```

### 5b. Qué avisa cada tipo de actividad

```mermaid
flowchart TD
    subgraph Interactivas["Actividades interactivas"]
        SS[Seleccion simple\nPreguntas de imagen]
        PZ[Rompecabezas]
    end

    subgraph Observacion["Actividades de observacion"]
        VI[Video]
        PI[Pictograma]
        AU[Audio]
    end

    SS --> I1[Cuando cargaron\nlas preguntas]
    SS --> I2[Al responder\nla ultima pregunta]
    SS --> I3[Numero total\nde intentos]

    PZ --> P1[Cuando cargo\nla imagen]
    PZ --> P2[Al colocar\nla ultima pieza]
    PZ --> P3[Numero de\nintentos]

    VI --> V1[Cuando el video\nesta listo]
    VI --> V2[Al llegar al 90%\ny tocar COMPLETAR]
    VI --> V3[Cuantas veces\nse repitio]

    PI --> O1[Cuando cargo\nla imagen]
    AU --> A1[Cuando cargo\nel audio]
```

---

## 6. Consentimiento y privacidad

El servicio de telemetría solo actúa si el tutor ha activado la opción en
ajustes. Nunca se guarda nombre, correo ni información personal.

```mermaid
flowchart TD
    T[El tutor activa\nEnviar metricas\nen Ajustes] --> ON[El servicio\ncomiienza a registrar]
    T2[El tutor desactiva\nEnviar metricas] --> OFF[El servicio deja\nde registrar\nHistorial previo se conserva]

    ON --> DB[(Historial de sesiones\nSolo IDs anonimos\nSin nombre ni correo)]

    style T fill:#1a6640,color:#fff
    style T2 fill:#7a4800,color:#fff
    style DB fill:#1a3d52,color:#fff
    style OFF fill:#555,color:#fff
```

---

## 7. Los 7 indicadores — Mediciones de uso (KPI 1 a 4)

Todas las respuestas se calculan consultando el historial de sesiones guardado,
dentro de un rango de fechas elegido por el dashboard.

```mermaid
flowchart TD
    DB[(Historial de\nsesiones)]

    DB --> K1[Tiempo promedio activo\npor actividad completada]
    DB --> K2[Promedio de veces\nque se repite un video]
    DB --> K3[Porcentaje de actividades\nque el nino abandono]
    DB --> K4[Porcentaje de actividades\ncompletadas sin salir\nen ningun momento]

    style DB fill:#1a3d52,color:#fff
```

---

## 8. Los 7 indicadores — Mediciones de uso (KPI 5 a 7)

```mermaid
flowchart TD
    DB[(Historial de\nsesiones)]
    PR[(Progreso\ndel modulo)]

    DB --> K5[Porcentaje de actividades\nque se terminaron\nincluye las interrumpidas]
    DB --> K6[Promedio de intentos\npara completar\nactividades interactivas]
    PR --> K7[Cuantos niveles del modulo\ncompleto el nino\ndel total disponible]

    style DB fill:#1a3d52,color:#fff
    style PR fill:#1a3d52,color:#fff
```

---

## 9. Resumen comparativo

| | Antes | Ahora |
|---|---|---|
| Datos guardados al jugar | Solo estrellas | Tiempo activo, intentos, estado, replays |
| Saber si el nino abandono | No | Si, con motivo |
| Medir tiempo real de juego | No | Si, solo el tiempo activo |
| Impacto en el nino | — | Ninguno, el servicio es invisible |
| Privacidad | — | Sin nombre, correo ni datos personales |
| Indicadores disponibles | 0 | 7 KPI consultables por rango de fecha |
