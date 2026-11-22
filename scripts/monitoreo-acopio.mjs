// Monitor local de solo lectura. Ejecutar desde la raíz del proyecto con Node 20+.
import { execFileSync } from 'node:child_process';
import { mkdir, writeFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { performance } from 'node:perf_hooks';
import { setTimeout as pausa } from 'node:timers/promises';

const rutas = ['/actuator/health', '/api/estado'];
function version() {
  const git = (...args) => execFileSync('git', args, { encoding: 'utf8', stdio: ['ignore','pipe','ignore'] }).trim();
  try { return { commit: git('rev-parse','HEAD'), cambiosLocales: Boolean(git('status','--porcelain')) }; }
  catch { return { commit: null, cambiosLocales: null }; }
}
// Solo se conservan datos mínimos; jamás cuerpos, cabeceras ni centros individuales.
async function medir(ruta, puerto) {
  const inicio = performance.now();
  let http = null, detalle = 'sin_respuesta', correcto = false;
  try {
    const resp = await fetch('http://127.0.0.1:' + puerto + ruta,
      { signal: AbortSignal.timeout(5000), redirect: 'error', headers: { Accept: 'application/json' } });
    http = resp.status;
    if (http !== 200) { detalle = 'http_no_esperado'; await resp.body?.cancel(); }
    else {
      let dato;
      try { dato = await resp.json(); }
      catch (e) { if (e.name === 'SyntaxError') detalle = 'respuesta_no_json'; else throw e; }
      if (detalle !== 'respuesta_no_json') {
        correcto = ruta === rutas[0] ? dato?.status === 'UP'
          : dato?.estado === 'CONECTADO' && dato?.baseDatos === 'PostgreSQL' && dato?.tablas === 9;
        detalle = correcto ? (ruta === rutas[0] ? 'UP' : 'CONECTADO_9_TABLAS') : 'respuesta_inesperada';
      }
    }
  } catch (e) { detalle = ['AbortError','TimeoutError'].includes(e.name) ? 'tiempo_agotado' : 'sin_respuesta'; }
  const duracionMs = Math.round((performance.now() - inicio) * 10) / 10;
  return { ruta, http, detalle, duracionMs, nivel: !correcto ? 'ERROR' : duracionMs >= 2000 ? 'WARN' : 'INFO' };
}
export async function muestra(puerto) {
  const fechaUTC = new Date().toISOString();
  return { fechaUTC, consultas: await Promise.all(rutas.map(r => medir(r, puerto))) };
}
function opciones(args) {
  const valores = { '--muestras': 3, '--intervalo': 5, '--puerto': 18080 };
  const topes = { '--muestras': 100, '--intervalo': 3600, '--puerto': 65535 };
  for (let i=0; i<args.length; i+=2) {
    const clave=args[i], bruto=args[i+1];
    if (!Object.hasOwn(valores,clave) || !/^\d+$/.test(bruto ?? '') ||
        Number(bruto)<1 || Number(bruto)>topes[clave]) throw Error('Parámetro no válido: '+clave);
    valores[clave]=Number(bruto);
  }
  return valores;
}
async function main() {
  const args=opciones(process.argv.slice(2)), registros=[];
  const fuente=version();
  for (let i=0; i<args['--muestras']; i++) {
    const dato=await muestra(args['--puerto']); registros.push(dato);
    for (const r of dato.consultas) console.log(dato.fechaUTC, r.nivel, r.ruta, r.http ?? 'SIN_HTTP', r.detalle, r.duracionMs+' ms');
    if (i+1<args['--muestras']) await pausa(args['--intervalo']*1000);
  }
  const consultas=registros.flatMap(r=>r.consultas);
  const resumen=rutas.map(ruta=>{
    const lista=consultas.filter(r=>r.ruta===ruta);
    const validas=lista.filter(r=>r.nivel!=='ERROR'); const tiempos=validas.map(r=>r.duracionMs).sort((a,b)=>a-b);
    return {ruta, intentos:lista.length, validas:validas.length, fallos:lista.length-validas.length,
      avisosLentos:validas.filter(r=>r.nivel==='WARN').length,
      p95MsValidas:tiempos.length?tiempos[Math.ceil(0.95*tiempos.length)-1]:null};
  });
  const dir=join('docs','monitoreo','evidencias');
  await mkdir(dir,{recursive:true});
  const archivo=join(dir,'sondeo-'+registros[0].fechaUTC.replace(/[:.]/g,'-')+'-'+randomUUID().slice(0,8)+'.json');
  await writeFile(archivo,JSON.stringify({ fuente, puerto:args['--puerto'], pausaEntreRondasSeg:args['--intervalo'],
    alcance:'Sondeos HTTP locales de salud y estado. No miden el registro de lotes ni la disponibilidad mensual.',
    registros, resumen },null,2)+'\n',{encoding:'utf8',flag:'wx'});
  console.log('Evidencia: '+resolve(archivo));
  if (resumen.some(r=>r.fallos)) process.exitCode=2;
}
if (process.argv[1] && import.meta.url===pathToFileURL(resolve(process.argv[1])).href) {
  main().catch(e=>{ console.error(e.message); process.exitCode=1; });
}
