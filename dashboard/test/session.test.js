import test from 'node:test';
import assert from 'node:assert/strict';
import { SESSION_KEY, tokenExpiresAt, readDashboardSession, saveDashboardSession, clearDashboardSession } from '../src/session.js';

const now = new Date('2026-10-24T18:00:00Z').getTime();
const token = exp => `header.${Buffer.from(JSON.stringify({ exp })).toString('base64url')}.signature`;
const session = () => ({ accessToken: token(now / 1000 + 3600), usuario: {
  id: 2, idCentro: 1, nombre: 'Jefatura de prueba', centro: 'Centro de prueba', rol: 'JEFATURA'
}, view: { page: 'traceability', activeLotId: 'lote-prueba', statusFilter: 'APROBADO', lotsPage: 2 } });
function memoryStorage() {
  const values = new Map();
  return { getItem: key => values.get(key) ?? null, setItem: (key, value) => values.set(key, value), removeItem: key => values.delete(key) };
}

test('recargar restaura sesión vigente, página, selección y filtros sin guardar contraseña', () => {
  const storage = memoryStorage();
  const original = session();
  assert.equal(saveDashboardSession({ ...original, password: 'no-guardar', usuario: { ...original.usuario, password: 'tampoco' } }, storage, now), true);
  const restored = readDashboardSession(storage, now);
  assert.equal(restored.accessToken, original.accessToken);
  assert.equal(restored.view.page, 'traceability');
  assert.equal(restored.view.activeLotId, 'lote-prueba');
  assert.equal(restored.view.statusFilter, 'APROBADO');
  assert.equal(restored.view.lotsPage, 2);
  assert.ok(!storage.getItem(SESSION_KEY).includes('password'));
});

test('sesión vencida se descarta incluso si estaba guardada previamente', () => {
  const storage = memoryStorage();
  saveDashboardSession(session(), storage, now);
  assert.equal(readDashboardSession(storage, now + 3600 * 1000), null);
  assert.equal(storage.getItem(SESSION_KEY), null);
});

test('JSON corrupto, JWT inválido y rol OPERARIO no restauran acceso de jefatura', () => {
  const storage = memoryStorage();
  for (const content of ['{', JSON.stringify({ ...session(), accessToken: 'invalid' }), JSON.stringify({ ...session(), usuario: { ...session().usuario, rol: 'OPERARIO' } })]) {
    storage.setItem(SESSION_KEY, content);
    assert.equal(readDashboardSession(storage, now), null);
    assert.equal(storage.getItem(SESSION_KEY), null);
  }
  assert.equal(tokenExpiresAt('header.eyJleHAiOiJzdHJpbmcifQ.signature'), 0);
});

test('cerrar sesión elimina la restauración después de F5', () => {
  const storage = memoryStorage();
  saveDashboardSession(session(), storage, now);
  clearDashboardSession(storage);
  assert.equal(readDashboardSession(storage, now), null);
});

test('almacenamiento bloqueado no provoca un fallo de la página', () => {
  const unavailable = { getItem() { throw new Error('blocked'); }, setItem() { throw new Error('blocked'); }, removeItem() { throw new Error('blocked'); } };
  assert.equal(readDashboardSession(unavailable, now), null);
  assert.equal(saveDashboardSession(session(), unavailable, now), false);
  assert.doesNotThrow(() => clearDashboardSession(unavailable));
});
