const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const path = require('node:path');
const ts = require('typescript');
const sesion = {accessToken:'token', usuario:{id:1, idCentro:2}};
const solicitud = {idLote:'test-id', idProveedor:3, idVehiculo:4, volumenLitros:100, fechaHora:'2026-10-16T12:00:00Z', mediciones:{temperaturaC:4, acidezDornic:16, densidadGml:1.03}};
const resultado = {idLote:'test-id', estadoEvaluacion:'RECHAZADO', motivo:'Regla demo', codigoQr:null, versionReglas:'DEMO-1', recibidoEn:'2026-10-16T12:01:00Z', idempotente:false};
function api(fetch) {
  const js = ts.transpileModule(readFileSync(path.join(__dirname, '../src/services/envioService.ts'), 'utf8'), {compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText;
  const module = {exports:{}};
  const state = {prepared:false, result:null};
  const repository = {
    prepararEnvio:async (body, user, center) => {assert.equal(user,1); assert.equal(center,2); state.prepared=true; return {solicitud:body, resultado:state.result};},
    confirmarEnvio:async (id, value) => {assert.equal(id,solicitud.idLote); state.result=value;},
  };
  new Function('require','module','exports','fetch',js)(name => name.includes('sesionLocal')?{sesionVigente:()=>true}:name.includes('huellaSolicitud')?{huellaSolicitud:()=> 'a'.repeat(64)}:repository,module,module.exports,async (...args) => {assert.equal(state.prepared,true); return fetch(...args);});
  return {send:()=>module.exports.enviarRecepcion(sesion,solicitud),state};
}
test('send persists before HTTP, accepts rejected quality as received, and does not resend confirmed record', async () => {
  let calls=0;
  const a=api(async (url, options) => {calls++; assert.ok(url.endsWith('/api/lotes')); assert.equal(options.headers.Authorization,'Bearer token'); assert.deepEqual(JSON.parse(options.body),{...solicitud,huellaSolicitud:'a'.repeat(64)}); return {ok:true,json:async()=>resultado};});
  assert.deepEqual(await a.send(),resultado);
  assert.deepEqual(await a.send(),resultado);
  assert.equal(calls,1);
});
test('failed or invalid responses are never marked as received and retry keeps UUID', async () => {
  for (const response of [{ok:false,status:409}, {ok:true,json:async()=>({...resultado,idLote:'wrong'})}]) {
    const a=api(async()=>response);
    await assert.rejects(a.send()); assert.equal(a.state.result,null);
  }
  let first=true;
  const bodies=[];
  const a=api(async (_url,options)=>{bodies.push(options.body); if(first){first=false;throw new TypeError('network');} return {ok:true,json:async()=>({...resultado,idempotente:true})};});
  await assert.rejects(a.send(),/conexión/);
  assert.equal(a.state.result,null);
  assert.equal((await a.send()).idempotente,true);
  assert.equal(bodies[0],bodies[1]);
});
