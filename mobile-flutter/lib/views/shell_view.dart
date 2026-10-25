import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../models/session.dart';
import '../models/lot.dart';
import '../viewmodels/app_viewmodels.dart';
import 'widgets.dart';
import 'capture_view.dart';
import 'local_detail_view.dart';
import 'central_view.dart';
import 'catalog_view.dart';
import 'connection_view.dart';
import 'connection_status.dart';

class ShellView extends ConsumerStatefulWidget {
  final Session session;
  const ShellView({super.key, required this.session});
  @override
  ConsumerState<ShellView> createState() => _ShellState();
}

class _ShellState extends ConsumerState<ShellView> with WidgetsBindingObserver {
  int tab = 0;
  String query = '';
  bool pendingOnly = false;
  bool syncingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ref.read(workspaceProvider(widget.session)).ensureEdition();
    }
  }

  void push(Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

  void open(LocalLot lot) =>
      push(LocalDetailView(session: widget.session, lot: lot));

  Future<void> syncAll(WorkspaceViewModel vm) async {
    if (syncingAll || vm.busy) return;
    setState(() => syncingAll = true);
    try {
      await vm.sendAll();
    } finally {
      if (mounted) setState(() => syncingAll = false);
    }
    if (mounted) await ref.read(connectionProvider).check();
  }

  Widget lotCard(LocalLot lot) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(15, 23, 42, 0.04),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => open(lot),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_shipping_outlined,
                                  size: 13,
                                  color: AppColors.primaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lot.vehicle,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryContainer,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: AppColors.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeLabel(lot.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lot.supplier,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${number(lot.volume)} L',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryContainer,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '${number(lot.temperature, 1)}°C · ${number(lot.acidity, 0)}°D',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  StateBadge(
                    lot.sent ? 'RECIBIDO POR SERVIDOR' : 'PENDIENTE DE ENVÍO',
                    compact: true,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Ver detalle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> logout(WorkspaceViewModel vm) async {
    if (!await confirmAction(
      context,
      'Cerrar sesión',
      'La edición y los registros permanecerán en este celular.',
    )) {
      return;
    }
    if (await vm.ensureEdition()) {
      await ref.read(authProvider).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(workspaceProvider(widget.session));
    final s = widget.session;
    final filtered = vm.search(query, pendingOnly: pendingOnly);
    final headings = ['Inicio', 'Registros', 'Central', 'Mi perfil'];

    final children = switch (tab) {
      0 => <Widget>[
        // Operator Hero Banner Card (High-End Industrial Design)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryContainer],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(10, 56, 126, 0.22),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            s.name.isNotEmpty
                                ? s.name
                                      .split(' ')
                                      .map((w) => w[0])
                                      .take(2)
                                      .join()
                                : 'OP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OPERARIO DE RECEPCIÓN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'ID OP-${s.userId} • Turno Activo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Sesión autorizada',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.factory_outlined,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s.centerName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Centro de la cuenta',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Prominent High-Contrast Primary CTA: Nueva Recepción
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F4799), Color(0xFF1E60E6)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(30, 96, 230, 0.3),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: !vm.ready || vm.busy
                  ? null
                  : () => push(CaptureView(session: s)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Nueva recepción',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Captura de cisterna, tara y muestras',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 24,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Local Sync & Telemetry Panel (2 Metric Cards)
        SectionCard(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.cloud_sync_outlined,
                    size: 16,
                    color: AppColors.primaryContainer,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Registros locales almacenados en este celular (no acumulados de otros equipos).',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final singleCol = constraints.maxWidth < 360 || scale > 1.25;
                final cardWidth = singleCol
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // Card 1: Pendientes de envío
                    SizedBox(
                      width: cardWidth,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: vm.pending > 0
                                ? AppColors.pendingBorder
                                : AppColors.border,
                            width: vm.pending > 0 ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'PENDIENTES',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: vm.pending > 0
                                        ? AppColors.pendingText
                                        : AppColors.approvedText,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text(
                                  '${vm.pending}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const Text(
                                  'lotes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vm.pending > 0
                                  ? 'Requiere envío manual'
                                  : 'Todo sincronizado',
                              style: TextStyle(
                                fontSize: 11,
                                color: vm.pending > 0
                                    ? AppColors.pendingText
                                    : AppColors.approvedText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => setState(() {
                                tab = 1;
                                pendingOnly = true;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  children: const [
                                    Text(
                                      'Ver pendientes',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryContainer,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 14,
                                      color: AppColors.primaryContainer,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Card 2: En equipo hoy
                    SizedBox(
                      width: cardWidth,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: const [
                                Text(
                                  'EN EQUIPO HOY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Icon(
                                  Icons.smartphone_rounded,
                                  size: 14,
                                  color: AppColors.secondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text(
                                  '${vm.lots.length}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryContainer,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const Text(
                                  'recep.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Aprox. ${number(vm.liters)} L',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                children: const [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 12,
                                    color: AppColors.approvedText,
                                  ),
                                  Text(
                                    'Balanza calibrada',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),

        // Operational Modules Grid (3 quick tiles)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: const Text(
            'MÓDULOS OPERATIVOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final single = c.maxWidth < 340 || scale > 1.25;
            final tileW = single ? c.maxWidth : (c.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: tileW,
                  child: _moduleTile(
                    Icons.science_outlined,
                    'Calidad',
                    'Laboratorio',
                    () => push(CentralView(session: s, mode: 'calidad')),
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: _moduleTile(
                    Icons.storage_outlined,
                    'Tanques',
                    'Capacidad',
                    () => push(CentralView(session: s, mode: 'tanque')),
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: _moduleTile(
                    Icons.qr_code_scanner_rounded,
                    'Trazabilidad',
                    'Buscar o QR',
                    () => push(CentralView(session: s, mode: 'trazabilidad')),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Recent Receptions Section
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Últimas recepciones',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Registradas en este dispositivo móvil',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => setState(() => tab = 1),
              icon: const Text('Historial'),
              label: const Icon(Icons.arrow_forward_rounded, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (vm.recovered)
          const Notice(
            'Tienes una recepción en edición. Abre Nueva recepción para continuar.',
          ),
        if (vm.lots.isEmpty)
          const Notice('Aún no tienes recepciones guardadas en este celular.'),
        ...vm.lots.take(3).map(lotCard),
      ],

      1 => <Widget>[
        // Local Queue Active Banner (Google Stitch specification)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'COLA LOCAL ACTIVA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            'Almacenamiento en equipo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      '${vm.pending} en cola',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Lotes almacenados localmente pendientes de confirmar envío al servidor central.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (vm.pending > 0)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: syncingAll || vm.busy ? null : () => syncAll(vm),
                  icon: syncingAll
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 20),
                  label: Text(
                    syncingAll
                        ? 'Enviando ${vm.syncProcessed} de ${vm.syncTotal}…'
                        : 'Sincronizar pendientes (${vm.pending})',
                  ),
                ),
            ],
          ),
        ),

        // Search Bar with Clean Elevation
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.04),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            key: const Key('local-search'),
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              labelText: 'Buscar proveedor, placa o cisterna...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() => query = ''),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filter Chips (Horizontal)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                selected: !pendingOnly,
                label: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    const Text('Todos'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: !pendingOnly
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '${vm.lots.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: !pendingOnly
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                onSelected: (_) => setState(() => pendingOnly = false),
                selectedColor: AppColors.primaryContainer,
                labelStyle: TextStyle(
                  color: !pendingOnly ? Colors.white : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                  side: BorderSide(
                    color: !pendingOnly
                        ? AppColors.primaryContainer
                        : AppColors.border,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: pendingOnly,
                label: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.pendingText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Text('Pendientes'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: pendingOnly
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '${vm.pending}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: pendingOnly
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                onSelected: (_) => setState(() => pendingOnly = true),
                selectedColor: AppColors.primaryContainer,
                labelStyle: TextStyle(
                  color: pendingOnly ? Colors.white : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                  side: BorderSide(
                    color: pendingOnly
                        ? AppColors.primaryContainer
                        : AppColors.border,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Summary Bar
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              '${filtered.length} registros',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              'Total: ${number(filtered.fold<int>(0, (n, l) => n + (l.volume * 100).round()) / 100)} L',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const Notice('No hay recepciones que coincidan con la búsqueda.'),
        ...filtered.map(lotCard),
      ],

      2 => <Widget>[
        // Central View Menu
        SectionCard(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.hub_outlined,
                    size: 22,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.centerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const Text(
                        'Servicios centrales y trazabilidad en servidor',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        _menu(
          Icons.qr_code_scanner_rounded,
          'Trazabilidad',
          'Consulta por UUID o escanea un comprobante QR',
          () => push(CentralView(session: s)),
        ),
        _menu(
          Icons.fact_check_outlined,
          'Calidad',
          'Evaluaciones confirmadas y reglas del servidor',
          () => push(CentralView(session: s, mode: 'calidad')),
        ),
        _menu(
          Icons.storage_outlined,
          'Tanques',
          'Consulta silos disponibles y asigna destino',
          () => push(CentralView(session: s, mode: 'tanque')),
        ),
        _menu(
          Icons.menu_book_outlined,
          'Catálogos',
          'Proveedores, vehículos y centro asignado',
          () => push(CatalogView(session: s)),
        ),
      ],

      _ => <Widget>[
        // Profile Section
        SectionCard(
          children: [
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    s.name.isNotEmpty
                        ? s.name.split(' ').map((w) => w[0]).take(2).join()
                        : 'OP',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSecondaryFixed,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              s.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Operario • ${s.centerName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pendientes en este celular',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: vm.pending > 0
                          ? AppColors.pendingContainer
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      '${vm.pending}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: vm.pending > 0
                            ? AppColors.pendingText
                            : AppColors.primaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _menu(
          Icons.menu_book_outlined,
          'Catálogos',
          'Datos descargados disponibles para registrar',
          () => push(CatalogView(session: s)),
        ),
        _menu(
          Icons.wifi_tethering_rounded,
          'Conexión',
          'Comprueba el acceso a los servicios de backend',
          () => push(const ConnectionView()),
        ),
        if (ref.watch(authProvider).error != null)
          Notice(ref.watch(authProvider).error!, error: true),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.rejectedText,
            side: const BorderSide(color: AppColors.rejectedBorder, width: 1.5),
            backgroundColor: Colors.white,
          ),
          onPressed: vm.busy ? null : () => logout(vm),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
      ],
    };

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACOPIO CAMPO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  headings[tab],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar registros locales',
            onPressed: vm.busy
                ? null
                : () async {
                    await vm.refresh();
                    await ref.read(connectionProvider).check();
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await vm.refresh();
            await ref.read(connectionProvider).check();
          },
          child: PageBody(
            children: [
              const ConnectionStatus(),
              if (tab == 0 || tab == 1)
                Notice(
                  'Datos de este celular y de tu cuenta. El dashboard muestra los lotes recibidos por el servidor del centro. Lectura local: ${vm.localReadAt == null ? 'pendiente' : dateLabel(vm.localReadAt!.toIso8601String())}.',
                ),
              if (vm.lastSync != null && (tab == 0 || tab == 1))
                SectionCard(
                  children: [
                    const Text(
                      'Resultado del último envío conjunto',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Notice(
                      vm.lastSync!.message,
                      warning: vm.lastSync!.failures.isNotEmpty,
                    ),
                    const Text(
                      'Enviado confirma la recepción en el servidor. Aprobado o rechazado indica el resultado de calidad.',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Finalizado: ${dateLabel(vm.lastSync!.finishedAt.toIso8601String())}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    ...vm.lastSync!.failures.entries.map(
                      (failure) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Lote ${failure.key}: ${failure.value}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (vm.lastSync!.failures.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: vm.busy || syncingAll
                            ? null
                            : () => syncAll(vm),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar pendientes'),
                      ),
                  ],
                ),
              if (vm.busy) const LinearProgressIndicator(),
              if (vm.error != null) Notice(vm.error!, error: true),
              if (!vm.ready && !vm.busy)
                FilledButton(
                  onPressed: vm.initialize,
                  child: const Text('Reintentar recuperación'),
                ),
              ...children,
            ],
          ),
        ),
      ),
      floatingActionButton: tab == 1
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: !vm.ready || vm.busy
                  ? null
                  : () => push(CaptureView(session: s)),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nueva recepción',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Registros',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub_rounded),
            label: 'Central',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _moduleTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: action,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.03),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryContainer),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _menu(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(15, 23, 42, 0.03),
          blurRadius: 6,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 22, color: AppColors.primaryContainer),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.outline,
      ),
      onTap: action,
    ),
  );
}
