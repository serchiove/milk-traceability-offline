import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import 'widgets.dart';

class ConnectionStatus extends ConsumerStatefulWidget {
  const ConnectionStatus({super.key});

  @override
  ConsumerState<ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends ConsumerState<ConnectionStatus>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) ref.read(connectionProvider).check();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(connectionProvider).check();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(connectionProvider);
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        Row(
          children: [
            Icon(
              vm.online == true
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              color: vm.checking || vm.online == null
                  ? AppColors.outline
                  : vm.online == true
                  ? AppColors.approvedText
                  : AppColors.pendingText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vm.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    vm.checkedAt == null
                        ? 'Comprobando acceso a la API'
                        : 'Comprobación: ${dateLabel(vm.checkedAt!.toIso8601String())}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Comprobar conexión',
              onPressed: vm.checking ? null : vm.check,
              icon: vm.checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
