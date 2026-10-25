import test from 'node:test';
import assert from 'node:assert/strict';
import { periodRange, selectedPeriod } from '../src/filters.js';

test('hoy usa la fecha local incluso al final del día', () => {
  const now = new Date(2026, 9, 24, 23, 59);
  assert.deepEqual(periodRange('today', now), { from: '2026-10-24', to: '2026-10-24' });
});

test('siete días incluye hoy y cruza el año', () => {
  const now = new Date(2026, 0, 3);
  assert.deepEqual(periodRange('week', now), { from: '2025-12-28', to: '2026-01-03' });
});

test('treinta días contempla febrero bisiesto', () => {
  const now = new Date(2024, 2, 1);
  assert.deepEqual(periodRange('month', now), { from: '2024-02-01', to: '2024-03-01' });
});

test('historial completo no añade límites y las fechas manuales se reconocen', () => {
  const now = new Date(2026, 9, 24);
  assert.deepEqual(periodRange('all', now), { from: '', to: '' });
  assert.equal(selectedPeriod('', '', now), 'all');
  assert.equal(selectedPeriod('2026-10-18', '2026-10-24', now), 'week');
  assert.equal(selectedPeriod('2026-10-01', '', now), 'custom');
  assert.throws(() => periodRange('custom', now));
});
