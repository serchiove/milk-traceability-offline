import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'views/login_view.dart';
import 'views/shell_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AcopioApp()));
}

class AcopioApp extends StatelessWidget {
  const AcopioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ACOPIO Flutter',
    debugShowCheckedModeBanner: false,
    theme: acopioTheme(),
    locale: const Locale('es', 'PE'),
    supportedLocales: const [Locale('es', 'PE')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const AuthGate(),
  );
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.session == null
        ? const LoginView()
        : ShellView(key: ValueKey(auth.session!.key), session: auth.session!);
  }
}
