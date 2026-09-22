import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../shared/services/haptics_service.dart';
import '../model/avatar_models.dart';
import '../viewmodel/avatar_viewmodel.dart';

/*
Diseño completo de la pantalla de avatar con todas sus funcionalidades:
- Mostrar avatar con skin, expresión y accesorio
- Mostrar stats (felicidad, energía, monedas)
- Botón para abrir panel de edición
- Panel de edición con secciones para skins, expresiones, accesorios y fondos
*/
class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AvatarViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(viewModel.currentEstado.backgroundActual),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRobot(context, viewModel),
                        const SizedBox(height: 20),
                        Expanded(child: _buildAvatarDisplay(viewModel)),
                      ],
                    ),
                  ),
                ),
              ),
              if (viewModel.showEditPanel)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildEditPanel(context, viewModel),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarDisplay(AvatarViewModel viewModel) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            child: Container(
              width: 200,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 30),
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          Image.asset(
            viewModel.currentEstado.skinActual.imagenBase,
            fit: BoxFit.contain,
          ),
          if (viewModel.currentEstado.expresionActual != null)
            Image.asset(
              viewModel.currentEstado.expresionActual!,
              fit: BoxFit.contain,
            ),
          if (viewModel.currentEstado.accesorioActual != null)
            Positioned(
              top: viewModel.currentEstado.accesorioActual!.top,
              left: viewModel.currentEstado.accesorioActual!.left,
              child: SizedBox(
                width: viewModel.currentEstado.accesorioActual!.width,
                height: viewModel.currentEstado.accesorioActual!.height,
                child: Image.asset(
                  viewModel.currentEstado.accesorioActual!.imagenPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditPanel(BuildContext context, AvatarViewModel viewModel) {
    final colors = context.appColors;
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        gradient: colors.backgroundGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.sheet),
          topRight: Radius.circular(AppRadius.sheet),
        ),
        border: Border(top: BorderSide(color: colors.surfaceBorder)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Personalizar',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    color: colors.ink,
                    fontSize: 20,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      context.read<AvatarViewModel>().toggleEditPanel(),
                  icon: Icon(Icons.close_rounded, color: colors.ink),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Skins'),
                  _buildSkinsSection(context, viewModel),
                  const SizedBox(height: 20),
                  _buildSectionTitle(context, 'Expresiones'),
                  _buildExpresionesSection(context, viewModel),
                  const SizedBox(height: 20),
                  _buildSectionTitle(context, 'Accesorios'),
                  _buildAccesoriosSection(context, viewModel),
                  const SizedBox(height: 20),
                  _buildSectionTitle(context, 'Fondos'),
                  _buildBackgroundsSection(context, viewModel),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
    child: Text(
      title,
      style: TextStyle(
        color: context.appColors.inkSoft,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
  );

  Widget _buildSkinsSection(BuildContext context, AvatarViewModel viewModel) {
    final skins = viewModel.availableSkins;
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: skins.length,
        itemBuilder: (context, index) {
          final skin = skins[index];
          final isSelected =
              viewModel.currentEstado.skinActual.nombre == skin.nombre;
          final isDesbloqueada =
              !skin.bloqueado || viewModel.isSkinDesbloqueada(skin.nombre);
          return _buildSkinCardWithLock(
            context,
            skin,
            isSelected,
            isDesbloqueada,
            viewModel,
          );
        },
      ),
    );
  }

  Widget _buildSkinCardWithLock(
    BuildContext context,
    SkinInfo skin,
    bool isSelected,
    bool isDesbloqueada,
    AvatarViewModel viewModel,
  ) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? colors.accent : colors.surfaceBorder,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () async {
              if (isDesbloqueada) {
                await context.read<AvatarViewModel>().updateSkin(skin);
              } else {
                _mostrarDialogoDesbloqueoSkin(context, skin, viewModel);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Opacity(
                          opacity: isDesbloqueada ? 1.0 : 0.3,
                          child: Image.asset(
                            skin.imagenBase,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      if (!isDesbloqueada)
                        Center(child: _buildPrecioBadge(colors, skin.costoMonedas)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    skin.nombre,
                    style: TextStyle(
                      color: isSelected ? colors.accent : colors.inkSoft,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Candado + precio, igual en accesorios, skins y fondos: un solo patron
  /// visual para que se aprenda una vez y funcione igual en todos lados.
  Widget _buildPrecioBadge(AppColors colors, int costoMonedas) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, color: colors.ink, size: 26),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: colors.accentSoft,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFFF2B233),
                size: 12,
              ),
              const SizedBox(width: 3),
              Text(
                '$costoMonedas',
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpresionesSection(
    BuildContext context,
    AvatarViewModel viewModel,
  ) {
    final expresiones = viewModel.currentEstado.skinActual.expresiones ?? [];
    if (expresiones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Esta skin no tiene expresiones disponibles',
          style: TextStyle(fontSize: 14),
        ),
      );
    }
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: expresiones.length,
        itemBuilder: (context, index) {
          final expresion = expresiones[index];
          final isSelected =
              viewModel.currentEstado.expresionActual == expresion;
          return _buildCard(
            context,
            80,
            isSelected,
            context.appColors.accent,
            () async {
              await context.read<AvatarViewModel>().updateExpresion(expresion);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(expresion, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccesoriosSection(
    BuildContext context,
    AvatarViewModel viewModel,
  ) {
    final accesorios = viewModel.availableAccesorios;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: accesorios.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = viewModel.currentEstado.accesorioActual == null;
            return _buildCard(
              context,
              80,
              isSelected,
              context.appColors.accent,
              () async {
                await context.read<AvatarViewModel>().updateAccesorio(null);
              },
              child: Center(
                child: Icon(
                  Icons.block_rounded,
                  color: context.appColors.inkSoft,
                  size: 32,
                ),
              ),
            );
          }
          final accesorio = accesorios[index - 1];
          final isSelected =
              viewModel.currentEstado.accesorioActual?.nombre ==
              accesorio.nombre;
          final isDesbloqueado =
              !accesorio.bloqueado ||
              viewModel.isAccesorioDesbloqueado(accesorio.nombre);

          return _buildAccesorioCardWithLock(
            context,
            accesorio,
            isSelected,
            isDesbloqueado,
            viewModel,
          );
        },
      ),
    );
  }

  Widget _buildBackgroundsSection(
    BuildContext context,
    AvatarViewModel viewModel,
  ) {
    final fondos = viewModel.availableFondos;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: fondos.length,
        itemBuilder: (context, index) {
          final fondo = fondos[index];
          final isSelected =
              viewModel.currentEstado.backgroundActual == fondo.path;
          final isDesbloqueado =
              !fondo.bloqueado || viewModel.isFondoDesbloqueado(fondo.path);
          return _buildFondoCardWithLock(
            context,
            fondo,
            isSelected,
            isDesbloqueado,
            viewModel,
          );
        },
      ),
    );
  }

  Widget _buildFondoCardWithLock(
    BuildContext context,
    FondoInfo fondo,
    bool isSelected,
    bool isDesbloqueado,
    AvatarViewModel viewModel,
  ) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? colors.accent : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () async {
              if (isDesbloqueado) {
                await context.read<AvatarViewModel>().updateBackground(
                  fondo.path,
                );
              } else {
                _mostrarDialogoDesbloqueoFondo(context, fondo, viewModel);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Opacity(
                    opacity: isDesbloqueado ? 1.0 : 0.4,
                    child: Image.asset(fondo.path, fit: BoxFit.cover),
                  ),
                ),
                if (!isDesbloqueado)
                  Center(child: _buildPrecioBadge(colors, fondo.costoMonedas)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    double width,
    bool isSelected,
    Color neonColor,
    VoidCallback onTap, {
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? neonColor : context.appColors.surfaceBorder,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: onTap,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRobot(BuildContext context, AvatarViewModel viewModel) {
    final estado = viewModel.currentEstado;
    final loaded = viewModel.isLoaded;
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: _buildFaceButton(context, estado.felicidad, loaded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 56,
                child: _buildNameButton(context, estado.nombre, loaded),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 56, height: 56, child: _buildEditButton(context)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildStatButton(
                context,
                label: 'Felicidad',
                value: loaded ? estado.felicidad : null,
                accent: const Color(0xFFF2B233),
                icon: Icons.favorite_rounded,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildStatButton(
                context,
                label: 'Energía',
                value: loaded ? estado.energia : null,
                accent: context.appColors.accent,
                icon: Icons.bolt_rounded,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildStatButton(
                context,
                label: 'Monedas',
                value: loaded ? estado.monedas : null,
                accent: const Color(0xFFF2B233),
                icon: Icons.monetization_on_rounded,
                isPercent: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Cara del robot segun su felicidad. Usa los presets de cabeza, que
  /// comparten estilo con el resto de ilustraciones del personaje.
  Widget _buildFaceButton(BuildContext context, int felicidad, bool loaded) {
    final String imagePath;
    if (!loaded || felicidad > 70) {
      imagePath = 'assets/images/presets/FELIZ.png';
    } else if (felicidad >= 40) {
      imagePath = 'assets/images/presets/MEH.png';
    } else {
      imagePath = 'assets/images/presets/TRISTE.png';
    }
    return _buildButton(
      context,
      () {},
      Center(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Image.asset(imagePath, fit: BoxFit.contain),
        ),
      ),
      padding: const EdgeInsets.all(6),
    );
  }

  Widget _buildNameButton(BuildContext context, String nombre, bool loaded) {
    final colors = context.appColors;
    return _buildButton(
      context,
      () => _editarNombre(context, nombre),
      Center(
        child: Text(
          loaded ? nombre : '',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 18,
            color: colors.ink,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Renombrar al robot desde la propia tarjeta del nombre.
  Future<void> _editarNombre(BuildContext context, String nombreActual) async {
    final viewModel = context.read<AvatarViewModel>();
    if (!viewModel.isLoaded) return;
    final controller = TextEditingController(text: nombreActual);
    HapticsService.selection();

    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nombre de tu robot'),
        content: TextField(
          controller: controller,
          maxLength: 16,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    HapticsService.selection();
    if (nuevoNombre == null || nuevoNombre.isEmpty) return;
    await viewModel.updateNombre(nuevoNombre);
  }

  Widget _buildEditButton(BuildContext context) => _buildButton(
    context,
    () => context.read<AvatarViewModel>().toggleEditPanel(),
    Center(
      child: Icon(Icons.edit_rounded, color: context.appColors.ink, size: 22),
    ),
  );

  /// Panel de vidrio sobre el fondo del avatar. Toma su tono del tema para
  /// que en modo claro sea blanco translucido y en oscuro azul profundo.
  Widget _buildButton(
    BuildContext context,
    VoidCallback onTap,
    Widget child, {
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 10,
    ),
  }) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: colors.glassFill,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.glassBorder, width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Indicador de una estadistica. Con [value] nulo muestra un guion largo:
  /// la cuenta aun no se ha leido y no hay cifra que mostrar.
  Widget _buildStatButton(
    BuildContext context, {
    required String label,
    required int? value,
    required Color accent,
    required IconData icon,
    bool isPercent = true,
  }) {
    final colors = context.appColors;
    final texto = value == null ? '—' : (isPercent ? '$value%' : '$value');
    return Container(
      decoration: BoxDecoration(
        // Fondo solido (no glassFill translucido): esta tarjeta va encima del
        // fondo elegible del avatar, y con transparencia el texto se perdia
        // contra fondos claros o con mucho detalle.
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.surfaceBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.inkSoft,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isPercent) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 5,
                child: LinearProgressIndicator(
                  value: value == null ? 0 : value / 100,
                  backgroundColor: colors.accentSoft,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccesorioCardWithLock(
    BuildContext context,
    AccesorioGeneral accesorio,
    bool isSelected,
    bool isDesbloqueado,
    AvatarViewModel viewModel,
  ) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? colors.accent : colors.surfaceBorder,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () async {
              if (isDesbloqueado) {
                await context.read<AvatarViewModel>().updateAccesorio(
                  accesorio,
                );
              } else {
                _mostrarDialogoDesbloqueo(context, accesorio, viewModel);
              }
            },
            child: Stack(
              children: [
                // Imagen del accesorio
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Opacity(
                    opacity: isDesbloqueado ? 1.0 : 0.3,
                    child: Image.asset(
                      accesorio.imagenPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Overlay de candado si está bloqueado
                if (!isDesbloqueado)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded, color: colors.ink, size: 26),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accentSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.monetization_on_rounded,
                                color: Color(0xFFF2B233),
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${accesorio.costoMonedas}',
                                style: TextStyle(
                                  color: colors.ink,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoDesbloqueo(
    BuildContext context,
    AccesorioGeneral accesorio,
    AvatarViewModel viewModel,
  ) {
    final colors = context.appColors;
    final bool tieneSuficientes =
        viewModel.currentEstado.monedas >= accesorio.costoMonedas;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Desbloquear ${accesorio.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Image.asset(
                  accesorio.imagenPath,
                  height: 96,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFF2B233),
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${accesorio.costoMonedas}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tieneSuficientes
                    ? 'Tienes ${viewModel.currentEstado.monedas} monedas.'
                    : 'Tienes ${viewModel.currentEstado.monedas} monedas. Completa más actividades para reunir ${accesorio.costoMonedas}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.inkSoft),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: tieneSuficientes
                  ? () async {
                      final exito = await viewModel.desbloquearAccesorio(
                        accesorio,
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      if (!context.mounted) return;
                      if (exito) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${accesorio.nombre} desbloqueado'),
                          ),
                        );
                        await viewModel.updateAccesorio(accesorio);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No tienes suficientes monedas'),
                          ),
                        );
                      }
                    }
                  : null,
              child: const Text('Desbloquear'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoDesbloqueoSkin(
    BuildContext context,
    SkinInfo skin,
    AvatarViewModel viewModel,
  ) {
    final colors = context.appColors;
    final bool tieneSuficientes = viewModel.currentEstado.monedas >= skin.costoMonedas;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Desbloquear ${skin.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Image.asset(skin.imagenBase, height: 96, fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFF2B233),
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${skin.costoMonedas}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tieneSuficientes
                    ? 'Tienes ${viewModel.currentEstado.monedas} monedas.'
                    : 'Tienes ${viewModel.currentEstado.monedas} monedas. Completa más actividades para reunir ${skin.costoMonedas}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.inkSoft),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: tieneSuficientes
                  ? () async {
                      final exito = await viewModel.desbloquearSkin(skin);
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      if (!context.mounted) return;
                      if (exito) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${skin.nombre} desbloqueada')),
                        );
                        await viewModel.updateSkin(skin);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No tienes suficientes monedas'),
                          ),
                        );
                      }
                    }
                  : null,
              child: const Text('Desbloquear'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoDesbloqueoFondo(
    BuildContext context,
    FondoInfo fondo,
    AvatarViewModel viewModel,
  ) {
    final colors = context.appColors;
    final bool tieneSuficientes =
        viewModel.currentEstado.monedas >= fondo.costoMonedas;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Desbloquear fondo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Image.asset(fondo.path, height: 96, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFF2B233),
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${fondo.costoMonedas}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tieneSuficientes
                    ? 'Tienes ${viewModel.currentEstado.monedas} monedas.'
                    : 'Tienes ${viewModel.currentEstado.monedas} monedas. Completa más actividades para reunir ${fondo.costoMonedas}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.inkSoft),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: tieneSuficientes
                  ? () async {
                      final exito = await viewModel.desbloquearFondo(fondo);
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      if (!context.mounted) return;
                      if (exito) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fondo desbloqueado')),
                        );
                        await viewModel.updateBackground(fondo.path);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No tienes suficientes monedas'),
                          ),
                        );
                      }
                    }
                  : null,
              child: const Text('Desbloquear'),
            ),
          ],
        );
      },
    );
  }
}
