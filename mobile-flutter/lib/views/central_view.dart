import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../models/session.dart';
import '../viewmodels/app_viewmodels.dart';
import 'widgets.dart';

class CentralView extends ConsumerStatefulWidget {
  final Session session;
  final String mode;
  final String? initialCode;
  const CentralView({
    super.key,
    required this.session,
    this.mode = 'trazabilidad',
    this.initialCode,
  });
  @override
  ConsumerState<CentralView> createState() => _CentralState();
}

class _CentralState extends ConsumerState<CentralView> {
  late final CentralViewModel vm;
  final code = TextEditingController();

  @override
  void initState() {
    super.initState();
    vm = CentralViewModel(
      widget.session,
      ref.read(centralServiceProvider),
      approvedOnly: widget.mode == 'tanque',
    );
    if (widget.initialCode != null) {
      code.text = widget.initialCode!;
      vm.open(code.text);
    } else {
      vm.load();
    }
  }

  @override
  void dispose() {
    vm.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> scan() async {
    final value = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerView()),
    );
    if (value != null && mounted) {
      code.text = value;
      await vm.open(value);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) {
      final d = vm.detail;
      return PopScope(
        canPop: !vm.assigning,
        child: Scaffold(
          appBar: AppBar(
            title: Text(switch (widget.mode) {
              'calidad' => 'Calidad',
              'tanque' => 'Asignar tanque',
              _ => 'Trazabilidad',
            }),
            actions: [
              IconButton(
                tooltip: 'Actualizar datos del servidor',
                onPressed: vm.busy
                    ? null
                    : () => vm.detail != null
                          ? vm.open(vm.code)
                          : vm.load(vm.page),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: PageBody(
              children: [
                Notice(
                  'Datos del servidor para ${widget.session.centerName}. Última consulta correcta: ${vm.updatedAt == null ? 'pendiente' : dateLabel(vm.updatedAt!.toIso8601String())}. Requiere conexión.',
                  warning: vm.error != null,
                ),
                // Plant Info Mini Header
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.factory_outlined,
                        size: 16,
                        color: AppColors.primaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.session.centerName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search & Scan Bar
                TextField(
                  controller: code,
                  enabled: !vm.busy,
                  decoration: InputDecoration(
                    labelText: 'UUID o código ACOPIO',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: code.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              code.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (v) => vm.open(v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 46),
                        ),
                        onPressed: vm.busy ? null : () => vm.open(code.text),
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Buscar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                        ),
                        onPressed: vm.busy ? null : scan,
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 18,
                        ),
                        label: const Text('Escanear QR'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (vm.error != null) ...[
                  Notice(vm.error!, error: true),
                  OutlinedButton.icon(
                    onPressed: vm.busy
                        ? null
                        : () => vm.code.isNotEmpty
                              ? vm.open(vm.code)
                              : vm.load(vm.page),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reintentar consulta'),
                  ),
                  const SizedBox(height: 10),
                ],

                if (vm.busy) const LinearProgressIndicator(),

                // Visualización de detalle de lote consultado
                if (d != null) ...[
                  SectionCard(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StateBadge(d['estadoEvaluacion']),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              d['placa'] ?? 'CISTERNA',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        d['proveedor'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: AppColors.outline,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateLabel(d['fechaHora']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Operario: ${d['operario'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${d['centro'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Metrics([
                    ('Volumen', '${number(d['volumenLitros'])} L'),
                    ('Temperatura', '${number(d['temperaturaC'], 1)} °C'),
                    ('Acidez', '${number(d['acidezDornic'], 1)} °D'),
                    ('Densidad', '${number(d['densidadGml'], 4)} g/mL'),
                  ]),
                  const SizedBox(height: 14),

                  Notice(
                    d['motivo'] ??
                        (d['estadoEvaluacion'] == 'APROBADO'
                            ? 'Cumple con todas las reglas de calidad fisicoquímica establecidas.'
                            : 'El servidor todavía no ha emitido un resultado final.'),
                    error: d['estadoEvaluacion'] == 'RECHAZADO',
                    warning: d['estadoEvaluacion'] == 'PENDIENTE',
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Motor de Reglas: ${d['versionReglas'] ?? 'Pendientes'}${(d['versionReglas'] ?? '').startsWith('DEMO') ? ' · Demostración académica' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tanque de destino
                  SectionCard(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.storage_rounded,
                                size: 18,
                                color: AppColors.primaryContainer,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tanque de destino',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (d['asignadoEn'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.approvedContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ASIGNADO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.approvedText,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        d['tanque'] ?? 'Sin asignar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: d['tanque'] != null
                              ? AppColors.primaryContainer
                              : AppColors.outline,
                        ),
                      ),
                      if (d['asignadoEn'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Fecha de asignación: ${dateLabel(d['asignadoEn'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (d['estadoEvaluacion'] == 'APROBADO' &&
                          d['idTanque'] == null) ...[
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: vm.busy ? null : () => vm.loadTanks(),
                          icon: const Icon(
                            Icons.propane_tank_outlined,
                            size: 18,
                          ),
                          label: const Text('Elegir tanque disponible'),
                        ),
                      ],
                    ],
                  ),

                  // Lista de tanques para asignación
                  if (vm.tanks != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: const Text(
                        'TANQUES DISPONIBLES EN PLANTA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (vm.tanks!.items.isEmpty)
                      const Notice(
                        'No hay tanques disponibles con capacidad suficiente en esta página.',
                      ),
                    ...vm.tanks!.items.map((t) {
                      final assigned = (t['volumenAsignadoLitros'] as num)
                          .toDouble();
                      final cap = (t['capacidadLitros'] as num).toDouble();
                      final disp = (t['disponibleLitros'] as num).toDouble();
                      final reqVolume = (d['volumenLitros'] as num).toDouble();
                      final sufficient = disp >= reqVolume;
                      final ratio = cap > 0
                          ? (assigned / cap).clamp(0.0, 1.0)
                          : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  t['codigo'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sufficient
                                        ? AppColors.approvedContainer
                                        : AppColors.rejectedContainer,
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Text(
                                    sufficient ? 'DISPONIBLE' : 'INSUFICIENTE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: sufficient
                                          ? AppColors.approvedText
                                          : AppColors.rejectedText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${number(disp)} L libres de ${number(cap)} L totales',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 8,
                                backgroundColor: AppColors.surfaceContainerLow,
                                valueColor: AlwaysStoppedAnimation(
                                  ratio > 0.85
                                      ? AppColors.rejectedText
                                      : AppColors.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: sufficient
                                    ? AppColors.primaryContainer
                                    : AppColors.outlineVariant,
                                minimumSize: const Size(double.infinity, 44),
                              ),
                              onPressed: vm.busy || !sufficient
                                  ? null
                                  : () async {
                                      if (await confirmAction(
                                        context,
                                        'Confirmar destino',
                                        '${number(d['volumenLitros'])} L al tanque ${t['codigo']}. La asignación no permite cambios posteriores.',
                                        action: 'Asignar',
                                      )) {
                                        await vm.assign(t['id']);
                                      }
                                    },
                              child: Text(
                                sufficient
                                    ? 'Confirmar destino (${t['codigo']})'
                                    : 'Capacidad insuficiente',
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Paging(
                      page: vm.tanks!.page,
                      total: vm.tanks!.total,
                      size: vm.tanks!.size,
                      busy: vm.busy,
                      go: vm.loadTanks,
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (d['estadoEvaluacion'] == 'APROBADO' &&
                      d['codigoQr'] != null)
                    LotQr(d['codigoQr']),

                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ExpansionTile(
                      title: const Text(
                        'Identificador único (UUID)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: SelectableText(
                            d['idLote'],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  OutlinedButton.icon(
                    onPressed: vm.busy ? null : () => vm.load(vm.page),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Volver a las recepciones'),
                  ),
                ] else ...[
                  // Lista central de recepciones del centro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.mode == 'tanque'
                            ? 'Recepciones aprobadas'
                            : 'Recepciones del centro',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Actualizar',
                        onPressed: vm.busy ? null : () => vm.load(vm.page),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (vm.list != null) ...[
                    if (vm.list!.items.isEmpty)
                      const Notice(
                        'No hay recepciones registradas en el servidor.',
                      ),
                    ...vm.list!.items.map(
                      (l) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: vm.busy
                              ? null
                              : () {
                                  code.text = l['idLote'];
                                  vm.open(l['idLote']);
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l['proveedor'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${number(l['volumenLitros'])} L',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Placa: ${l['placa'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    StateBadge(
                                      l['estadoEvaluacion'] ?? 'PENDIENTE',
                                      compact: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Paging(
                      page: vm.list!.page,
                      total: vm.list!.total,
                      size: vm.list!.size,
                      busy: vm.busy,
                      go: vm.load,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});
  @override
  State<ScannerView> createState() => _ScannerState();
}

class _ScannerState extends State<ScannerView> with WidgetsBindingObserver {
  final controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool read = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.hasCameraPermission) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      controller.start();
    } else if (state == AppLifecycleState.inactive) {
      controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Escanear Comprobante QR'),
      actions: [
        IconButton(
          tooltip: 'Linterna',
          onPressed: () => controller.toggleTorch(),
          icon: const Icon(Icons.flashlight_on_rounded),
        ),
      ],
    ),
    body: MobileScanner(
      controller: controller,
      onDetect: (capture) {
        if (read) {
          return;
        }
        for (final b in capture.barcodes) {
          if (b.rawValue != null) {
            read = true;
            controller.stop();
            Navigator.pop(context, b.rawValue);
            break;
          }
        }
      },
      errorBuilder: (context, error) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Cámara no disponible o permiso denegado. Habilita el permiso en ajustes o vuelve para escribir el código manualmente.',
          ),
        ),
      ),
    ),
  );
}
