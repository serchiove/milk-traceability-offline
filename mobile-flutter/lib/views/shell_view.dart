import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../models/session.dart';
import '../models/lot.dart';
import '../viewmodels/workspace_view_model.dart';
import 'widgets.dart';
import 'capture_view.dart';
import 'local_detail_view.dart';
import 'connection_status.dart';
import 'home_view.dart';
import 'records_view.dart';
import 'central_menu_view.dart';
import 'profile_view.dart';
import 'components/sync_feedback.dart';

/// Contenedor de navegación. Cada pestaña tiene su propia clase de presentación.
class ShellView extends ConsumerStatefulWidget {
  final Session session;
  const ShellView({super.key, required this.session});
  @override
  ConsumerState<ShellView> createState() => _ShellState();
}

class _ShellState extends ConsumerState<ShellView> with WidgetsBindingObserver {
  int tab = 0;
  String query = '';
  bool pendingOnly = false, syncingAll = false;
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
  Future<void> refresh(WorkspaceViewModel vm) async {
    await vm.refresh();
    if (mounted) await ref.read(connectionProvider).check();
  }

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

  Future<void> logout(WorkspaceViewModel vm) async {
    if (!await confirmAction(
      context,
      'Cerrar sesión',
      'La edición y los registros permanecerán en este celular.',
    )) {
      return;
    }
    if (await vm.ensureEdition() && mounted) {
      await ref.read(authProvider).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(workspaceProvider(widget.session));
    final s = widget.session;
    const headings = ['Inicio', 'Registros', 'Central', 'Mi perfil'];
    final page = switch (tab) {
      0 => HomeView(
        session: s,
        vm: vm,
        onCapture: () => push(CaptureView(session: s)),
        onRecords: () => setState(() => tab = 1),
        onSend: () => syncAll(vm),
        onOpen: open,
      ),
      1 => RecordsView(
        vm: vm,
        query: query,
        pendingOnly: pendingOnly,
        onQuery: (v) => setState(() => query = v),
        onPending: (v) => setState(() => pendingOnly = v),
        onOpen: open,
        onSend: () => syncAll(vm),
      ),
      2 => CentralMenuView(session: s, onNavigate: push),
      _ => ProfileView(
        session: s,
        pending: vm.pending,
        busy: vm.busy,
        onLogout: () => logout(vm),
        onNavigate: push,
        error: ref.watch(authProvider).error,
      ),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(headings[tab]),
        actions: [
          IconButton(
            tooltip: 'Actualizar registros locales',
            onPressed: vm.busy ? null : () => refresh(vm),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => refresh(vm),
          child: PageBody(
            children: [
              const ConnectionStatus(),
              if (vm.busy) const LinearProgressIndicator(),
              if (vm.error != null) Notice(vm.error!, error: true),
              if (!vm.ready && !vm.busy)
                FilledButton(
                  onPressed: vm.initialize,
                  child: const Text('Reintentar recuperación'),
                ),
              if (vm.lastSync != null && tab < 2)
                SyncFeedback(
                  summary: vm.lastSync!,
                  onRetry: vm.busy ? null : () => syncAll(vm),
                ),
              page,
            ],
          ),
        ),
      ),
      floatingActionButton: tab == 1
          ? FloatingActionButton.extended(
              onPressed: vm.ready && !vm.busy
                  ? () => push(CaptureView(session: s))
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Nueva recepción'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Registros',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub),
            label: 'Central',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
