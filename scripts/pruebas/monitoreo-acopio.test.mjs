import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { once } from 'node:events';
import { mkdtemp, readdir, readFile, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { muestra } from '../monitoreo-acopio.mjs';
async function servidor(t, fn) {
  const s=createServer(fn); s.listen(0,'127.0.0.1'); await once(s,'listening');
  t.after(()=>new Promise(resolve=>{s.close(resolve); s.closeAllConnections();})); return s.address().port;
}
const bin=fileURLToPath(new URL('../monitoreo-acopio.mjs',import.meta.url));
const ejecutar=promisify(execFile);
test('valida el contenido y no guarda centros ni cabeceras', async t=>{
  const puerto=await servidor(t,(req,res)=>{
    res.setHeader('X-Secreto','sensible'); res.end(JSON.stringify(req.url.includes('actuator')?{status:'UP'}:
      {estado:'CONECTADO',baseDatos:'PostgreSQL',tablas:9,centros:['dato-privado']}));
  });
  const dir=await mkdtemp(join(tmpdir(),'acopio-tests-')); t.after(()=>rm(dir,{recursive:true,force:true}));
  await ejecutar(process.execPath,[bin,'--muestras','1','--puerto',String(puerto)],{cwd:dir});
  const ev=join(dir,'docs','monitoreo','evidencias'); const [f]=await readdir(ev);
  const raw=await readFile(join(ev,f),'utf8'); const r=JSON.parse(raw);
  assert.equal(r.resumen.length,2); assert.ok(r.resumen.every(e=>e.validas===1 && e.fallos===0));
  assert.equal(r.registros[0].consultas[0].detalle,'UP'); assert.doesNotMatch(raw,/sensible|dato-privado/);
});
test('HTTP 200 no basta con estado distinto de UP o con esquema inesperado',async t=>{
  const puerto=await servidor(t,(req,res)=>res.end(JSON.stringify(req.url.includes('actuator')?{status:'DOWN'}:
    {estado:'CONECTADO',baseDatos:'PostgreSQL',tablas:0})));
  const x=await muestra(puerto); assert.ok(x.consultas.every(r=>r.http===200 && r.nivel==='ERROR'));
});
test('conserva un fallo HTTP y un cuerpo ilegible sin copiar el cuerpo',async t=>{
  const puerto=await servidor(t,(req,res)=>{if(req.url.includes('actuator')) res.statusCode=503; res.end('privado');});
  const x=await muestra(puerto); assert.equal(x.consultas[0].http,503);
  assert.equal(x.consultas[1].detalle,'respuesta_no_json'); assert.doesNotMatch(JSON.stringify(x),/privado/);
});
test('sin conexión guarda evidencia y devuelve código 2',async t=>{
  const s=createServer(); s.listen(0,'127.0.0.1'); await once(s,'listening'); const puerto=s.address().port;
  await new Promise(ok=>s.close(ok));
  const dir=await mkdtemp(join(tmpdir(),'acopio-fallo-')); t.after(()=>rm(dir,{recursive:true,force:true}));
  await assert.rejects(ejecutar(process.execPath,[bin,'--muestras','1','--puerto',String(puerto)],{cwd:dir}),e=>e.code===2);
  const ev=join(dir,'docs','monitoreo','evidencias'); const [f]=await readdir(ev);
  const r=JSON.parse(await readFile(join(ev,f),'utf8')); assert.ok(r.resumen.every(x=>x.fallos===1 && x.p95MsValidas===null));
});
