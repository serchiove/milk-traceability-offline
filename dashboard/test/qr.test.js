import test from 'node:test';
import assert from 'node:assert/strict';
import { lotQrValue, createQrImage } from '../src/qr.js';

test('imagen QR PNG se genera desde el valor exacto confirmado por el servidor', async () => {
  const code = 'ACOPIO:d2f3de03-98c2-47c7-9cfb-3a68561a1ba2';
  const value = lotQrValue({ quality: 'APROBADO', raw: { codigoQr: code } });
  assert.equal(value, code);
  const image = await createQrImage(value);
  assert.ok(image.startsWith('data:image/png;base64,'));
  const bytes = Buffer.from(image.split(',')[1], 'base64');
  assert.deepEqual([...bytes.subarray(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
  assert.equal(bytes.readUInt32BE(16), 256);
  assert.equal(bytes.readUInt32BE(20), 256);
});

test('rechazados, pendientes y aprobados sin código no inventan un QR', async () => {
  for (const quality of ['RECHAZADO', 'PENDIENTE']) {
    assert.equal(lotQrValue({ quality, raw: { codigoQr: 'ACOPIO:ejemplo' } }), null);
  }
  assert.equal(lotQrValue({ quality: 'APROBADO', id: 'uuid', raw: {} }), null);
  await assert.rejects(createQrImage(''));
});
