import '../model/avatar_models.dart';

/* 
REPOSITORIO DE DATOS PARA EL AVATAR
Proporciona las listas de skins, accesorios y backgrounds disponibles
Ya después, esto se podría cargar datos desde una API o base de datos
*/

class AvatarRepository {
  /* 
  Retorna todas las skins disponibles en el sistema
  */
  static List<SkinInfo>
  obtenerSkinsDisponibles() {
    return [
      // Skin Default (tiene expresiones)
      SkinInfo(
        nombre: 'Default',
        imagenBase:
            'assets/images/Skins/DefaultSkin/default.png',
        carpetaBackground:
            'assets/images/Skins/DefaultSkin/backgrounds/',
        expresiones: [
          'assets/images/Skins/DefaultSkin/expresions/CALMADO.png',
          'assets/images/Skins/DefaultSkin/expresions/curioso.png',
          'assets/images/Skins/DefaultSkin/expresions/emocionado.png',
          'assets/images/Skins/DefaultSkin/expresions/FELIZ.png',
          'assets/images/Skins/DefaultSkin/expresions/pensativo.png',
        ],
      ),

      // Skin Astronaut (tiene expresiones)
      SkinInfo(
        nombre: 'Astronaut',
        imagenBase:
            'assets/images/Skins/Astronaut/astronauta.png',
        carpetaBackground:
            'assets/images/Skins/Astronaut/backgrounds/',
        expresiones: [
          'assets/images/Skins/Astronaut/expresions/expastron.png',
          'assets/images/Skins/Astronaut/expresions/expastron2.png',
          'assets/images/Skins/Astronaut/expresions/expastron3.png',
        ],
      ),

      // Skin Chef (tiene expresiones)
      SkinInfo(
        nombre: 'Chef',
        imagenBase:
            'assets/images/Skins/Chef/chefskin.png',
        carpetaBackground:
            'assets/images/Skins/Chef/backgrounds/',
        expresiones: [
          'assets/images/Skins/Chef/expresions/expchef.png',
          'assets/images/Skins/Chef/expresions/expchef2.png',
          'assets/images/Skins/Chef/expresions/expchef3.png',
          'assets/images/Skins/Chef/expresions/expchef4.png',
        ],
      ),

      // Skin Dinosaur (sin expresiones)
      SkinInfo(
        nombre: 'Dinosaur',
        imagenBase:
            'assets/images/Skins/Dinosaur/dinosaurio.png',
        carpetaBackground:
            'assets/images/Skins/Dinosaur/backgrounds/',
        expresiones:
            null, // No tiene expresiones
      ),

      // Skin Firefighter (sin expresiones)
      SkinInfo(
        nombre: 'Firefighter',
        imagenBase:
            'assets/images/Skins/Firefighter/Bombero.png',
        carpetaBackground:
            'assets/images/Skins/Firefighter/backgrounds/',
        expresiones:
            null, // No tiene expresiones
      ),

      // Skin Superhero (sin expresiones)
      SkinInfo(
        nombre: 'Superhero',
        imagenBase:
            'assets/images/Skins/Superhero/Superheroe.png',
        carpetaBackground:
            'assets/images/Skins/Superhero/backgrounds/',
        expresiones:
            null, // No tiene expresiones
      ),
    ];
  }

  /* 
  Retorna todos los accesorios generales (los png's) disponibles con sus posiciones personalizadas
  Se puede ajustar top, left, width y height para cada accesorio individualmente
  */
  static List<AccesorioGeneral>
  obtenerAccesoriosGenerales() {
    return [
      AccesorioGeneral(
        nombre: 'Antenitas',
        imagenPath:
            'assets/images/Skins/accesorios generales/antenitas.png',
        top: -40,
        width: 250,
        height: 250,
        bloqueado:
            false, // Gratis desde el inicio
        costoMonedas: 0,
      ),
      AccesorioGeneral(
        nombre: 'Corona',
        imagenPath:
            'assets/images/Skins/accesorios generales/corona.png',
        top: -37,
        width: 280,
        height: 280,
        bloqueado:
            true, // Requiere desbloqueo
        costoMonedas: 50,
      ),
      AccesorioGeneral(
        nombre: 'Diadema Joyas',
        imagenPath:
            'assets/images/Skins/accesorios generales/diademajoyas.png',
        top: -15,
        width: 260,
        height: 260,
        bloqueado:
            true, // Requiere desbloqueo
        costoMonedas: 75,
      ),
      AccesorioGeneral(
        nombre: 'Gafas',
        imagenPath:
            'assets/images/Skins/accesorios generales/gafas.png',
        top: 55,
        width: 260,
        height: 260,
        bloqueado:
            false, // Gratis desde el inicio
        costoMonedas: 0,
      ),
      AccesorioGeneral(
        nombre: 'Halo Dorado',
        imagenPath:
            'assets/images/Skins/accesorios generales/halodorado.png',
        top: -40,
        width: 240,
        height: 240,
        bloqueado:
            true, // Requiere desbloqueo
        costoMonedas: 100,
      ),
    ];
  }

  /* 
  Retorna todos los backgrounds disponibles en el sistema
  */
  static List<String>
  obtenerBackgroundsDisponibles() {
    return [
      'assets/images/Skins/DefaultSkin/backgrounds/default.jpg',
      'assets/images/Skins/Astronaut/backgrounds/espacio.jpg',
      'assets/images/Skins/Astronaut/backgrounds/espacio2.jpg',
      'assets/images/Skins/Chef/backgrounds/cocina.jpg',
      'assets/images/Skins/Dinosaur/backgrounds/prehistoria.jpg',
      'assets/images/Skins/Dinosaur/backgrounds/prehistoria2.jpg',
      'assets/images/Skins/Firefighter/backgrounds/departamento_bomberos.jpg',
      'assets/images/Skins/Firefighter/backgrounds/departamento_bomberos2.jpg',
      'assets/images/Skins/Superhero/backgrounds/superbase.jpg',
      'assets/images/Skins/Superhero/backgrounds/superbase2.jpg',
    ];
  }
}
