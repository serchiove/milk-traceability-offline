import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/session.dart';
import 'catalog_view.dart';
import 'connection_view.dart';
import 'widgets.dart';
import 'components/menu_action.dart';
import 'components/section_intro.dart';

/// Identidad de la cuenta y herramientas de sesión.
class ProfileView extends StatelessWidget {
  final Session session;
  final int pending;
  final bool busy;
  final VoidCallback onLogout;
  final ValueChanged<Widget> onNavigate;
  final String? error;
  const ProfileView({
    super.key,
    required this.session,
    required this.pending,
    required this.busy,
    required this.onLogout,
    required this.onNavigate,
    this.error,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionIntro(
        eyebrow: 'CUENTA DE OPERARIO',
        title: session.name,
        description: session.centerName,
        icon: Icons.badge_outlined,
      ),
      Text(
        'Herramientas de trabajo',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      MenuAction(
        title: 'Catálogos',
        description:
            'Actualiza los proveedores y vehículos disponibles para registrar.',
        icon: Icons.menu_book_outlined,
        onTap: () => onNavigate(CatalogView(session: session)),
      ),
      MenuAction(
        title: 'Conexión',
        description:
            'Comprueba si el celular puede comunicarse con el servidor.',
        icon: Icons.wifi_tethering,
        onTap: () => onNavigate(const ConnectionView()),
      ),
      const SizedBox(height: 8),
      Text(
        'Sesión y almacenamiento',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text('Pendientes en este celular: $pending'),
      const SizedBox(height: 16),
      if (error != null) Notice(error!, error: true),
      OutlinedButton.icon(
        onPressed: busy ? null : onLogout,
        icon: const Icon(Icons.logout),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.rejectedText,
        ),
        label: const Text('Cerrar sesión'),
      ),
      const SizedBox(height: 8),
      const Text(
        'Cerrar sesión conserva los registros y la edición en este celular.',
      ),
    ],
  );
}
