import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Lee un QR con la cámara y devuelve el texto a Trazabilidad.
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
