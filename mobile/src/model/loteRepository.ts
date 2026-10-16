import * as SQLite from 'expo-sqlite';
import type { DatosLote, FormularioLote, LoteLocal } from './lote';
// Tabla separada del diagnóstico. Son borradores locales, todavía sin catálogos autenticados.
let conexion: ReturnType<typeof abrir> | undefined;
async function abrir() {
  const db = await SQLite.openDatabaseAsync('acopio_desarrollo.db');
  await db.execAsync(`CREATE TABLE IF NOT EXISTS borrador_lote_v1 (
    id TEXT PRIMARY KEY NOT NULL, fecha TEXT NOT NULL,
    proveedor TEXT NOT NULL, vehiculo TEXT NOT NULL, centro TEXT NOT NULL,
    volumen REAL NOT NULL CHECK(volumen > 0), temperatura REAL NOT NULL,
    acidez REAL NOT NULL CHECK(acidez >= 0), densidad REAL NOT NULL CHECK(densidad > 0)
  )`);
  await db.execAsync(`CREATE TABLE IF NOT EXISTS recepcion_en_edicion_v1 (
    id INTEGER PRIMARY KEY CHECK (id = 1), formulario TEXT NOT NULL
  )`);
  return db;
}
async function obtenerDb() {
  if(!conexion)
    conexion = abrir().catch(error => { conexion = undefined; throw error; });
  return conexion;
}
export async function prepararAlmacenamiento(): Promise<void> {
  await obtenerDb();
}
export async function listarLotes(): Promise<LoteLocal[]> {
  const db = await obtenerDb();
  return db.getAllAsync<LoteLocal>('SELECT * FROM borrador_lote_v1 ORDER BY fecha DESC, id DESC');
}
// Serialize edition writes and confirmation so an older autosave cannot revive a saved form.
let escritura: Promise<unknown> = Promise.resolve();
function enCola<T>(accion: () => Promise<T>): Promise<T> {
  const tarea = escritura.then(accion);
  escritura = tarea.catch(() => undefined);
  return tarea;
}
export async function leerEdicion(): Promise<FormularioLote | null> {
  const db = await obtenerDb();
  const fila = await db.getFirstAsync<{formulario: string}>('SELECT formulario FROM recepcion_en_edicion_v1 WHERE id = 1');
  if (!fila) return null;
  const datos: unknown = JSON.parse(fila.formulario);
  const campos = ['proveedor', 'vehiculo', 'centro', 'volumen', 'temperatura', 'acidez', 'densidad'] as const;
  if (!datos || typeof datos !== 'object' || !campos.every(campo => typeof (datos as Record<string, unknown>)[campo] === 'string')) {
    throw new Error('No se pudo recuperar la recepción en edición');
  }
  return Object.fromEntries(campos.map(campo => [campo, (datos as FormularioLote)[campo]])) as FormularioLote;
}
export function guardarEdicion(form: FormularioLote): Promise<void> {
  const contenido = JSON.stringify(form);
  const vacio = Object.values(form).every(valor => !valor.trim());
  return enCola(async () => {
    const db = await obtenerDb();
    if (vacio) await db.runAsync('DELETE FROM recepcion_en_edicion_v1 WHERE id = 1');
    else await db.runAsync('INSERT INTO recepcion_en_edicion_v1(id, formulario) VALUES (1, ?) ON CONFLICT(id) DO UPDATE SET formulario = excluded.formulario', contenido);
  });
}
export function guardarLote(datos: DatosLote): Promise<LoteLocal> {
  return enCola(() => confirmarLote(datos));
}
async function confirmarLote(datos: DatosLote): Promise<LoteLocal> {

  const db = await obtenerDb();
  const random = await db.getFirstAsync<{
    valor: string;
  }>('SELECT lower(hex(randomblob(16))) AS valor');
  if(!random)
    throw new Error('No se pudo generar el identificador');
  const hex = random.valor;
  const variante = ((parseInt(hex[16], 16) & 3) | 8).toString(16);
  const id = `${hex.slice(0, 8)}-${hex.slice(8, 12)}-4${hex.slice(13, 16)}-${variante}${hex.slice(17, 20)}-${hex.slice(20)}`;
  const lote = { ...datos, id, fecha: new Date().toISOString() };
  await db.execAsync('BEGIN TRANSACTION');
  try {
  await db.runAsync('INSERT INTO borrador_lote_v1(id, fecha, proveedor, vehiculo, centro, volumen, temperatura, acidez, densidad) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', lote.id, lote.fecha, lote.proveedor, lote.vehiculo, lote.centro, lote.volumen, lote.temperatura, lote.acidez, lote.densidad);
    await db.runAsync('DELETE FROM recepcion_en_edicion_v1 WHERE id = 1');
    await db.execAsync('COMMIT');
  } catch (error) {
    await db.execAsync('ROLLBACK');
    throw error;
  }

  return lote;
}
