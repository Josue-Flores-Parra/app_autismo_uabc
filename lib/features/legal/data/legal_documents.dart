/*
Textos legales de Appy: terminos de uso y aviso de privacidad integral.

Viven en Dart y no en los archivos ARB porque son documentos largos y
versionados: lo que importa es poder comparar la version aceptada por cada
cuenta contra [kLegalVersion], no traducir cadena por cadena.

Al cambiar el contenido de forma sustancial hay que subir [kLegalVersion]. Eso
hace que la app vuelva a pedir la aceptacion a todas las cuentas, incluidas las
que ya habian aceptado una version anterior.
*/

/// Version vigente de los documentos legales.
/// Subir este numero obliga a aceptar de nuevo a todas las cuentas.
const int kLegalVersion = 1;

/// Fecha de la ultima actualizacion, visible para el usuario.
const String kLegalLastUpdated = '17 de septiembre de 2026';

/// Nombre con el que el equipo se identifica como responsable.
const String kLegalResponsable = 'el Equipo de Appy TEApoya TEAcompaña';

/// Correo unico de contacto para asuntos legales y de datos personales.
const String kLegalContactEmail = 'rosalesq.software@gmail.com';

/// Entidad federativa cuya legislacion rige el servicio.
const String kLegalJurisdiccion = 'Baja California, México';

enum LegalBlockType { heading, paragraph, bullet, note }

class LegalBlock {
  final LegalBlockType type;
  final String text;

  const LegalBlock.heading(this.text) : type = LegalBlockType.heading;
  const LegalBlock.paragraph(this.text) : type = LegalBlockType.paragraph;
  const LegalBlock.bullet(this.text) : type = LegalBlockType.bullet;
  const LegalBlock.note(this.text) : type = LegalBlockType.note;
}

class LegalDocument {
  final String title;
  final String shortTitle;
  final String lastUpdated;
  final List<LegalBlock> blocks;

  const LegalDocument({
    required this.title,
    required this.shortTitle,
    required this.lastUpdated,
    required this.blocks,
  });
}

/// Devuelve los terminos de uso en el idioma indicado.
LegalDocument termsOfUse(String languageCode) =>
    languageCode == 'en' ? _termsEn : _termsEs;

/// Devuelve el aviso de privacidad en el idioma indicado.
LegalDocument privacyNotice(String languageCode) =>
    languageCode == 'en' ? _privacyEn : _privacyEs;

// ─────────────────────────────────────────────────────────────────────────────
// Terminos de Uso (español)
// ─────────────────────────────────────────────────────────────────────────────

const LegalDocument _termsEs = LegalDocument(
  title: 'Términos y Condiciones de Uso',
  shortTitle: 'Términos y Condiciones',
  lastUpdated: kLegalLastUpdated,
  blocks: [
    LegalBlock.paragraph(
      'Los presentes Términos y Condiciones de Uso (en adelante, los "Términos") '
      'regulan el acceso y uso de la aplicación móvil Appy TEApoya TEAcompaña '
      '(en adelante, la "Aplicación"), puesta a disposición del público por '
      '$kLegalResponsable (en adelante, el "Titular"). Le solicitamos leerlos '
      'íntegramente antes de crear una cuenta.',
    ),

    LegalBlock.heading('1. Definiciones'),
    LegalBlock.paragraph(
      'Para efectos de los presentes Términos se entenderá por:',
    ),
    LegalBlock.bullet(
      '"Aplicación": el programa de cómputo denominado Appy TEApoya TEAcompaña, '
      'incluyendo su código, interfaces, contenidos audiovisuales, pictogramas, '
      'bases de datos y cualquier actualización o versión posterior.',
    ),
    LegalBlock.bullet(
      '"Usuario Titular": la persona mayor de edad que crea, administra y es '
      'responsable de una cuenta en la Aplicación.',
    ),
    LegalBlock.bullet(
      '"Usuario Asistido": la persona menor de edad o bajo tutela que utiliza la '
      'Aplicación bajo la supervisión del Usuario Titular.',
    ),
    LegalBlock.bullet(
      '"Contenido": la totalidad de videos, ilustraciones, pictogramas, '
      'locuciones, textos, marcas, diseños y elementos gráficos incorporados a '
      'la Aplicación.',
    ),
    LegalBlock.bullet(
      '"Cuenta": el registro individual asociado a una dirección de correo '
      'electrónico mediante el cual se accede a la Aplicación.',
    ),

    LegalBlock.heading('2. Objeto'),
    LegalBlock.paragraph(
      '2.1. La Aplicación tiene por objeto ofrecer material educativo de apoyo '
      'para el aprendizaje y la práctica de habilidades de la vida diaria, '
      'dirigido preferentemente a personas con Trastorno del Espectro Autista, '
      'mediante contenidos audiovisuales y actividades interactivas.',
    ),
    LegalBlock.paragraph(
      '2.2. El Titular es un equipo independiente sin fines de lucro. La '
      'Aplicación se ofrece de forma gratuita, no contiene publicidad, no '
      'comercializa bienes o servicios y no genera ingresos derivados de su uso.',
    ),

    LegalBlock.heading(
      '3. Naturaleza del servicio y ausencia de finalidad médica',
    ),
    LegalBlock.note(
      'La Aplicación no constituye un dispositivo médico, no realiza '
      'diagnósticos, no emite valoraciones clínicas y no sustituye la '
      'intervención de profesionales de la salud, de la psicología, de la '
      'terapia ocupacional, del lenguaje o de la educación especial.',
    ),
    LegalBlock.paragraph(
      '3.1. El Contenido tiene naturaleza estrictamente educativa y de práctica '
      'complementaria. Su uso no implica relación terapéutica alguna entre el '
      'Titular y el Usuario.',
    ),
    LegalBlock.paragraph(
      '3.2. La información sobre avance, estrellas, niveles o cualquier métrica '
      'mostrada por la Aplicación constituye únicamente un registro de '
      'actividad dentro del programa y no debe interpretarse como indicador '
      'clínico, evaluación de desarrollo ni evidencia de progreso terapéutico.',
    ),
    LegalBlock.paragraph(
      '3.3. El Usuario Titular reconoce que ninguna decisión médica, '
      'terapéutica, educativa o de cualquier otra índole relativa al Usuario '
      'Asistido debe adoptarse con fundamento exclusivo en la Aplicación, y se '
      'obliga a consultar a los profesionales correspondientes.',
    ),

    LegalBlock.heading('4. Capacidad legal y aceptación'),
    LegalBlock.paragraph(
      '4.1. Para crear una Cuenta se requiere ser mayor de edad y contar con '
      'plena capacidad legal para obligarse conforme a la legislación mexicana.',
    ),
    LegalBlock.paragraph(
      '4.2. Al marcar la casilla de aceptación y continuar, el Usuario Titular '
      'manifiesta bajo protesta de decir verdad que: (i) es mayor de edad; (ii) '
      'es madre, padre, tutor legal o persona legalmente facultada respecto del '
      'Usuario Asistido; (iii) ha leído íntegramente estos Términos y el Aviso '
      'de Privacidad; y (iv) otorga su consentimiento expreso para el '
      'tratamiento de datos personales en los términos ahí descritos.',
    ),
    LegalBlock.paragraph(
      '4.3. La aceptación se registra de forma electrónica, haciendo constar la '
      'versión aceptada y la fecha correspondiente, y produce los efectos '
      'jurídicos previstos en la legislación aplicable en materia de mensajes '
      'de datos.',
    ),
    LegalBlock.paragraph(
      '4.4. Si el Usuario no acepta los presentes Términos, deberá abstenerse '
      'de utilizar la Aplicación.',
    ),

    LegalBlock.heading('5. Cuenta de usuario y credenciales'),
    LegalBlock.paragraph(
      '5.1. El registro requiere una dirección de correo electrónico válida y '
      'una contraseña. El Usuario Titular es el único responsable de la '
      'veracidad de los datos proporcionados.',
    ),
    LegalBlock.paragraph(
      '5.2. Las credenciales de acceso son personales e intransferibles. El '
      'Usuario Titular se obliga a mantenerlas bajo estricta confidencialidad y '
      'responde de todas las operaciones realizadas mediante su Cuenta.',
    ),
    LegalBlock.paragraph(
      '5.3. La Aplicación incorpora un código de acceso parental (PIN) que '
      'restringe el ingreso a la pantalla de ajustes. Dicho PIN se almacena '
      'localmente en el dispositivo y queda vinculado a la Cuenta. El Usuario '
      'Titular es responsable de elegir un PIN que no resulte previsible para '
      'el Usuario Asistido y de resguardarlo.',
    ),
    LegalBlock.paragraph(
      '5.4. El Usuario Titular deberá notificar de inmediato al Titular, al '
      'correo $kLegalContactEmail, cualquier uso no autorizado de su Cuenta.',
    ),
    LegalBlock.paragraph(
      '5.5. El Titular no solicita ni almacena la contraseña en texto legible. '
      'Su resguardo se realiza mediante el servicio de autenticación descrito '
      'en el Aviso de Privacidad.',
    ),

    LegalBlock.heading('6. Supervisión del Usuario Asistido'),
    LegalBlock.paragraph(
      '6.1. La Aplicación está diseñada para utilizarse bajo la supervisión de '
      'una persona adulta. El Usuario Titular asume la responsabilidad de '
      'determinar la idoneidad del Contenido para el Usuario Asistido, '
      'atendiendo a su edad, características y recomendaciones profesionales.',
    ),
    LegalBlock.paragraph(
      '6.2. El Usuario Titular es responsable del tiempo de exposición a '
      'pantallas, del entorno físico en que se utiliza la Aplicación y de la '
      'supervisión durante la realización de las actividades sugeridas, '
      'particularmente aquellas que involucren objetos del hogar, alimentos, '
      'higiene personal o interacción social.',
    ),

    LegalBlock.heading('7. Licencia de uso'),
    LegalBlock.paragraph(
      '7.1. El Titular concede al Usuario una licencia limitada, personal, '
      'revocable, intransferible, no exclusiva y no sublicenciable para instalar '
      'y utilizar la Aplicación con fines exclusivamente personales, educativos '
      'y no comerciales.',
    ),
    LegalBlock.paragraph(
      '7.2. Esta licencia no constituye transmisión de propiedad ni cesión de '
      'derecho alguno sobre la Aplicación o el Contenido.',
    ),

    LegalBlock.heading('8. Conductas prohibidas'),
    LegalBlock.paragraph('Queda expresamente prohibido al Usuario:'),
    LegalBlock.bullet(
      'Utilizar la Aplicación con fines distintos a los previstos en la cláusula '
      '2, o de forma contraria a la ley, la moral o el orden público.',
    ),
    LegalBlock.bullet(
      'Descompilar, desensamblar, aplicar ingeniería inversa, modificar o crear '
      'obras derivadas de la Aplicación, salvo en los supuestos expresamente '
      'permitidos por la legislación aplicable.',
    ),
    LegalBlock.bullet(
      'Acceder o intentar acceder a cuentas, datos, sistemas o áreas de la '
      'infraestructura que no le correspondan.',
    ),
    LegalBlock.bullet(
      'Interferir, sobrecargar o vulnerar la seguridad, integridad o '
      'disponibilidad de la Aplicación o de los servicios de terceros que la '
      'soportan.',
    ),
    LegalBlock.bullet(
      'Extraer, reproducir, distribuir, comunicar públicamente o transformar el '
      'Contenido, total o parcialmente, con fines comerciales o sin '
      'autorización escrita del Titular.',
    ),
    LegalBlock.bullet(
      'Emplear medios automatizados para acceder al servicio, manipular el '
      'sistema de recompensas o alterar los registros de progreso.',
    ),
    LegalBlock.bullet(
      'Suplantar la identidad de terceros o proporcionar información falsa al '
      'momento del registro.',
    ),

    LegalBlock.heading('9. Propiedad intelectual'),
    LegalBlock.paragraph(
      '9.1. La Aplicación y la totalidad del Contenido, incluidos sin limitación '
      'los videos animados, los pictogramas, las locuciones, el diseño del '
      'personaje, las interfaces, el código fuente y las bases de datos, son '
      'titularidad del Titular o de sus respectivos autores, y se encuentran '
      'protegidos por la Ley Federal del Derecho de Autor, la Ley Federal de '
      'Protección a la Propiedad Industrial y los tratados internacionales '
      'aplicables.',
    ),
    LegalBlock.paragraph(
      '9.2. Ninguna disposición de estos Términos podrá interpretarse como una '
      'cesión, licencia o autorización de uso de marcas, avisos comerciales, '
      'nombres o signos distintivos del Titular.',
    ),
    LegalBlock.paragraph(
      '9.3. El Usuario que considere que algún Contenido vulnera derechos de '
      'propiedad intelectual podrá notificarlo al correo $kLegalContactEmail, '
      'acompañando los elementos que acrediten su titularidad, a efecto de que '
      'el Titular realice la valoración y, en su caso, el retiro correspondiente.',
    ),

    LegalBlock.heading('10. Elementos virtuales'),
    LegalBlock.paragraph(
      '10.1. La Aplicación otorga monedas virtuales como incentivo por la '
      'realización de actividades. Dichas monedas únicamente permiten '
      'desbloquear elementos decorativos del avatar dentro de la Aplicación.',
    ),
    LegalBlock.paragraph(
      '10.2. Las monedas virtuales carecen de valor monetario, no constituyen '
      'moneda de curso legal, título de crédito ni instrumento de pago, no son '
      'adquiribles con dinero real, no son transferibles entre cuentas y no son '
      'canjeables, reembolsables ni indemnizables bajo ninguna circunstancia, '
      'incluida la terminación de la Cuenta.',
    ),
    LegalBlock.paragraph(
      '10.3. El Titular se reserva el derecho de ajustar las reglas de '
      'obtención, el costo de los elementos y los saldos, cuando ello resulte '
      'necesario para corregir errores, prevenir abusos o rediseñar la '
      'experiencia educativa.',
    ),

    LegalBlock.heading('11. Disponibilidad y modificaciones del servicio'),
    LegalBlock.paragraph(
      '11.1. La Aplicación se proporciona en la medida en que se encuentre '
      'disponible. El Titular no garantiza la prestación ininterrumpida, '
      'oportuna, segura o libre de errores.',
    ),
    LegalBlock.paragraph(
      '11.2. Por tratarse de un proyecto sin fines de lucro sostenido por un '
      'equipo reducido, podrán presentarse interrupciones, fallas, periodos sin '
      'actualización, modificaciones de funcionalidades o la descontinuación '
      'total o parcial del servicio.',
    ),
    LegalBlock.paragraph(
      '11.3. El Titular podrá modificar, suspender o dar por terminada la '
      'Aplicación, en todo o en parte, sin responsabilidad, procurando avisar '
      'con la anticipación razonable que las circunstancias permitan.',
    ),
    LegalBlock.paragraph(
      '11.4. El acceso requiere conexión a internet y un dispositivo compatible. '
      'Los costos de datos, equipo y energía corren por cuenta del Usuario.',
    ),

    LegalBlock.heading('12. Servicios de terceros'),
    LegalBlock.paragraph(
      '12.1. La Aplicación se apoya en servicios de infraestructura de terceros, '
      'particularmente los servicios de Google Firebase, descritos en el Aviso '
      'de Privacidad.',
    ),
    LegalBlock.paragraph(
      '12.2. El Titular no controla dichos servicios y no responde por sus '
      'interrupciones, fallas, cambios en sus condiciones ni por los actos u '
      'omisiones de sus proveedores, sin perjuicio de las obligaciones que '
      'corresponden al Titular en su carácter de responsable del tratamiento de '
      'datos personales.',
    ),

    LegalBlock.heading('13. Exclusión de garantías'),
    LegalBlock.paragraph(
      '13.1. En la máxima medida permitida por la legislación aplicable, la '
      'Aplicación y el Contenido se proporcionan "tal cual" y "según '
      'disponibilidad", sin garantías de ninguna naturaleza, ya sean expresas o '
      'implícitas.',
    ),
    LegalBlock.paragraph(
      '13.2. El Titular no garantiza que el Contenido sea apropiado para un '
      'caso particular, que produzca un resultado educativo determinado, que '
      'esté libre de errores u omisiones, ni que la Aplicación sea compatible '
      'con todos los dispositivos o versiones de sistema operativo.',
    ),
    LegalBlock.paragraph(
      '13.3. Las exclusiones previstas en esta cláusula no aplicarán respecto de '
      'aquellas garantías que, conforme a la legislación de protección al '
      'consumidor, no puedan ser válidamente excluidas.',
    ),

    LegalBlock.heading('14. Limitación de responsabilidad'),
    LegalBlock.paragraph(
      '14.1. En la máxima medida permitida por la ley, el Titular, sus '
      'integrantes y colaboradores no serán responsables por daños indirectos, '
      'incidentales, especiales, punitivos o consecuenciales, ni por pérdida de '
      'datos, de oportunidad o de beneficios, derivados del uso o de la '
      'imposibilidad de uso de la Aplicación.',
    ),
    LegalBlock.paragraph(
      '14.2. El Titular no será responsable por los daños que deriven de: (i) '
      'decisiones médicas, terapéuticas o educativas adoptadas con base en la '
      'Aplicación; (ii) la falta de supervisión del Usuario Asistido; (iii) el '
      'uso de las credenciales por terceros no autorizados; (iv) fallas de '
      'conectividad, del dispositivo o de servicios de terceros; o (v) caso '
      'fortuito o fuerza mayor.',
    ),
    LegalBlock.paragraph(
      '14.3. Tratándose de un servicio gratuito, y en la medida en que la ley lo '
      'permita, la responsabilidad total del Titular frente al Usuario se '
      'limitará a la reparación del daño directo efectivamente acreditado.',
    ),
    LegalBlock.paragraph(
      '14.4. Ninguna disposición de estos Términos excluye o limita la '
      'responsabilidad del Titular por dolo, mala fe o por aquellos supuestos '
      'que la legislación aplicable declare irrenunciables.',
    ),

    LegalBlock.heading('15. Indemnización'),
    LegalBlock.paragraph(
      'El Usuario Titular se obliga a sacar en paz y a salvo al Titular, sus '
      'integrantes y colaboradores, respecto de cualquier reclamación, demanda, '
      'procedimiento, sanción, daño o gasto, incluidos honorarios legales '
      'razonables, que derive del incumplimiento de estos Términos, del uso '
      'indebido de la Aplicación o de la infracción de derechos de terceros que '
      'le sea imputable.',
    ),

    LegalBlock.heading('16. Suspensión y terminación'),
    LegalBlock.paragraph(
      '16.1. El Usuario Titular podrá dar por terminada la relación en '
      'cualquier momento, dejando de utilizar la Aplicación y eliminando su '
      'Cuenta desde la sección "Cuenta y seguridad" de la pantalla de ajustes.',
    ),
    LegalBlock.paragraph(
      '16.2. El Titular podrá suspender o cancelar una Cuenta, previa '
      'notificación cuando ello sea posible, en caso de incumplimiento de estos '
      'Términos, uso que comprometa la seguridad del servicio o riesgo para '
      'otras personas usuarias.',
    ),
    LegalBlock.paragraph(
      '16.3. La terminación implica la pérdida del acceso al progreso, a la '
      'personalización y a las monedas virtuales asociadas a la Cuenta, sin '
      'derecho a compensación.',
    ),

    LegalBlock.heading('17. Protección de datos personales'),
    LegalBlock.paragraph(
      'El tratamiento de datos personales se rige por el Aviso de Privacidad, '
      'que forma parte integrante de estos Términos y puede consultarse en todo '
      'momento desde la pantalla de ajustes, sección "Información y soporte".',
    ),

    LegalBlock.heading('18. Modificaciones a los Términos'),
    LegalBlock.paragraph(
      '18.1. El Titular podrá modificar estos Términos para adecuarlos a cambios '
      'legales, técnicos o funcionales.',
    ),
    LegalBlock.paragraph(
      '18.2. Cuando la modificación sea sustancial, la Aplicación mostrará la '
      'nueva versión y solicitará su aceptación antes de permitir la '
      'continuación del uso. La negativa a aceptar la nueva versión faculta al '
      'Usuario a dejar de usar la Aplicación y a eliminar su Cuenta.',
    ),
    LegalBlock.paragraph(
      '18.3. La versión vigente estará siempre disponible dentro de la '
      'Aplicación.',
    ),

    LegalBlock.heading('19. Divisibilidad'),
    LegalBlock.paragraph(
      'Si alguna disposición de estos Términos fuere declarada nula, ilegal o '
      'inexigible por autoridad competente, dicha disposición se tendrá por no '
      'puesta y las restantes conservarán plena validez y exigibilidad.',
    ),

    LegalBlock.heading('20. Cesión'),
    LegalBlock.paragraph(
      'El Usuario no podrá ceder los derechos y obligaciones derivados de estos '
      'Términos. El Titular podrá cederlos en caso de reorganización del '
      'proyecto, previa notificación a través de la Aplicación.',
    ),

    LegalBlock.heading('21. Ausencia de renuncia'),
    LegalBlock.paragraph(
      'La falta de ejercicio o el ejercicio tardío de cualquier derecho previsto '
      'en estos Términos no constituirá renuncia al mismo.',
    ),

    LegalBlock.heading('22. Acuerdo íntegro'),
    LegalBlock.paragraph(
      'Estos Términos, junto con el Aviso de Privacidad, constituyen el acuerdo '
      'íntegro entre las partes respecto del uso de la Aplicación y dejan sin '
      'efecto cualquier comunicación o acuerdo previo sobre la misma materia.',
    ),

    LegalBlock.heading('23. Legislación aplicable y jurisdicción'),
    LegalBlock.paragraph(
      '23.1. Estos Términos se rigen por la legislación de los Estados Unidos '
      'Mexicanos.',
    ),
    LegalBlock.paragraph(
      '23.2. Para la interpretación y cumplimiento de estos Términos, las partes '
      'se someten a la jurisdicción de los tribunales competentes de '
      '$kLegalJurisdiccion, renunciando a cualquier otro fuero que pudiera '
      'corresponderles, sin perjuicio de la competencia que la Procuraduría '
      'Federal del Consumidor tenga en materia de protección al consumidor.',
    ),

    LegalBlock.heading('24. Contacto'),
    LegalBlock.paragraph(
      'Para dudas, aclaraciones o notificaciones relacionadas con estos '
      'Términos, el Usuario podrá dirigirse al correo electrónico '
      '$kLegalContactEmail.',
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Aviso de Privacidad (español)
// ─────────────────────────────────────────────────────────────────────────────

const LegalDocument _privacyEs = LegalDocument(
  title: 'Aviso de Privacidad Integral',
  shortTitle: 'Aviso de Privacidad',
  lastUpdated: kLegalLastUpdated,
  blocks: [
    LegalBlock.paragraph(
      'El presente Aviso de Privacidad se emite en cumplimiento de la Ley '
      'Federal de Protección de Datos Personales en Posesión de los '
      'Particulares, su Reglamento y los Lineamientos del Aviso de Privacidad.',
    ),

    LegalBlock.heading('1. Responsable del tratamiento'),
    LegalBlock.paragraph(
      '$kLegalResponsable, equipo independiente sin fines de lucro con '
      'operación en $kLegalJurisdiccion, es responsable del tratamiento de los '
      'datos personales que se recaban a través de la aplicación móvil Appy '
      'TEApoya TEAcompaña.',
    ),
    LegalBlock.paragraph(
      'Domicilio para oír y recibir notificaciones en materia de datos '
      'personales: correo electrónico $kLegalContactEmail.',
    ),

    LegalBlock.heading('2. Datos personales sometidos a tratamiento'),
    LegalBlock.paragraph(
      'Se recaban únicamente los datos necesarios para la prestación del '
      'servicio. La relación es la siguiente:',
    ),
    LegalBlock.bullet(
      'Datos de identificación y contacto: nombre para mostrar y dirección de '
      'correo electrónico.',
    ),
    LegalBlock.bullet(
      'Datos de autenticación: contraseña, resguardada de forma cifrada por el '
      'proveedor de autenticación. El Responsable no tiene acceso a ella en '
      'texto legible.',
    ),
    LegalBlock.bullet(
      'Datos de registro de la cuenta: fecha de creación y, en su caso, fecha de '
      'solicitud de eliminación.',
    ),
    LegalBlock.bullet(
      'Datos de actividad educativa: módulos y pasos completados, estrellas '
      'obtenidas, modalidades finalizadas, número de respuestas incorrectas y '
      'fechas de cada avance.',
    ),
    LegalBlock.bullet(
      'Datos de personalización: nombre asignado al personaje, apariencia '
      'seleccionada, fondo, accesorios desbloqueados, monedas virtuales y '
      'niveles de felicidad y energía del avatar.',
    ),
    LegalBlock.bullet(
      'Constancia de consentimiento: versión aceptada de los documentos legales '
      'y fecha de aceptación.',
    ),
    LegalBlock.paragraph(
      'No se recaban datos patrimoniales o financieros, datos biométricos, '
      'geolocalización, imágenes, audio del usuario, contactos, ni información '
      'contenida en los archivos del dispositivo.',
    ),

    LegalBlock.heading('3. Datos personales sensibles'),
    LegalBlock.note(
      'La Aplicación está orientada al apoyo de personas con Trastorno del '
      'Espectro Autista. En consecuencia, el solo uso del servicio puede '
      'revelar información relativa al estado de salud del Usuario Asistido, '
      'la cual constituye dato personal sensible conforme al artículo 3, '
      'fracción VI, de la Ley.',
    ),
    LegalBlock.paragraph(
      '3.1. Por lo anterior, y con fundamento en el artículo 9 de la Ley, el '
      'tratamiento requiere el consentimiento expreso del titular o de quien '
      'ejerza la patria potestad o tutela, el cual se recaba mediante la '
      'aceptación electrónica de este Aviso.',
    ),
    LegalBlock.paragraph(
      '3.2. El Responsable no solicita diagnóstico, expediente clínico, nombre '
      'del profesional tratante ni ningún otro dato de salud adicional, y se '
      'obliga a limitar el tratamiento de esta categoría de datos a las '
      'finalidades estrictamente necesarias señaladas en el numeral 5.',
    ),

    LegalBlock.heading('4. Datos de personas menores de edad'),
    LegalBlock.paragraph(
      '4.1. La cuenta es creada y administrada exclusivamente por una persona '
      'mayor de edad que ejerce la patria potestad, la tutela o la '
      'representación legal del Usuario Asistido.',
    ),
    LegalBlock.paragraph(
      '4.2. El consentimiento para el tratamiento de los datos del Usuario '
      'Asistido es otorgado por dicha persona adulta, en su carácter de '
      'representante legal, conforme al principio del interés superior de la '
      'niñez.',
    ),
    LegalBlock.paragraph(
      '4.3. La Aplicación no genera perfiles públicos, no permite comunicación '
      'entre personas usuarias y no expone información del Usuario Asistido a '
      'terceros.',
    ),

    LegalBlock.heading('5. Finalidades primarias'),
    LegalBlock.paragraph(
      'Los datos se tratan para las siguientes finalidades necesarias y que dan '
      'origen a la relación con el Responsable:',
    ),
    LegalBlock.bullet(
      'Crear, identificar, autenticar y administrar la cuenta de usuario.',
    ),
    LegalBlock.bullet(
      'Conservar y sincronizar el avance educativo entre dispositivos, así como '
      'determinar el contenido disponible en cada momento.',
    ),
    LegalBlock.bullet(
      'Conservar la personalización del avatar y el saldo de monedas virtuales.',
    ),
    LegalBlock.bullet(
      'Acreditar el otorgamiento del consentimiento y la versión de los '
      'documentos legales aceptada.',
    ),
    LegalBlock.bullet(
      'Atender solicitudes de soporte y el ejercicio de derechos ARCO.',
    ),
    LegalBlock.bullet(
      'Dar cumplimiento a obligaciones legales y atender requerimientos de '
      'autoridad competente.',
    ),

    LegalBlock.heading('6. Finalidades secundarias'),
    LegalBlock.paragraph(
      'Las siguientes finalidades no son necesarias para la prestación del '
      'servicio y pueden deshabilitarse en cualquier momento desde la pantalla '
      'de ajustes, sección "Privacidad y datos":',
    ),
    LegalBlock.bullet(
      'Generación de métricas de uso disociadas, con el objeto de evaluar la '
      'pertinencia del contenido educativo y mejorar la Aplicación. Esta opción '
      'se encuentra desactivada de forma predeterminada.',
    ),
    LegalBlock.paragraph(
      'La negativa a estas finalidades no será motivo para negar el servicio.',
    ),

    LegalBlock.heading('7. Limitación de uso y divulgación'),
    LegalBlock.paragraph('El Responsable manifiesta que:'),
    LegalBlock.bullet(
      'No comercializa, vende, renta ni cede datos personales.',
    ),
    LegalBlock.bullet(
      'No realiza tratamiento con fines mercadotécnicos, publicitarios o de prospección comercial.',
    ),
    LegalBlock.bullet(
      'No incorpora publicidad ni tecnologías de seguimiento de terceros con fines comerciales.',
    ),
    LegalBlock.bullet(
      'No elabora perfiles con fines distintos a los descritos en el numeral 5.',
    ),

    LegalBlock.heading('8. Encargados y transferencias'),
    LegalBlock.paragraph(
      '8.1. Para la prestación del servicio, el Responsable utiliza la '
      'infraestructura de Google Firebase, provista por Google LLC y sus '
      'filiales, en calidad de encargado del tratamiento, para los servicios de '
      'autenticación, base de datos y almacenamiento de contenido.',
    ),
    LegalBlock.paragraph(
      '8.2. Dicho tratamiento implica la remisión de datos a servidores que '
      'pueden ubicarse fuera del territorio nacional. El encargado se encuentra '
      'obligado contractualmente a tratar los datos únicamente conforme a las '
      'instrucciones del Responsable y a mantener medidas de seguridad '
      'equivalentes.',
    ),
    LegalBlock.paragraph(
      '8.3. Fuera del supuesto anterior, no se realizan transferencias de datos '
      'personales a terceros, salvo aquellas previstas en el artículo 37 de la '
      'Ley, entre ellas las requeridas por autoridad competente mediante '
      'resolución fundada y motivada.',
    ),

    LegalBlock.heading('9. Datos que no salen del dispositivo'),
    LegalBlock.paragraph(
      'Las siguientes configuraciones se almacenan localmente y no son '
      'transmitidas al Responsable ni a terceros:',
    ),
    LegalBlock.bullet('Tema visual, tamaño de fuente e idioma.'),
    LegalBlock.bullet(
      'Preferencias de accesibilidad: alto contraste, reducción de animaciones, '
      'retroalimentación auditiva y háptica.',
    ),
    LegalBlock.bullet('Recordatorios de práctica y horario configurado.'),
    LegalBlock.bullet('Configuración del control parental.'),
    LegalBlock.bullet(
      'Código de acceso parental (PIN), el cual se elimina al borrar la cuenta.',
    ),

    LegalBlock.heading('10. Plazo de conservación'),
    LegalBlock.paragraph(
      '10.1. Los datos se conservan mientras subsista la cuenta y la relación '
      'con el Responsable.',
    ),
    LegalBlock.paragraph(
      '10.2. Solicitada la eliminación de la cuenta, se cancela el acceso, se '
      'suprimen los datos almacenados localmente en el dispositivo y se marca el '
      'registro para su eliminación, conservándose únicamente aquella '
      'información cuya guarda resulte obligatoria por disposición legal o '
      'necesaria para la atención de responsabilidades derivadas del '
      'tratamiento, durante los plazos legales aplicables.',
    ),

    LegalBlock.heading('11. Medidas de seguridad'),
    LegalBlock.paragraph(
      '11.1. El Responsable ha implementado medidas de seguridad administrativas '
      'y técnicas orientadas a proteger los datos personales contra daño, '
      'pérdida, alteración, destrucción, uso, acceso o tratamiento no '
      'autorizados, entre ellas el cifrado de contraseñas, la autenticación por '
      'cuenta y la restricción de acceso a la base de datos mediante reglas de '
      'seguridad.',
    ),
    LegalBlock.paragraph(
      '11.2. No obstante lo anterior, ningún sistema es invulnerable. El Usuario '
      'Titular contribuye a la seguridad utilizando una contraseña robusta, no '
      'compartiéndola y manteniendo actualizado su dispositivo.',
    ),
    LegalBlock.paragraph(
      '11.3. En caso de vulneración de seguridad que afecte de forma '
      'significativa los derechos patrimoniales o morales de los titulares, el '
      'Responsable lo informará sin dilación a través de la Aplicación o del '
      'correo registrado, a fin de que puedan tomarse las medidas '
      'correspondientes.',
    ),

    LegalBlock.heading('12. Derechos ARCO'),
    LegalBlock.paragraph(
      '12.1. El titular de los datos, o su representante legal, tiene derecho a '
      'conocer qué datos personales se poseen y para qué se utilizan (Acceso), a '
      'solicitar su corrección cuando sean inexactos o incompletos '
      '(Rectificación), a solicitar su eliminación cuando considere que no se '
      'requieren para las finalidades señaladas (Cancelación) y a oponerse al '
      'uso de sus datos para fines específicos (Oposición).',
    ),
    LegalBlock.paragraph(
      '12.2. La solicitud deberá enviarse al correo $kLegalContactEmail e '
      'incluir: (i) nombre del titular y medio para comunicar la respuesta; '
      '(ii) documento que acredite la identidad o, en su caso, la '
      'representación legal; (iii) descripción clara de los datos respecto de '
      'los cuales se ejerce el derecho; y (iv) cualquier elemento que facilite '
      'la localización de los datos.',
    ),
    LegalBlock.paragraph(
      '12.3. El Responsable comunicará la determinación adoptada en un plazo '
      'máximo de veinte días hábiles contados a partir de la recepción de la '
      'solicitud, y la hará efectiva dentro de los quince días hábiles '
      'siguientes. Los plazos podrán ampliarse una sola vez por un periodo '
      'igual cuando las circunstancias lo justifiquen.',
    ),
    LegalBlock.paragraph(
      '12.4. El ejercicio de estos derechos es gratuito, sin perjuicio de los '
      'gastos de reproducción o envío que en su caso procedan.',
    ),

    LegalBlock.heading('13. Revocación del consentimiento'),
    LegalBlock.paragraph(
      '13.1. El consentimiento puede revocarse en cualquier momento, sin efectos '
      'retroactivos, mediante la eliminación de la cuenta desde la pantalla de '
      'ajustes o mediante solicitud enviada al correo $kLegalContactEmail.',
    ),
    LegalBlock.paragraph(
      '13.2. La revocación del consentimiento respecto de las finalidades '
      'primarias implica la imposibilidad de continuar prestando el servicio y, '
      'por tanto, la terminación de la cuenta.',
    ),

    LegalBlock.heading('14. Cookies y tecnologías de rastreo'),
    LegalBlock.paragraph(
      'La Aplicación no utiliza cookies, balizas web, identificadores '
      'publicitarios ni tecnologías equivalentes de rastreo con fines '
      'comerciales o de creación de perfiles.',
    ),

    LegalBlock.heading('15. Modificaciones al Aviso de Privacidad'),
    LegalBlock.paragraph(
      '15.1. El presente Aviso puede ser modificado para atender novedades '
      'legislativas, políticas internas o nuevos requerimientos para la '
      'prestación del servicio.',
    ),
    LegalBlock.paragraph(
      '15.2. Cuando la modificación sea sustancial, la Aplicación mostrará la '
      'nueva versión y solicitará nuevamente el consentimiento antes de permitir '
      'la continuación del uso. La versión vigente estará disponible en todo '
      'momento dentro de la Aplicación.',
    ),

    LegalBlock.heading('16. Autoridad garante'),
    LegalBlock.paragraph(
      'Si el titular considera que su derecho a la protección de datos '
      'personales ha sido vulnerado, o presume alguna violación a las '
      'disposiciones de la Ley, podrá interponer la denuncia o queja '
      'correspondiente ante la autoridad garante competente en materia de '
      'protección de datos personales en los Estados Unidos Mexicanos.',
    ),

    LegalBlock.heading('17. Contacto'),
    LegalBlock.paragraph(
      'Cualquier duda relacionada con el presente Aviso de Privacidad puede '
      'dirigirse al correo electrónico $kLegalContactEmail, atendido '
      'directamente por el equipo responsable del proyecto.',
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Terms and Conditions (English)
// ─────────────────────────────────────────────────────────────────────────────

const LegalDocument _termsEn = LegalDocument(
  title: 'Terms and Conditions of Use',
  shortTitle: 'Terms and Conditions',
  lastUpdated: 'September 17, 2026',
  blocks: [
    LegalBlock.paragraph(
      'These Terms and Conditions of Use (the "Terms") govern access to and use '
      'of the mobile application Appy TEApoya TEAcompaña (the "Application"), '
      'made available by $kLegalResponsable (the "Provider"). Please read them '
      'in full before creating an account.',
    ),

    LegalBlock.heading('1. Definitions'),
    LegalBlock.bullet(
      '"Application": the software known as Appy TEApoya TEAcompaña, including '
      'its code, interfaces, audiovisual content, pictograms, databases and any '
      'subsequent update or version.',
    ),
    LegalBlock.bullet(
      '"Account Holder": the adult who creates, manages and is responsible for '
      'an account in the Application.',
    ),
    LegalBlock.bullet(
      '"Assisted User": the minor or person under guardianship who uses the '
      'Application under the Account Holder\'s supervision.',
    ),
    LegalBlock.bullet(
      '"Content": all videos, illustrations, pictograms, voice-overs, texts, '
      'trademarks, designs and graphic elements included in the Application.',
    ),

    LegalBlock.heading('2. Purpose'),
    LegalBlock.paragraph(
      '2.1. The Application provides supporting educational material for '
      'learning and practising daily living skills, primarily aimed at people '
      'with Autism Spectrum Disorder, through audiovisual content and '
      'interactive activities.',
    ),
    LegalBlock.paragraph(
      '2.2. The Provider is an independent, non-profit team. The Application is '
      'offered free of charge, contains no advertising, sells no goods or '
      'services and generates no revenue from its use.',
    ),

    LegalBlock.heading(
      '3. Nature of the service and absence of medical purpose',
    ),
    LegalBlock.note(
      'The Application is not a medical device, does not provide diagnoses, '
      'does not issue clinical assessments and does not replace intervention by '
      'health, psychology, occupational therapy, speech therapy or special '
      'education professionals.',
    ),
    LegalBlock.paragraph(
      '3.1. The Content is strictly educational and complementary in nature. Its '
      'use does not create any therapeutic relationship between the Provider '
      'and the User.',
    ),
    LegalBlock.paragraph(
      '3.2. Progress, stars, levels or any metric displayed by the Application '
      'is solely a record of activity within the programme and must not be '
      'interpreted as a clinical indicator, developmental assessment or '
      'evidence of therapeutic progress.',
    ),
    LegalBlock.paragraph(
      '3.3. The Account Holder acknowledges that no medical, therapeutic or '
      'educational decision regarding the Assisted User should be made solely '
      'on the basis of the Application, and undertakes to consult the relevant '
      'professionals.',
    ),

    LegalBlock.heading('4. Legal capacity and acceptance'),
    LegalBlock.paragraph(
      '4.1. Creating an Account requires being of legal age and having full '
      'legal capacity under Mexican law.',
    ),
    LegalBlock.paragraph(
      '4.2. By ticking the acceptance box and continuing, the Account Holder '
      'declares that: (i) they are of legal age; (ii) they are the parent, legal '
      'guardian or legally authorised person in respect of the Assisted User; '
      '(iii) they have read these Terms and the Privacy Notice in full; and '
      '(iv) they give express consent to the processing of personal data as '
      'described therein.',
    ),
    LegalBlock.paragraph(
      '4.3. Acceptance is recorded electronically, stating the accepted version '
      'and the corresponding date.',
    ),

    LegalBlock.heading('5. Account and credentials'),
    LegalBlock.paragraph(
      '5.1. Registration requires a valid email address and a password. The '
      'Account Holder is solely responsible for the accuracy of the data '
      'provided.',
    ),
    LegalBlock.paragraph(
      '5.2. Credentials are personal and non-transferable. The Account Holder '
      'must keep them strictly confidential and is responsible for all activity '
      'carried out through the Account.',
    ),
    LegalBlock.paragraph(
      '5.3. The Application includes a parental access code (PIN) restricting '
      'entry to the settings screen. The PIN is stored locally on the device and '
      'linked to the Account.',
    ),
    LegalBlock.paragraph(
      '5.4. Any unauthorised use of the Account must be reported immediately to '
      '$kLegalContactEmail.',
    ),

    LegalBlock.heading('6. Supervision of the Assisted User'),
    LegalBlock.paragraph(
      '6.1. The Application is designed for use under adult supervision. The '
      'Account Holder is responsible for determining whether the Content is '
      'suitable for the Assisted User.',
    ),
    LegalBlock.paragraph(
      '6.2. The Account Holder is responsible for screen time, the physical '
      'environment in which the Application is used and supervision during the '
      'suggested activities, particularly those involving household objects, '
      'food, personal hygiene or social interaction.',
    ),

    LegalBlock.heading('7. Licence of use'),
    LegalBlock.paragraph(
      'The Provider grants a limited, personal, revocable, non-transferable, '
      'non-exclusive and non-sublicensable licence to install and use the '
      'Application for strictly personal, educational and non-commercial '
      'purposes. This licence transfers no ownership or rights over the '
      'Application or the Content.',
    ),

    LegalBlock.heading('8. Prohibited conduct'),
    LegalBlock.paragraph('Users are expressly prohibited from:'),
    LegalBlock.bullet(
      'Using the Application for purposes other than those set out in clause 2, '
      'or in a manner contrary to law or public order.',
    ),
    LegalBlock.bullet(
      'Decompiling, disassembling, reverse engineering, modifying or creating '
      'derivative works of the Application, except where expressly permitted by '
      'applicable law.',
    ),
    LegalBlock.bullet(
      'Accessing or attempting to access accounts, data, systems or '
      'infrastructure areas that are not theirs.',
    ),
    LegalBlock.bullet(
      'Interfering with, overloading or compromising the security, integrity or '
      'availability of the Application or the third-party services supporting '
      'it.',
    ),
    LegalBlock.bullet(
      'Extracting, reproducing, distributing, publicly communicating or '
      'transforming the Content, in whole or in part, for commercial purposes or '
      'without the Provider\'s written authorisation.',
    ),
    LegalBlock.bullet(
      'Using automated means to access the service, manipulate the reward system '
      'or alter progress records.',
    ),

    LegalBlock.heading('9. Intellectual property'),
    LegalBlock.paragraph(
      '9.1. The Application and all Content, including without limitation the '
      'animated videos, pictograms, voice-overs, character design, interfaces, '
      'source code and databases, are owned by the Provider or its respective '
      'authors and are protected by Mexican copyright and industrial property '
      'law and applicable international treaties.',
    ),
    LegalBlock.paragraph(
      '9.2. Nothing in these Terms may be construed as an assignment, licence or '
      'authorisation to use the Provider\'s trademarks, trade names or '
      'distinctive signs.',
    ),
    LegalBlock.paragraph(
      '9.3. Any person who believes that Content infringes intellectual property '
      'rights may notify $kLegalContactEmail, providing evidence of ownership.',
    ),

    LegalBlock.heading('10. Virtual items'),
    LegalBlock.paragraph(
      '10.1. The Application grants virtual coins as an incentive for completing '
      'activities. These coins only unlock decorative avatar items within the '
      'Application.',
    ),
    LegalBlock.paragraph(
      '10.2. Virtual coins have no monetary value, are not legal tender, a '
      'credit instrument or a means of payment, cannot be purchased with real '
      'money, are not transferable between accounts and are not exchangeable, '
      'refundable or compensable under any circumstance, including account '
      'termination.',
    ),
    LegalBlock.paragraph(
      '10.3. The Provider reserves the right to adjust earning rules, item costs '
      'and balances where necessary to correct errors, prevent abuse or redesign '
      'the educational experience.',
    ),

    LegalBlock.heading('11. Availability and changes to the service'),
    LegalBlock.paragraph(
      '11.1. The Application is provided on an as-available basis. The Provider '
      'does not guarantee uninterrupted, timely, secure or error-free operation.',
    ),
    LegalBlock.paragraph(
      '11.2. As a non-profit project maintained by a small team, there may be '
      'outages, faults, periods without updates, changes to features or partial '
      'or total discontinuation of the service.',
    ),
    LegalBlock.paragraph(
      '11.3. Access requires an internet connection and a compatible device. '
      'Data, equipment and power costs are borne by the User.',
    ),

    LegalBlock.heading('12. Third-party services'),
    LegalBlock.paragraph(
      'The Application relies on third-party infrastructure, in particular '
      'Google Firebase, as described in the Privacy Notice. The Provider does '
      'not control those services and is not liable for their interruptions, '
      'faults or changes, without prejudice to the Provider\'s own obligations '
      'as data controller.',
    ),

    LegalBlock.heading('13. Disclaimer of warranties'),
    LegalBlock.paragraph(
      '13.1. To the maximum extent permitted by applicable law, the Application '
      'and the Content are provided "as is" and "as available", without '
      'warranties of any kind, whether express or implied.',
    ),
    LegalBlock.paragraph(
      '13.2. The Provider does not warrant that the Content is suitable for any '
      'particular case, that it will produce a given educational outcome, that '
      'it is free from errors or omissions, or that the Application is '
      'compatible with all devices or operating system versions.',
    ),
    LegalBlock.paragraph(
      '13.3. These exclusions do not apply to warranties that cannot validly be '
      'excluded under consumer protection law.',
    ),

    LegalBlock.heading('14. Limitation of liability'),
    LegalBlock.paragraph(
      '14.1. To the maximum extent permitted by law, the Provider, its members '
      'and collaborators shall not be liable for indirect, incidental, special, '
      'punitive or consequential damages, nor for loss of data, opportunity or '
      'profit, arising from the use or inability to use the Application.',
    ),
    LegalBlock.paragraph(
      '14.2. The Provider shall not be liable for damages arising from: (i) '
      'medical, therapeutic or educational decisions based on the Application; '
      '(ii) lack of supervision of the Assisted User; (iii) use of credentials '
      'by unauthorised third parties; (iv) connectivity, device or third-party '
      'service failures; or (v) acts of God or force majeure.',
    ),
    LegalBlock.paragraph(
      '14.3. Nothing in these Terms excludes or limits liability for wilful '
      'misconduct, bad faith or any matter that applicable law declares '
      'non-waivable.',
    ),

    LegalBlock.heading('15. Indemnity'),
    LegalBlock.paragraph(
      'The Account Holder shall hold the Provider, its members and collaborators '
      'harmless from any claim, demand, proceeding, penalty, damage or expense, '
      'including reasonable legal fees, arising from breach of these Terms, '
      'misuse of the Application or infringement of third-party rights '
      'attributable to them.',
    ),

    LegalBlock.heading('16. Suspension and termination'),
    LegalBlock.paragraph(
      '16.1. The Account Holder may terminate the relationship at any time by '
      'ceasing to use the Application and deleting the Account from the '
      '"Account and security" section of the settings screen.',
    ),
    LegalBlock.paragraph(
      '16.2. The Provider may suspend or cancel an Account, with prior notice '
      'where possible, in the event of breach of these Terms or use that '
      'compromises the security of the service.',
    ),
    LegalBlock.paragraph(
      '16.3. Termination entails loss of access to progress, customisation and '
      'virtual coins associated with the Account, without right to compensation.',
    ),

    LegalBlock.heading('17. Data protection'),
    LegalBlock.paragraph(
      'The processing of personal data is governed by the Privacy Notice, which '
      'forms an integral part of these Terms and may be consulted at any time '
      'from the settings screen.',
    ),

    LegalBlock.heading('18. Changes to these Terms'),
    LegalBlock.paragraph(
      'Where changes are substantial, the Application will display the new '
      'version and request acceptance before allowing continued use. Refusal '
      'entitles the User to stop using the Application and delete the Account.',
    ),

    LegalBlock.heading('19. Severability, assignment and waiver'),
    LegalBlock.paragraph(
      'If any provision is held void, unlawful or unenforceable, it shall be '
      'deemed not written and the remaining provisions shall remain in full '
      'force. The User may not assign rights or obligations under these Terms. '
      'Failure or delay in exercising any right shall not constitute a waiver '
      'thereof.',
    ),

    LegalBlock.heading('20. Entire agreement'),
    LegalBlock.paragraph(
      'These Terms, together with the Privacy Notice, constitute the entire '
      'agreement between the parties regarding use of the Application.',
    ),

    LegalBlock.heading('21. Governing law and jurisdiction'),
    LegalBlock.paragraph(
      'These Terms are governed by the laws of the United Mexican States. The '
      'parties submit to the competent courts of $kLegalJurisdiccion, waiving '
      'any other jurisdiction, without prejudice to consumer protection rights.',
    ),

    LegalBlock.heading('22. Contact'),
    LegalBlock.paragraph(
      'For questions or notices relating to these Terms, please write to '
      '$kLegalContactEmail.',
    ),
    LegalBlock.note(
      'These Terms were originally drafted in Spanish. In the event of any '
      'discrepancy between versions, the Spanish text shall prevail.',
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Privacy Notice (English)
// ─────────────────────────────────────────────────────────────────────────────

const LegalDocument _privacyEn = LegalDocument(
  title: 'Privacy Notice',
  shortTitle: 'Privacy Notice',
  lastUpdated: 'September 17, 2026',
  blocks: [
    LegalBlock.paragraph(
      'This Privacy Notice is issued in compliance with the Mexican Federal Law '
      'on Protection of Personal Data Held by Private Parties and its '
      'Regulations.',
    ),

    LegalBlock.heading('1. Data controller'),
    LegalBlock.paragraph(
      '$kLegalResponsable, an independent non-profit team operating in '
      '$kLegalJurisdiccion, is responsible for processing the personal data '
      'collected through the Appy TEApoya TEAcompaña mobile application. '
      'Address for notices on data protection matters: $kLegalContactEmail.',
    ),

    LegalBlock.heading('2. Personal data processed'),
    LegalBlock.bullet(
      'Identification and contact data: display name and email address.',
    ),
    LegalBlock.bullet(
      'Authentication data: password, stored encrypted by the authentication '
      'provider. The controller has no access to it in readable form.',
    ),
    LegalBlock.bullet(
      'Account records: creation date and, where applicable, deletion request '
      'date.',
    ),
    LegalBlock.bullet(
      'Educational activity data: modules and steps completed, stars earned, '
      'modalities finished, number of incorrect answers and dates of each '
      'advance.',
    ),
    LegalBlock.bullet(
      'Customisation data: character name, chosen appearance, background, '
      'unlocked accessories, virtual coins and avatar happiness and energy '
      'levels.',
    ),
    LegalBlock.bullet(
      'Consent record: accepted version of the legal documents and date of '
      'acceptance.',
    ),
    LegalBlock.paragraph(
      'No financial, biometric, geolocation, image, audio, contact or device '
      'file data is collected.',
    ),

    LegalBlock.heading('3. Sensitive personal data'),
    LegalBlock.note(
      'The Application is aimed at supporting people with Autism Spectrum '
      'Disorder. Consequently, use of the service alone may reveal information '
      'relating to the Assisted User\'s health, which constitutes sensitive '
      'personal data under Mexican law.',
    ),
    LegalBlock.paragraph(
      'For that reason, processing requires the express consent of the data '
      'subject or of the person exercising parental authority or guardianship, '
      'obtained through electronic acceptance of this Notice. No diagnosis, '
      'clinical record or additional health data is requested.',
    ),

    LegalBlock.heading('4. Data of minors'),
    LegalBlock.paragraph(
      'The account is created and managed exclusively by an adult exercising '
      'parental authority, guardianship or legal representation of the Assisted '
      'User, who gives consent on their behalf in accordance with the principle '
      'of the best interests of the child. The Application creates no public '
      'profiles and allows no communication between users.',
    ),

    LegalBlock.heading('5. Primary purposes'),
    LegalBlock.bullet(
      'Creating, identifying, authenticating and managing the user account.',
    ),
    LegalBlock.bullet(
      'Storing and synchronising educational progress across devices and '
      'determining the content available at any time.',
    ),
    LegalBlock.bullet(
      'Preserving avatar customisation and virtual coin balance.',
    ),
    LegalBlock.bullet(
      'Evidencing the granting of consent and the accepted version of the legal '
      'documents.',
    ),
    LegalBlock.bullet(
      'Handling support requests and the exercise of data subject rights.',
    ),
    LegalBlock.bullet(
      'Complying with legal obligations and requests from competent authorities.',
    ),

    LegalBlock.heading('6. Secondary purposes'),
    LegalBlock.paragraph(
      'The following purpose is not necessary for the service and may be '
      'disabled at any time from the settings screen, under "Privacy and data": '
      'generation of dissociated usage metrics in order to assess the relevance '
      'of educational content and improve the Application. This option is '
      'disabled by default. Refusal will not be grounds for denying the service.',
    ),

    LegalBlock.heading('7. Limitation of use and disclosure'),
    LegalBlock.bullet(
      'No personal data is sold, rented, marketed or assigned.',
    ),
    LegalBlock.bullet(
      'No processing is carried out for marketing, advertising or commercial prospecting purposes.',
    ),
    LegalBlock.bullet(
      'No advertising or third-party commercial tracking technologies are included.',
    ),

    LegalBlock.heading('8. Processors and transfers'),
    LegalBlock.paragraph(
      '8.1. The controller uses Google Firebase infrastructure, provided by '
      'Google LLC and its affiliates, as data processor, for authentication, '
      'database and content storage services.',
    ),
    LegalBlock.paragraph(
      '8.2. This entails sending data to servers that may be located outside '
      'Mexico. The processor is contractually bound to process data only on the '
      'controller\'s instructions and to maintain equivalent security measures.',
    ),
    LegalBlock.paragraph(
      '8.3. Apart from the above, no personal data is transferred to third '
      'parties, except in the cases provided by law, including requests from '
      'competent authorities based on a duly founded and reasoned decision.',
    ),

    LegalBlock.heading('9. Data that does not leave the device'),
    LegalBlock.bullet('Theme, font size and language.'),
    LegalBlock.bullet(
      'Accessibility preferences: high contrast, reduced animations, audio and '
      'haptic feedback.',
    ),
    LegalBlock.bullet('Practice reminders and configured schedule.'),
    LegalBlock.bullet('Parental control configuration.'),
    LegalBlock.bullet(
      'Parental access code (PIN), deleted when the account is removed.',
    ),

    LegalBlock.heading('10. Retention period'),
    LegalBlock.paragraph(
      'Data is retained while the account and the relationship with the '
      'controller subsist. Upon a deletion request, access is cancelled, locally '
      'stored data is removed and the record is marked for deletion, retaining '
      'only information whose storage is legally required, for the applicable '
      'legal periods.',
    ),

    LegalBlock.heading('11. Security measures'),
    LegalBlock.paragraph(
      'Administrative and technical measures have been implemented to protect '
      'personal data against damage, loss, alteration, destruction or '
      'unauthorised access, including password encryption, per-account '
      'authentication and database security rules. No system is invulnerable; '
      'users contribute by using a strong, unique password.',
    ),
    LegalBlock.paragraph(
      'In the event of a security breach materially affecting data subjects\' '
      'rights, the controller will report it without delay through the '
      'Application or the registered email address.',
    ),

    LegalBlock.heading('12. Data subject rights'),
    LegalBlock.paragraph(
      'Data subjects, or their legal representatives, may request access to '
      'their personal data, rectification when inaccurate or incomplete, '
      'cancellation when they consider it unnecessary for the stated purposes, '
      'and may object to its processing for specific purposes.',
    ),
    LegalBlock.paragraph(
      'Requests must be sent to $kLegalContactEmail including: the data '
      'subject\'s name and a means of reply; proof of identity or legal '
      'representation; a clear description of the data concerned; and any '
      'element facilitating its location. A determination will be communicated '
      'within a maximum of twenty business days.',
    ),

    LegalBlock.heading('13. Withdrawal of consent'),
    LegalBlock.paragraph(
      'Consent may be withdrawn at any time, without retroactive effect, by '
      'deleting the account from the settings screen or by request to '
      '$kLegalContactEmail. Withdrawal in respect of primary purposes means the '
      'service can no longer be provided and the account will be terminated.',
    ),

    LegalBlock.heading('14. Cookies and tracking technologies'),
    LegalBlock.paragraph(
      'The Application uses no cookies, web beacons, advertising identifiers or '
      'equivalent tracking technologies for commercial or profiling purposes.',
    ),

    LegalBlock.heading('15. Changes to this Notice'),
    LegalBlock.paragraph(
      'Where changes are substantial, the Application will display the new '
      'version and request consent again before allowing continued use. The '
      'current version is available at all times within the Application.',
    ),

    LegalBlock.heading('16. Supervisory authority'),
    LegalBlock.paragraph(
      'Data subjects who consider their right to protection of personal data has '
      'been infringed may file a complaint with the competent data protection '
      'supervisory authority in the United Mexican States.',
    ),

    LegalBlock.heading('17. Contact'),
    LegalBlock.paragraph(
      'Any question regarding this Privacy Notice may be addressed to '
      '$kLegalContactEmail, handled directly by the project team.',
    ),
    LegalBlock.note(
      'This Notice was originally drafted in Spanish. In the event of any '
      'discrepancy between versions, the Spanish text shall prevail.',
    ),
  ],
);
