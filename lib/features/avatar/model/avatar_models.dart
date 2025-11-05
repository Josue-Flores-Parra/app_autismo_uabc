/* 
MODELOS DE DATOS PARA EL SISTEMA DE AVATAR
*/

/* 
CLASE BASE PARA CADA SKIN TEMÁTICA
Cada skin tiene su imagen base, sus expresiones disponibles y su background
*/
class SkinInfo {
  final String
  nombre; // 'Default', 'Astronaut', 'Chef', etc.
  final String
  imagenBase; // Ruta a la imagen base (default.png, astronauta.png, etc.)
  final String
  carpetaBackground; // Ruta a la carpeta de backgrounds
  final List<String>?
  expresiones; // Lista de expresiones disponibles (puede ser null si no tiene)

  SkinInfo({
    required this.nombre,
    required this.imagenBase,
    required this.carpetaBackground,
    this.expresiones, // Opcional porque no todas las skins tienen expresiones
  });
}

/* 
CLASE PARA ACCESORIOS GENERALES
Estos se pueden superponer sobre cualquier skin con posición y tamaño personalizados
*/
class AccesorioGeneral {
  final String
  nombre; // 'Antenitas', 'Corona', 'Gafas', etc.
  final String
  imagenPath; // Ruta a la imagen del accesorio
  final double
  top; // Posición vertical (negativo = más arriba)
  final double?
  left; // Posición horizontal (null = centrado)
  final double
  width; // Ancho del accesorio
  final double
  height; // Alto del accesorio
  final bool
  bloqueado; // Si requiere desbloqueo
  final int
  costoMonedas; // Monedas necesarias para desbloquear

  AccesorioGeneral({
    required this.nombre,
    required this.imagenPath,
    this.top = -20, // Valor por defecto
    this.left, // null = centrado horizontalmente
    this.width =
        280, // Valor por defecto
    this.height =
        280, // Valor por defecto
    this.bloqueado =
        false, // Por defecto desbloqueado
    this.costoMonedas =
        0, // Sin costo por defecto
  });
}

/* 
CLASE PARA EL ESTADO COMPLETO DEL AVATAR
Guarda la apariencia visual Y las estadísticas del robot
*/
class AvatarEstado {
  final SkinInfo
  skinActual; // Skin base que está usando
  final String?
  expresionActual; // Expresión seleccionada (puede ser null)
  final AccesorioGeneral?
  accesorioActual; // Accesorio general seleccionado (puede ser null)
  final String
  backgroundActual; // Background actual
  final String
  nombre; // Nombre del robot (ej: "APPY")
  final int
  felicidad; // Nivel de felicidad (0-100)
  final int
  energia; // Nivel de energía (0-100)
  final int
  monedas; // Monedas del usuario para desbloquear accesorios
  final Set<String>
  accesoriosDesbloqueados; // IDs de accesorios desbloqueados

  AvatarEstado({
    required this.skinActual,
    this.expresionActual,
    this.accesorioActual,
    required this.backgroundActual,
    required this.nombre,
    required this.felicidad,
    required this.energia,
    this.monedas =
        100, // Monedas iniciales
    Set<String>?
    accesoriosDesbloqueados,
  }) : accesoriosDesbloqueados =
           accesoriosDesbloqueados ??
           {};

  /* 
  Método para copiar el estado con cambios.
  Útil para actualizar solo algunos campos sin recrear todo el objeto.
  */
  AvatarEstado copyWith({
    SkinInfo? skinActual,
    String? expresionActual,
    bool resetExpresion = false,
    AccesorioGeneral? accesorioActual,
    bool resetAccesorio = false,
    String? backgroundActual,
    String? nombre,
    int? felicidad,
    int? energia,
    int? monedas,
    Set<String>?
    accesoriosDesbloqueados,
  }) {
    return AvatarEstado(
      skinActual:
          skinActual ?? this.skinActual,
      expresionActual: resetExpresion
          ? null
          : (expresionActual ??
                this.expresionActual),
      accesorioActual: resetAccesorio
          ? null
          : (accesorioActual ??
                this.accesorioActual),
      backgroundActual:
          backgroundActual ??
          this.backgroundActual,
      nombre: nombre ?? this.nombre,
      felicidad:
          felicidad ?? this.felicidad,
      energia: energia ?? this.energia,
      monedas: monedas ?? this.monedas,
      accesoriosDesbloqueados:
          accesoriosDesbloqueados ??
          this.accesoriosDesbloqueados,
    );
  }
}
