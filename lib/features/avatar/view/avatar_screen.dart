import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/avatar_models.dart';
import '../viewmodel/avatar_viewmodel.dart';

/*
Diseño completo de la pantalla de avatar con todas sus funcionalidades:
- Mostrar avatar con skin, expresión y accesorio
- Mostrar stats (felicidad, energía, monedas)
- Botón para abrir panel de edición
- Panel de edición con secciones para skins, expresiones, accesorios y fondos
*/
class AvatarScreen
    extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() =>
      _AvatarScreenState();
}

class _AvatarScreenState
    extends State<AvatarScreen> {
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
                    image: AssetImage(
                      viewModel
                          .currentEstado
                          .backgroundActual,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                          16.0,
                        ),
                    child: Column(
                      children: [
                        _buildInfoRobot(
                          context,
                          viewModel,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Expanded(
                          child:
                              _buildAvatarDisplay(
                                viewModel,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (viewModel
                  .showEditPanel)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child:
                      _buildEditPanel(
                        context,
                        viewModel,
                      ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarDisplay(
    AvatarViewModel viewModel,
  ) {
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
                borderRadius:
                    BorderRadius.circular(
                      100,
                    ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(
                          alpha: 0.6,
                        ),
                    blurRadius: 40,
                    offset:
                        const Offset(
                          0,
                          30,
                        ),
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.cyan
                        .withValues(
                          alpha: 0.5,
                        ),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Image.asset(
            viewModel
                .currentEstado
                .skinActual
                .imagenBase,
            fit: BoxFit.contain,
          ),
          if (viewModel
                  .currentEstado
                  .expresionActual !=
              null)
            Image.asset(
              viewModel
                  .currentEstado
                  .expresionActual!,
              fit: BoxFit.contain,
            ),
          if (viewModel
                  .currentEstado
                  .accesorioActual !=
              null)
            Positioned(
              top: viewModel
                  .currentEstado
                  .accesorioActual!
                  .top,
              left: viewModel
                  .currentEstado
                  .accesorioActual!
                  .left,
              child: SizedBox(
                width: viewModel
                    .currentEstado
                    .accesorioActual!
                    .width,
                height: viewModel
                    .currentEstado
                    .accesorioActual!
                    .height,
                child: Image.asset(
                  viewModel
                      .currentEstado
                      .accesorioActual!
                      .imagenPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditPanel(
    BuildContext context,
    AvatarViewModel viewModel,
  ) {
    return Container(
      height:
          MediaQuery.of(
            context,
          ).size.height *
          0.65,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xF20D3B52),
            Color(0xFF091F2C),
          ],
        ),
        borderRadius:
            const BorderRadius.only(
              topLeft: Radius.circular(
                30,
              ),
              topRight: Radius.circular(
                30,
              ),
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(
                  16.0,
                ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                const Text(
                  'Personalizar Avatar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => context
                      .read<
                        AvatarViewModel
                      >()
                      .toggleEditPanel(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  _buildSectionTitle(
                    'Skins',
                  ),
                  _buildSkinsSection(
                    context,
                    viewModel,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _buildSectionTitle(
                    'Expresiones',
                  ),
                  _buildExpresionesSection(
                    context,
                    viewModel,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _buildSectionTitle(
                    'Accesorios',
                  ),
                  _buildAccesoriosSection(
                    context,
                    viewModel,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _buildSectionTitle(
                    'Fondos',
                  ),
                  _buildBackgroundsSection(
                    context,
                    viewModel,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
  ) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 8.0,
    ),
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _buildSkinsSection(
    BuildContext context,
    AvatarViewModel viewModel,
  ) {
    final skins =
        viewModel.availableSkins;
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
            ),
        itemCount: skins.length,
        itemBuilder: (context, index) {
          final skin = skins[index];
          final isSelected =
              viewModel
                  .currentEstado
                  .skinActual
                  .nombre ==
              skin.nombre;
          return _buildCard(
            context,
            100,
            isSelected,
            const Color(0xFF00E5FF),
            () => context
                .read<AvatarViewModel>()
                .updateSkin(skin),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                          8.0,
                        ),
                    child: Image.asset(
                      skin.imagenBase,
                      fit: BoxFit
                          .contain,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.all(
                        4,
                      ),
                  child: Text(
                    skin.nombre,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(
                              0xFF00E5FF,
                            )
                          : Colors
                                .white70,
                      fontSize: 12,
                    ),
                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpresionesSection(
    BuildContext context,
    AvatarViewModel viewModel,
  ) {
    final expresiones =
        viewModel
            .currentEstado
            .skinActual
            .expresiones ??
        [];
    if (expresiones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Text(
          'Esta skin no tiene expresiones disponibles',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      );
    }
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
            ),
        itemCount: expresiones.length,
        itemBuilder: (context, index) {
          final expresion =
              expresiones[index];
          final isSelected =
              viewModel
                  .currentEstado
                  .expresionActual ==
              expresion;
          return _buildCard(
            context,
            80,
            isSelected,
            const Color(0xFFFFD700),
            () => context
                .read<AvatarViewModel>()
                .updateExpresion(
                  expresion,
                ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                    8.0,
                  ),
              child: Image.asset(
                expresion,
                fit: BoxFit.contain,
              ),
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
    final accesorios =
        viewModel.availableAccesorios;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
            ),
        itemCount:
            accesorios.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected =
                viewModel
                    .currentEstado
                    .accesorioActual ==
                null;
            return _buildCard(
              context,
              80,
              isSelected,
              const Color(0xFF00E5FF),
              () => context
                  .read<
                    AvatarViewModel
                  >()
                  .updateAccesorio(
                    null,
                  ),
              child: const Center(
                child: Icon(
                  Icons.close,
                  color: Colors.white54,
                  size: 40,
                ),
              ),
            );
          }
          final accesorio =
              accesorios[index - 1];
          final isSelected =
              viewModel
                  .currentEstado
                  .accesorioActual
                  ?.nombre ==
              accesorio.nombre;
          final isDesbloqueado =
              !accesorio.bloqueado ||
              viewModel
                  .isAccesorioDesbloqueado(
                    accesorio.nombre,
                  );

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
    final backgrounds =
        viewModel.availableBackgrounds;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
            ),
        itemCount: backgrounds.length,
        itemBuilder: (context, index) {
          final background =
              backgrounds[index];
          final isSelected =
              viewModel
                  .currentEstado
                  .backgroundActual ==
              background;
          return _buildCard(
            context,
            120,
            isSelected,
            const Color(0xFF92C5BC),
            () => context
                .read<AvatarViewModel>()
                .updateBackground(
                  background,
                ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
              child: Image.asset(
                background,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
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
      padding:
          const EdgeInsets.symmetric(
            horizontal: 4,
          ),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? neonColor
                : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: neonColor,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(
                  15,
                ),
            onTap: onTap,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRobot(
    BuildContext context,
    AvatarViewModel viewModel,
  ) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: _buildFaceButton(
                viewModel
                    .currentEstado
                    .felicidad,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 56,
                child: _buildNameButton(
                  viewModel
                      .currentEstado
                      .nombre,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              height: 56,
              child: _buildEditButton(
                context,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildStatButton(
                label: 'Felicidad',
                value: viewModel
                    .currentEstado
                    .felicidad,
                gradientColors: const [
                  Color(0xFFFFD700),
                  Color(0xFFFFA500),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildStatButton(
                label: 'Energía',
                value: viewModel
                    .currentEstado
                    .energia,
                gradientColors: const [
                  Color(0xFF92C5BC),
                  Color(0xFF5A97B8),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildStatButton(
                label: 'Monedas',
                value: viewModel
                    .currentEstado
                    .monedas,
                gradientColors: const [
                  Color(0xFFFFD700),
                  Color(0xFFFF8C00),
                ],
                icon: Icons
                    .monetization_on,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFaceButton(
    int felicidad,
  ) {
    String imagePath;
    Color neonColor;
    if (felicidad > 70) {
      imagePath =
          'assets/images/FELIZ.png';
      neonColor = const Color(
        0xFF00E5FF,
      );
    } else if (felicidad >= 40) {
      imagePath =
          'assets/images/MEH.png';
      neonColor = const Color(
        0xFFFF8C00,
      );
    } else {
      imagePath =
          'assets/images/TRISTE.png';
      neonColor = const Color(
        0xFFFF3030,
      );
    }
    return _buildButton(
      neonColor,
      () {},
      Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: neonColor
                    .withValues(
                      alpha: 0.6,
                    ),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameButton(
    String nombre,
  ) => _buildButton(
    Colors.transparent,
    () {},
    Center(
      child: Text(
        nombre,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    ),
  );

  Widget _buildEditButton(
    BuildContext context,
  ) => _buildButton(
    const Color(0xFF6B9BB9),
    () => context
        .read<AvatarViewModel>()
        .toggleEditPanel(),
    const Center(
      child: Icon(
        Icons.edit,
        color: Colors.white,
        size: 22,
      ),
    ),
  );

  Widget _buildButton(
    Color shadowColor,
    VoidCallback onTap,
    Widget child,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          const BoxShadow(
            color: Color(0x50000000),
            blurRadius: 12,
            offset: Offset(0, 6),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                    begin: Alignment
                        .topLeft,
                    end: Alignment
                        .bottomRight,
                    colors: [
                      Color(0xFF2C5F7A),
                      Color(0xFF1A3D52),
                    ],
                  ),
              borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
              border: Border.all(
                color: const Color(
                  0x66FFFFFF,
                ),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildStatButton({
    required String label,
    required int value,
    required List<Color> gradientColors,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          const BoxShadow(
            color: Color(0x50000000),
            blurRadius: 12,
            offset: Offset(0, 6),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: gradientColors[0],
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(18),
          onTap: () {},
          child: Container(
            padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                    begin: Alignment
                        .topLeft,
                    end: Alignment
                        .bottomRight,
                    colors: [
                      Color(0xFF2C5F7A),
                      Color(0xFF1A3D52),
                    ],
                  ),
              borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
              border: Border.all(
                color: const Color(
                  0x66FFFFFF,
                ),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors
                              .white70,
                          fontSize: 9,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                    ),
                    const SizedBox(
                      width: 2,
                    ),
                    if (icon != null)
                      Row(
                        mainAxisSize:
                            MainAxisSize
                                .min,
                        children: [
                          Icon(
                            icon,
                            color:
                                gradientColors[0],
                            size: 12,
                          ),
                          const SizedBox(
                            width: 2,
                          ),
                          Text(
                            '$value',
                            style: TextStyle(
                              color: Colors
                                  .white,
                              fontSize:
                                  10,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              shadows: [
                                Shadow(
                                  color:
                                      gradientColors[0],
                                  blurRadius:
                                      6,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '$value%',
                        style: TextStyle(
                          color: Colors
                              .white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight
                                  .bold,
                          shadows: [
                            Shadow(
                              color:
                                  gradientColors[0],
                              blurRadius:
                                  6,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (icon == null) ...[
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          const Color(
                            0x33FFFFFF,
                          ),
                      borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(
                            0x80000000,
                          ),
                          blurRadius: 3,
                          offset:
                              Offset(
                                0,
                                1,
                              ),
                        ),
                      ],
                    ),
                    child: FractionallySizedBox(
                      widthFactor:
                          value / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment
                                .centerLeft,
                            end: Alignment
                                .centerRight,
                            colors:
                                gradientColors,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                                10,
                              ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  gradientColors[0],
                              blurRadius:
                                  6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
    return Padding(
      padding:
          const EdgeInsets.symmetric(
            horizontal: 4,
          ),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? const Color(
                    0xFFFF8C00,
                  )
                : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(
                      0xFFFF8C00,
                    ),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(
                  15,
                ),
            onTap: () {
              if (isDesbloqueado) {
                context
                    .read<
                      AvatarViewModel
                    >()
                    .updateAccesorio(
                      accesorio,
                    );
              } else {
                _mostrarDialogoDesbloqueo(
                  context,
                  accesorio,
                  viewModel,
                );
              }
            },
            child: Stack(
              children: [
                // Imagen del accesorio
                Padding(
                  padding:
                      const EdgeInsets.all(
                        8.0,
                      ),
                  child: Opacity(
                    opacity:
                        isDesbloqueado
                        ? 1.0
                        : 0.3,
                    child: Image.asset(
                      accesorio
                          .imagenPath,
                      fit: BoxFit
                          .contain,
                    ),
                  ),
                ),
                // Overlay de candado si está bloqueado
                if (!isDesbloqueado)
                  Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        const Icon(
                          Icons.lock,
                          color: Colors
                              .white,
                          size: 30,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                horizontal:
                                    6,
                                vertical:
                                    2,
                              ),
                          decoration: BoxDecoration(
                            color: Colors
                                .black,
                            borderRadius:
                                BorderRadius.circular(
                                  8,
                                ),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize
                                    .min,
                            children: [
                              const Icon(
                                Icons
                                    .monetization_on,
                                color: Color(
                                  0xFFFFD700,
                                ),
                                size:
                                    12,
                              ),
                              const SizedBox(
                                width:
                                    2,
                              ),
                              Text(
                                '${accesorio.costoMonedas}',
                                style: const TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize:
                                      10,
                                  fontWeight:
                                      FontWeight.bold,
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
    final bool tieneSuficientes =
        viewModel
            .currentEstado
            .monedas >=
        accesorio.costoMonedas;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor:
              Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.all(
                  24,
                ),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                    begin: Alignment
                        .topCenter,
                    end: Alignment
                        .bottomCenter,
                    colors: [
                      Color(0xF20D3B52),
                      Color(0xFF091F2C),
                    ],
                  ),
              borderRadius:
                  BorderRadius.circular(
                    30,
                  ),
              border: Border.all(
                color: const Color(
                  0x66FFFFFF,
                ),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(
                    0x50000000,
                  ),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  'Desbloquear ${accesorio.nombre}',
                  style:
                      const TextStyle(
                        color: Colors
                            .white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(
                  height: 24,
                ),
                Container(
                  padding:
                      const EdgeInsets.all(
                        16,
                      ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                    border: Border.all(
                      color:
                          const Color(
                            0xFFFF8C00,
                          ),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(
                          0xFFFF8C00,
                        ),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    accesorio
                        .imagenPath,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  '¿Deseas desbloquear este accesorio?',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                        fontSize: 16,
                        color: Colors
                            .white70,
                      ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(
                          colors: [
                            Color(
                              0xFF2C5F7A,
                            ),
                            Color(
                              0xFF1A3D52,
                            ),
                          ],
                        ),
                    borderRadius:
                        BorderRadius.circular(
                          15,
                        ),
                    border: Border.all(
                      color:
                          const Color(
                            0xFFFFD700,
                          ),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize
                            .min,
                    children: [
                      const Icon(
                        Icons
                            .monetization_on,
                        color: Color(
                          0xFFFFD700,
                        ),
                        size: 24,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        '${accesorio.costoMonedas}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color: Color(
                            0xFFFFD700,
                          ),
                          shadows: [
                            Shadow(
                              color: Color(
                                0xFFFFD700,
                              ),
                              blurRadius:
                                  8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Text(
                      'Tienes ',
                      style:
                          const TextStyle(
                            fontSize:
                                14,
                            color: Colors
                                .white70,
                          ),
                    ),
                    Text(
                      '${viewModel.currentEstado.monedas}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            tieneSuficientes
                            ? const Color(
                                0xFF00E5FF,
                              )
                            : const Color(
                                0xFFFF3030,
                              ),
                      ),
                    ),
                    Text(
                      ' monedas',
                      style:
                          const TextStyle(
                            fontSize:
                                14,
                            color: Colors
                                .white70,
                          ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceEvenly,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                                18,
                              ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(
                                0x50000000,
                              ),
                              blurRadius:
                                  8,
                              offset:
                                  Offset(
                                    0,
                                    4,
                                  ),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors
                              .transparent,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(
                                  18,
                                ),
                            onTap: () =>
                                Navigator.of(
                                  dialogContext,
                                ).pop(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical:
                                    14,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin:
                                      Alignment.topLeft,
                                  end: Alignment
                                      .bottomRight,
                                  colors: [
                                    Color(
                                      0xFF2C5F7A,
                                    ),
                                    Color(
                                      0xFF1A3D52,
                                    ),
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                      18,
                                    ),
                                border: Border.all(
                                  color: const Color(
                                    0x66FFFFFF,
                                  ),
                                  width:
                                      1.5,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                                18,
                              ),
                          boxShadow: [
                            const BoxShadow(
                              color: Color(
                                0x50000000,
                              ),
                              blurRadius:
                                  8,
                              offset:
                                  Offset(
                                    0,
                                    4,
                                  ),
                            ),
                            if (tieneSuficientes)
                              const BoxShadow(
                                color: Color(
                                  0xFFFFD700,
                                ),
                                blurRadius:
                                    15,
                                spreadRadius:
                                    1,
                              ),
                          ],
                        ),
                        child: Material(
                          color: Colors
                              .transparent,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(
                                  18,
                                ),
                            onTap:
                                tieneSuficientes
                                ? () {
                                    final exito = viewModel.desbloquearAccesorio(
                                      accesorio,
                                    );
                                    Navigator.of(
                                      dialogContext,
                                    ).pop();
                                    if (exito) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '¡${accesorio.nombre} desbloqueado!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      viewModel.updateAccesorio(
                                        accesorio,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No tienes suficientes monedas',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical:
                                    14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin:
                                      Alignment.topLeft,
                                  end: Alignment
                                      .bottomRight,
                                  colors:
                                      tieneSuficientes
                                      ? const [
                                          Color(
                                            0xFF2C5F7A,
                                          ),
                                          Color(
                                            0xFF1A3D52,
                                          ),
                                        ]
                                      : const [
                                          Color(
                                            0xFF3A3A3A,
                                          ),
                                          Color(
                                            0xFF2A2A2A,
                                          ),
                                        ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                      18,
                                    ),
                                border: Border.all(
                                  color:
                                      tieneSuficientes
                                      ? const Color(
                                          0xFFFFD700,
                                        )
                                      : const Color(
                                          0x33FFFFFF,
                                        ),
                                  width:
                                      1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Desbloquear',
                                  style: TextStyle(
                                    color:
                                        tieneSuficientes
                                        ? const Color(
                                            0xFFFFD700,
                                          )
                                        : Colors.white38,
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight.bold,
                                    shadows:
                                        tieneSuficientes
                                        ? const [
                                            Shadow(
                                              color: Color(
                                                0xFFFFD700,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
