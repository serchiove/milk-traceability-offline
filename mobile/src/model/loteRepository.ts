import * as SQLite from 'expo-sqlite';
import type { DatosLote, FormularioLote, LoteLocal } from './lote';
import type { EnvioLocal, ResultadoEnvio, SolicitudLote } from './envio';
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
  await db.execAsync(`CREATE TABLE IF NOT EXISTS envio_lote_v1 (
    id TEXT PRIMARY KEY NOT NULL, usuario INTEGER NOT NULL, centro INTEGER NOT NULL,
    solicitud TEXT NOT NULL, resultado TEXT
  )`);
  await db.execAsync(`CREATE TABLE IF NOT EXISTS configuracion_local_v1 (clave TEXT PRIMARY KEY NOT NULL, contenido TEXT NOT NULL)`);
  await db.execAsync(`CREATE TABLE IF NOT EXISTS edicion_operario_v1 (clave TEXT PRIMARY KEY NOT NULL, formulario TEXT NOT NULL)`);
  return db;
}
export async function leerConfiguracion<T>(clave:string):Promise<T|null>{
  const db=await obtenerDb();const row=await db.getFirstAsync<{contenido:string}>('SELECT contenido FROM configuracion_local_v1 WHERE clave=?',clave);return row?JSON.parse(row.contenido):null;
}
export function guardarConfiguracion(clave:string,valor:unknown):Promise<void>{return enCola(async()=>{const db=await obtenerDb();await db.runAsync('INSERT INTO configuracion_local_v1(clave,contenido) VALUES(?,?) ON CONFLICT(clave) DO UPDATE SET contenido=excluded.contenido',clave,JSON.stringify(valor));});}
export type ContextoCaptura={usuario:number;centro:number;idProveedor:number;idVehiculo:number;clave:string};
export async function leerEnvio(id: string): Promise<EnvioLocal | null> {
  const db = await obtenerDb();
  const fila = await db.getFirstAsync<{id: string; usuario: number; centro: number; solicitud: string; resultado: string | null}>('SELECT * FROM envio_lote_v1 WHERE id = ?', id);
  return fila ? {...fila, solicitud: JSON.parse(fila.solicitud), resultado: fila.resultado ? JSON.parse(fila.resultado) : null} : null;
}
// La identidad y el cuerpo quedan congelados antes del primer intento HTTP.
export function prepararEnvio(solicitud: SolicitudLote, usuario: number, centro: number): Promise<EnvioLocal> {
  return enCola(async () => {
    const db = await obtenerDb();
    await db.runAsync('INSERT OR IGNORE INTO envio_lote_v1(id, usuario, centro, solicitud) VALUES (?, ?, ?, ?)', solicitud.idLote, usuario, centro, JSON.stringify(solicitud));
    const envio = await leerEnvio(solicitud.idLote);
    if (!envio || envio.usuario !== usuario || envio.centro !== centro) throw new Error('Esta recepción está vinculada a otro operario o centro.');
    if (JSON.stringify(envio.solicitud) !== JSON.stringify(solicitud)) throw new Error('El envío ya está preparado. Reintenta con los datos originales.');
    return envio;
  });
}
export function confirmarEnvio(id: string, resultado: ResultadoEnvio): Promise<void> {
  return enCola(async () => {
    const db = await obtenerDb();
    await db.runAsync('UPDATE envio_lote_v1 SET resultado = ? WHERE id = ?', JSON.stringify(resultado), id);
  });
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
  const lotes = await db.getAllAsync<LoteLocal>('SELECT * FROM borrador_lote_v1 ORDER BY fecha DESC, id DESC');
  const enviados = await db.getAllAsync<{id: string}>('SELECT id FROM envio_lote_v1 WHERE resultado IS NOT NULL');
  const ids = new Set(enviados.map(fila => fila.id));
  return lotes.map(lote => ids.has(lote.id) ? {...lote, enviado: true} : lote);
}
// Serialize edition writes and confirmation so an older autosave cannot revive a saved form.
let escritura: Promise<unknown> = Promise.resolve();
function enCola<T>(accion: () => Promise<T>): Promise<T> {
  const tarea = escritura.then(accion);
  escritura = tarea.catch(() => undefined);
  return tarea;
}
export async function leerEdicion(clave?:string): Promise<FormularioLote | null> {
  const db = await obtenerDb();
  const fila = clave ? await db.getFirstAsync<{formulario:string}>('SELECT formulario FROM edicion_operario_v1 WHERE clave=?',clave) : await db.getFirstAsync<{formulario: string}>('SELECT formulario FROM recepcion_en_edicion_v1 WHERE id = 1');
  if (!fila) return null;
  const datos: unknown = JSON.parse(fila.formulario);
  const campos = ['proveedor', 'vehiculo', 'centro', 'volumen', 'temperatura', 'acidez', 'densidad'] as const;
  if (!datos || typeof datos !== 'object' || !campos.every(campo => typeof (datos as Record<string, unknown>)[campo] === 'string')) {
    throw new Error('No se pudo recuperar la recepción en edición');
  }
  return {...Object.fromEntries(campos.map(campo => [campo, (datos as FormularioLote)[campo]])), ...Object.fromEntries(['idProveedor','idVehiculo'].filter(campo=>typeof (datos as Record<string,unknown>)[campo]==='string').map(campo=>[campo,(datos as Record<string,unknown>)[campo]]))} as FormularioLote;
}
export function guardarEdicion(form: FormularioLote, clave?:string): Promise<void> {
  const contenido = JSON.stringify(form);
  const vacio = Object.values(form).every(valor => !valor.trim());
  return enCola(async () => {
    const db = await obtenerDb();
    if(clave){
      if(vacio) await db.runAsync('DELETE FROM edicion_operario_v1 WHERE clave=?',clave);
      else await db.runAsync('INSERT INTO edicion_operario_v1(clave,formulario) VALUES(?,?) ON CONFLICT(clave) DO UPDATE SET formulario=excluded.formulario',clave,contenido);
      return;
    }
    if (vacio) await db.runAsync('DELETE FROM recepcion_en_edicion_v1 WHERE id = 1');
    else await db.runAsync('INSERT INTO recepcion_en_edicion_v1(id, formulario) VALUES (1, ?) ON CONFLICT(id) DO UPDATE SET formulario = excluded.formulario', contenido);
  });
}
export function guardarLote(datos: DatosLote, contexto?:ContextoCaptura): Promise<LoteLocal> {
  return enCola(() => confirmarLote(datos, contexto));
}
async function confirmarLote(datos: DatosLote, contexto?:ContextoCaptura): Promise<LoteLocal> {

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
    if(contexto){
      const solicitud:SolicitudLote={idLote:lote.id,idProveedor:contexto.idProveedor,idVehiculo:contexto.idVehiculo,fechaHora:lote.fecha,volumenLitros:lote.volumen,mediciones:{temperaturaC:lote.temperatura,acidezDornic:lote.acidez,densidadGml:lote.densidad}};
      await db.runAsync('INSERT INTO envio_lote_v1(id,usuario,centro,solicitud) VALUES(?,?,?,?)',lote.id,contexto.usuario,contexto.centro,JSON.stringify(solicitud));
      await db.runAsync('DELETE FROM edicion_operario_v1 WHERE clave=?',contexto.clave);
    }else await db.runAsync('DELETE FROM recepcion_en_edicion_v1 WHERE id = 1');
    await db.execAsync('COMMIT');
  } catch (error) {
    await db.execAsync('ROLLBACK');
    throw error;
  }

  return lote;
}
