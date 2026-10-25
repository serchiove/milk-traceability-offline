import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import 'widgets.dart';

class ConnectionView extends ConsumerWidget {
  const ConnectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(connectionProvider);
    final busy = vm.checking, connected = vm.online;
    final message =
        '${vm.message}${vm.checkedAt == null ? '' : ' Comprobación: ${dateLabel(vm.checkedAt!.toIso8601String())}.'}';
    return Scaffold(
      appBar: AppBar(title: const Text('Conexión con Servidor')),
      body: SafeArea(
        child: PageBody(
          children: [
            // Connection status card
            SectionCard(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: connected == true
                            ? AppColors.approvedContainer
                            : connected == false
                            ? AppColors.rejectedContainer
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        connected == true
                            ? Icons.cloud_done_rounded
                            : connected == false
                            ? Icons.cloud_off_rounded
                            : Icons.wifi_tethering_rounded,
                        color: connected == true
                            ? AppColors.approvedText
                            : connected == false
                            ? AppColors.rejectedText
                            : AppColors.primaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            connected == true
                                ? 'CONECTADO AL BACKEND'
                                : connected == false
                                ? 'SIN RESPUESTA'
                                : 'ESTADO DE CONEXIÓN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: connected == true
                                  ? AppColors.approvedText
                                  : connected == false
                                  ? AppColors.rejectedText
                                  : AppColors.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: busy ? null : vm.check,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    busy ? 'Comprobando…' : 'Comprobar servidor ahora',
                  ),
                ),
              ],
            ),

            // Technical connection details card
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.settings_ethernet_rounded,
                  color: AppColors.primaryContainer,
                ),
                title: const Text(
                  'Configuración de conexión',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'URL Base configurada:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: SelectableText(
                            AppConfig.apiUrl,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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

            const Notice(
              'Los borradores y registros locales siguen disponibles en este equipo sin conexión. Para enviar a planta o consultar tanques se requiere enlace activo con el servidor.',
            ),
          ],
        ),
      ),
    );
  }
}
