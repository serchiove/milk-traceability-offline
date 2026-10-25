import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:acopio_flutter/services/api_client.dart';
import 'package:acopio_flutter/viewmodels/connection_viewmodel.dart';
import 'support.dart';

void main() {
  test(
    'conexión refleja caída y recuperación de la API sin afirmar conexión inicial',
    () async {
      var connected = false;
      final api = ApiClient(
        client: MockClient((_) async {
          if (!connected) throw http.ClientException('offline');
          return response({'estado': 'CONECTADO'});
        }),
      );
      final vm = ConnectionViewModel(api);
      addTearDown(vm.dispose);
      addTearDown(api.close);
      expect(vm.online, isNull);
      await vm.check();
      expect(vm.online, isFalse);
      expect(vm.checkedAt, isNotNull);
      connected = true;
      await vm.check();
      expect(vm.online, isTrue);
    },
  );

  test(
    'respuesta HTTP sin estado conectado no confirma disponibilidad',
    () async {
      final api = ApiClient(
        client: MockClient((_) async => response({'estado': 'ERROR'})),
      );
      final vm = ConnectionViewModel(api);
      addTearDown(vm.dispose);
      addTearDown(api.close);
      await vm.check();
      expect(vm.online, isFalse);
    },
  );

  test(
    'doble comprobación y cierre durante petición no notifican después de dispose',
    () async {
      final pending = Completer<http.Response>();
      var calls = 0;
      final api = ApiClient(
        client: MockClient((_) {
          calls++;
          return pending.future;
        }),
      );
      addTearDown(api.close);
      final vm = ConnectionViewModel(api);
      final first = vm.check();
      await vm.check();
      vm.dispose();
      pending.complete(response({'estado': 'CONECTADO'}));
      await first;
      expect(calls, 1);
    },
  );
}
