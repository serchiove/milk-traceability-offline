import 'package:flutter/material.dart';
import '../models/session.dart';
import '../core/app_colors.dart';
import 'central_view.dart';
import 'components/menu_action.dart';
import 'components/section_intro.dart';

/// Menú de funciones del centro: cada acceso explica su propósito.
class CentralMenuView extends StatelessWidget {
  final Session session;
  final ValueChanged<Widget> onNavigate;
  const CentralMenuView({
    super.key,
    required this.session,
    required this.onNavigate,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SectionIntro(
        eyebrow: 'CONSULTAS DEL CENTRO',
        title: 'Control y trazabilidad',
        description:
            'Consulta recepciones confirmadas y su destino. Requiere conexión al servidor.',
        icon: Icons.hub_outlined,
      ),
      MenuAction(
        title: 'Trazabilidad',
        description:
            'Encuentra el origen y el recorrido de una recepción por UUID o QR.',
        icon: Icons.qr_code_scanner,
        onTap: () =>
            onNavigate(CentralView(session: session, mode: 'trazabilidad')),
      ),
      MenuAction(
        title: 'Calidad',
        description:
            'Revisa mediciones, resultado e incidencias de la evaluación.',
        accent: AppColors.primaryLight,
        icon: Icons.science_outlined,
        onTap: () => onNavigate(CentralView(session: session, mode: 'calidad')),
      ),
      MenuAction(
        title: 'Tanques',
        description:
            'Asigna una recepción aprobada a un tanque con capacidad disponible.',
        accent: AppColors.pendingText,
        icon: Icons.storage_outlined,
        onTap: () => onNavigate(CentralView(session: session, mode: 'tanque')),
      ),
    ],
  );
}
