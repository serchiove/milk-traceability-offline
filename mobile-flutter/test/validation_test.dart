import 'package:flutter_test/flutter_test.dart';
import 'package:acopio_flutter/models/lot.dart';
import 'support.dart';

void main() {
  test('normaliza coma y acepta precisión y fronteras numéricas', () {
    expect(validateLot(validForm()), isEmpty);
    expect(
      validateLot({
        ...validForm(),
        'temperatura': '-273.15',
        'acidez': '0',
        'densidad': '999.9999',
        'volumen': '9999999999.99',
      }),
      isEmpty,
    );
  });
  test(
    'formulario vacío exige todos los campos',
    () => expect(validateLot(emptyForm()).length, 7),
  );
  test('rechaza orígenes vacíos y demasiado largos', () {
    for (final field in originFields) {
      for (final value in ['  ', 'a' * 181]) {
        expect(validateLot({...validForm(), field: value}), contains(field));
      }
    }
  });
  test('rechaza miles, exponentes, infinito y formatos ambiguos', () {
    for (final value in [
      '1,200.50',
      '1.200,50',
      '1e3',
      'Infinity',
      'NaN',
      'abc',
      '.5',
      '1.',
      '+2',
    ]) {
      expect(
        validateLot({...validForm(), 'volumen': value}),
        contains('volumen'),
        reason: value,
      );
    }
  });
  test('límites y precisión coinciden con el contrato de recepción', () {
    for (final pair in [
      ('volumen', '0'),
      ('volumen', '-1'),
      ('volumen', '10000000000'),
      ('temperatura', '-273.16'),
      ('temperatura', '10000'),
      ('acidez', '-1'),
      ('densidad', '0'),
      ('densidad', '1000'),
      ('volumen', '1.001'),
      ('temperatura', '4.001'),
      ('acidez', '16.001'),
      ('densidad', '1.03001'),
    ]) {
      expect(
        validateLot({...validForm(), pair.$1: pair.$2}),
        contains(pair.$1),
      );
    }
  });
  test('huella coincide con el vector canónico del backend Java', () {
    final r = LotRequest(
      id: 'f4a1ba39-6c18-411a-9657-859c301ded22',
      date: '2026-10-15T10:30:00-05:00',
      supplierId: 3,
      vehicleId: 4,
      volume: 120.50,
      temperature: 4,
      acidity: 16,
      density: 1.0300,
    );
    expect(
      r.canonical(1, 2),
      'f4a1ba39-6c18-411a-9657-859c301ded22|3|4|1|2|2026-10-15T15:30:00Z|120.5|4|16|1.03',
    );
    expect(
      r.fingerprint(1, 2),
      'f6f777f23c46bf673cdad744b12a5dcec09e2b4224f66358184dd5074cf01407',
    );
    expect(r.fingerprint(1, 2), isNot(r.fingerprint(2, 2)));
  });
  test('fechas conservan milisegundos y normalizan zona horaria', () {
    final r = LotRequest(
      id: 'id',
      date: '2026-10-15T10:30:00.120-05:00',
      supplierId: 1,
      vehicleId: 1,
      volume: 1,
      temperature: -0.0,
      acidity: 0,
      density: 0.0001,
    );
    expect(
      r.canonical(1, 1),
      'id|1|1|1|1|2026-10-15T15:30:00.120Z|1|0|0|0.0001',
    );
  });
  test('JWT expirado o malformado nunca habilita acceso offline', () {
    expect(session(expiry: 1).isValid, isFalse);
    expect(session().isValid, isTrue);
  });
}
