import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../models/lot.dart';
import '../models/session.dart';
import 'widgets.dart';
import 'central_view.dart';

class LocalDetailView extends ConsumerStatefulWidget {
  final Session session;
  final LocalLot lot;
  const LocalDetailView({super.key, required this.session, required this.lot});
  @override
  ConsumerState<LocalDetailView> createState() => _DetailState();
}

class _DetailState extends ConsumerState<LocalDetailView> {
  PreparedSend? prepared;
  String? readError;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final p = await ref.read(localProvider).send(widget.lot.id);
      if (mounted) {
        setState(() {
          prepared = p;
          loading = false;
          readError = p == null ? 'No se pudo leer el envío.' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          readError = e.toString();
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(workspaceProvider(widget.session)), l = widget.lot;
    final result = prepared?.result;
    final own =
        prepared?.user == widget.session.userId &&
        prepared?.center == widget.session.centerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle local'),
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            // Code ID & Quick Status Tag (Google Stitch specification)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 15,
                        color: AppColors.primaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'REC-${l.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryContainer,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.localContainer,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppColors.localBorder),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.smartphone_rounded,
                        size: 13,
                        color: AppColors.localText,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Almacenamiento Local',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.localText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dual Status Sync Banner
            if (result == null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.pendingContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.pendingBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cloud_off_rounded,
                            size: 20,
                            color: AppColors.pendingText,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              StateBadge('PENDIENTE DE ENVÍO', compact: true),
                              SizedBox(height: 4),
                              Text(
                                'Este registro solo existe en este dispositivo móvil. No ha sido recibido aún por el servidor de planta.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.serverContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.serverBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cloud_done_rounded,
                            size: 20,
                            color: AppColors.serverText,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const StateBadge('RECIBIDO POR SERVIDOR', compact: true),
                                  const SizedBox(width: 6),
                                  StateBadge(result.state, compact: true),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Confirmado por el servidor central. Reglas: ${result.json['versionReglas'] ?? 'V1.0'}',
                                style: const TextStyle(
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
              ),

            // Origin & Logistics Card (Stitch specification)
            SectionCard(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.factory_outlined,
                            size: 16,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CENTRO DE ACOPIO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              l.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Proveedor Mini-Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROVEEDOR GANADERO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.supplier,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Logistics Grid (2 columns)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  size: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Vehículo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.vehicle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.badge_outlined,
                                  size: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Operario',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.session.name.split(' ').first,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppColors.outline,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel(l.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Physical Measurements Grid
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: const Text(
                'MEDICIONES FÍSICO-QUÍMICAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Metrics([
              ('Volumen', '${number(l.volume)} L'),
              ('Temperatura', '${number(l.temperature, 1)} °C'),
              ('Acidez', '${number(l.acidity, 1)} °D'),
              ('Densidad', '${number(l.density, 4)} g/mL'),
            ]),
            const SizedBox(height: 16),

            if (loading) const LinearProgressIndicator(),
            if (readError != null) ...[
              Notice(readError!, error: true),
              OutlinedButton(
                onPressed: load,
                child: const Text('Reintentar lectura'),
              ),
              const SizedBox(height: 10),
            ],
            if (vm.error != null) Notice(vm.error!, error: true),

            // Server Result Details & Actions
            if (result != null) ...[
              if (result.json['motivo'] != null)
                Notice(
                  'Motivo de evaluación: ${result.json['motivo']}',
                  error: result.state == 'RECHAZADO',
                  warning: result.state == 'PENDIENTE',
                ),
              if (result.state == 'APROBADO' && result.qr != null)
                LotQr(result.qr!),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CentralView(session: widget.session, initialCode: l.id),
                  ),
                ),
                icon: const Icon(Icons.storage_rounded, size: 18),
                label: const Text('Consultar estado y tanque en el servidor'),
              ),
            ] else if (!loading && prepared != null) ...[
              if (!own)
                const Notice(
                  'Esta recepción pertenece a otro operario o centro.',
                  error: true,
                ),
              FilledButton.icon(
                key: const Key('send-lot'),
                onPressed: vm.busy || !own
                    ? null
                    : () async {
                        if (await confirmAction(
                          context,
                          'Confirmar envío',
                          '${l.supplier}\n${l.vehicle}\n${widget.session.name} · ${widget.session.centerName}\n\nEl servidor registrará y evaluará esta recepción.',
                          action: 'Enviar',
                        )) {
                          await vm.send(l);
                          await load();
                        }
                      },
                icon: const Icon(Icons.cloud_upload_rounded),
                label: Text(vm.busy ? 'Enviando…' : 'Enviar al servidor'),
              ),
            ],

            const SizedBox(height: 14),

            // UUID Technical Detail (collapsible)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: ExpansionTile(
                title: const Text(
                  'Identificador del registro (UUID)',
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
                      l.id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
