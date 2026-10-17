const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const path = require('node:path');
const {DatabaseSync} = require('node:sqlite');
const ts = require('typescript');

// Load production TypeScript; SQLite calls use a real isolated in-memory database.
// These tests do not access the phone or its Expo SQLite database.
function loadSource(relative, replacements = {}) {
  const filename = path.join(__dirname, '..', relative);
  const js = ts.transpileModule(readFileSync(filename, 'utf8'), {
    compilerOptions: {module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022},
  }).outputText;
  const module = {exports: {}};
  new Function('require', 'module', 'exports', js)(name => {
    if (name in replacements) return replacements[name];
    throw new Error(`Unexpected dependency: ${name}`);
  }, module, module.exports);
  return module.exports;
}
const {validarLote, formularioVacio} = loadSource('src/model/lote.ts');
const valid = () => ({proveedor: '  Fundo San José  ', vehiculo: 'abc-123', centro: ' Majes ', volumen: '120,50', temperatura: '4.5', acidez: '16', densidad: '1,0300'});

test('normalizes text and comma/point decimals', () => {
  const result = validarLote(valid());
  assert.deepEqual(result.errores, {});
  assert.deepEqual(result.datos, {proveedor: 'Fundo San José', vehiculo: 'ABC-123', centro: 'Majes', volumen: 120.5, temperatura: 4.5, acidez: 16, densidad: 1.03});
});
test('empty form reports every required field', () => {
  const result = validarLote(formularioVacio());
  assert.equal(Object.keys(result.errores).length, 7);
  assert.equal(result.datos, undefined);
});
test('rejects whitespace-only origin fields and oversized names', () => {
  for (const field of ['proveedor', 'vehiculo', 'centro']) {
    assert.ok(validarLote({...valid(), [field]: '   '}).errores[field]);
    assert.ok(validarLote({...valid(), [field]: 'a'.repeat(181)}).errores[field]);
  }
});
test('rejects thousands separators, scientific notation and non-finite numbers', () => {
  for (const value of ['1,200.50', '1.200,50', '1e3', 'Infinity', 'NaN', 'abc']) {
    assert.ok(validarLote({...valid(), volumen: value}).errores.volumen, value);
  }
});
test('enforces numeric bounds without claiming quality approval', () => {
  for (const [field, value] of [['volumen','0'], ['volumen','-1'], ['volumen','10000000000'], ['temperatura','-273.16'], ['acidez','-1'], ['densidad','0'], ['densidad','1000']]) {
    assert.ok(validarLote({...valid(), [field]: value}).errores[field]);
  }
  assert.ok(validarLote({...valid(), temperatura:'-10', acidez:'0'}).datos);
});
test('accepts boundary precision and rejects excess decimals', () => {
  assert.ok(validarLote({...valid(), densidad:'1.0325'}).datos);
  for (const [field, value] of [['volumen','1.001'], ['temperatura','4.001'], ['acidez','16.001'], ['densidad','1.03001']]) {
    assert.ok(validarLote({...valid(), [field]:value}).errores[field]);
  }
});
function repository() {
  const db = new DatabaseSync(':memory:');
  let opens = 0;
  const adapter = {
    async openDatabaseAsync() {
      opens++;
      return {
        async execAsync(sql) {db.exec(sql);},
        async getAllAsync(sql, ...args) {return db.prepare(sql).all(...args).map(row => ({...row}));},
        async getFirstAsync(sql, ...args) {return db.prepare(sql).get(...args);},
        async runAsync(sql, ...args) {return db.prepare(sql).run(...args);},
      };
    },
  };
  return {db, api:loadSource('src/model/loteRepository.ts', {'expo-sqlite':adapter}), opens:()=>opens};
}
test('initialization is idempotent and an empty database lists no records', async () => {
  const r = repository();
  try {
    await Promise.all([r.api.prepararAlmacenamiento(), r.api.prepararAlmacenamiento()]);
    assert.equal(r.opens(),1);
    assert.deepEqual(await r.api.listarLotes(),[]);
  } finally {r.db.close();}
});
test('saves and reads actual SQLite records with stable UUIDs and measurements', async () => {
  const r = repository();
  try {
    const data = validarLote(valid()).datos;
    const saved = await r.api.guardarLote(data);
    const second = await r.api.guardarLote(data);
    assert.match(saved.id,/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
    assert.notEqual(saved.id,second.id);
    assert.ok(Number.isFinite(Date.parse(saved.fecha)));
    const records = await r.api.listarLotes();
    assert.equal(records.length,2);
    assert.deepEqual(records.find(l=>l.id===saved.id),saved);
    assert.deepEqual(await r.api.listarLotes(),records);
  } finally {r.db.close();}
});
test('parameterized storage preserves quotes and SQL-like provider text', async () => {
  const r = repository();
  try {
    const data = {...validarLote(valid()).datos, proveedor: "Fundo O'Connor; DROP TABLE borrador_lote_v1;--"};
    const saved = await r.api.guardarLote(data);
    assert.equal((await r.api.listarLotes())[0].proveedor,saved.proveedor);
    await r.api.guardarLote(validarLote(valid()).datos);
    assert.equal((await r.api.listarLotes()).length,2);
  } finally {r.db.close();}
});
test('failed initialization can be retried', async () => {
  let attempts=0;
  const api=loadSource('src/model/loteRepository.ts', {'expo-sqlite':{async openDatabaseAsync(){
    if(++attempts===1)throw new Error('temporary failure');
    return {async execAsync(){}};
  }}});
  await assert.rejects(api.prepararAlmacenamiento(),/temporary failure/);
  await api.prepararAlmacenamiento();
  assert.equal(attempts,2);
});


test('unfinished edition is isolated from confirmed lots and can be recovered', async () => {
  const r = repository();
  try {
    const partial = {...formularioVacio(), proveedor: "Fundo O'Connor", volumen: '12,'};
    await r.api.guardarEdicion(partial);
    assert.deepEqual(await r.api.leerEdicion(),partial);
    assert.deepEqual(await r.api.listarLotes(),[]);
    // Re-initializing the schema must not remove the unfinished form.
    await r.api.prepararAlmacenamiento();
    assert.deepEqual(await r.api.leerEdicion(),partial);
  } finally {r.db.close();}
});
test('rapid autosaves preserve the most recent snapshot', async () => {
  const r = repository();
  try {
    await Promise.all(['F','Fu','Fundo'].map(proveedor=>r.api.guardarEdicion({...formularioVacio(),proveedor})));
    assert.equal((await r.api.leerEdicion()).proveedor,'Fundo');
  } finally {r.db.close();}
});
test('confirming a lot clears earlier queued autosaves atomically', async () => {
  const r = repository();
  try {
    const autosave = r.api.guardarEdicion(valid());
    const confirmation = r.api.guardarLote(validarLote(valid()).datos);
    await Promise.all([autosave,confirmation]);
    assert.equal(await r.api.leerEdicion(),null);
    assert.equal((await r.api.listarLotes()).length,1);
  } finally {r.db.close();}
});
test('failed confirmation retains the edition and creates no partial lot', async () => {
  const r = repository();
  try {
    await r.api.guardarEdicion(valid());
    await assert.rejects(r.api.guardarLote({...validarLote(valid()).datos,volumen:0}));
    assert.deepEqual(await r.api.leerEdicion(),valid());
    assert.equal((await r.api.listarLotes()).length,0);
    await r.api.guardarLote(validarLote(valid()).datos);
    assert.equal((await r.api.listarLotes()).length,1);
  } finally {r.db.close();}
});
test('discarding edition preserves existing confirmed lots', async () => {
  const r = repository();
  try {
    const lot = await r.api.guardarLote(validarLote(valid()).datos);
    await r.api.guardarEdicion(valid());
    await r.api.guardarEdicion(formularioVacio());
    assert.equal(await r.api.leerEdicion(),null);
    assert.deepEqual(await r.api.listarLotes(),[lot]);
  } finally {r.db.close();}
});
const result = id => ({idLote:id, estadoEvaluacion:'APROBADO', motivo:null, codigoQr:`ACOPIO:${id}`, versionReglas:'DEMO-1', recibidoEn:'2026-10-16T12:00:00Z', idempotente:false});
const request = lote => ({idLote:lote.id, idProveedor:1, idVehiculo:2, volumenLitros:lote.volumen, fechaHora:lote.fecha, mediciones:{temperaturaC:lote.temperatura, acidezDornic:lote.acidez, densidadGml:lote.densidad}});
test('prepared send survives reload, freezes identity and payload, and confirmation keeps local record', async () => {
  const r = repository();
  try {
    const lote = await r.api.guardarLote(validarLote(valid()).datos);
    const body = request(lote);
    await r.api.prepararEnvio(body, 4, 5);
    assert.deepEqual((await r.api.leerEnvio(lote.id)).solicitud, body);
    await assert.rejects(r.api.prepararEnvio(body, 9, 5), /otro operario/);
    await assert.rejects(r.api.prepararEnvio(body, 4, 8), /otro operario/);
    await assert.rejects(r.api.prepararEnvio({...body, idProveedor:3}, 4, 5), /datos originales/);
    assert.equal((await r.api.listarLotes())[0].enviado, undefined);
    await r.api.confirmarEnvio(lote.id, result(lote.id));
    assert.equal((await r.api.listarLotes())[0].enviado, true);
    assert.equal((await r.api.listarLotes())[0].id, lote.id);
    assert.equal((await r.api.prepararEnvio(body, 4, 5)).resultado.estadoEvaluacion, 'APROBADO');
  } finally {r.db.close();}
});
test('concurrent preparations cannot change the first sending identity', async () => {
  const r = repository();
  try {
    const lote = await r.api.guardarLote(validarLote(valid()).datos);
    const results = await Promise.allSettled([r.api.prepararEnvio(request(lote), 1, 2), r.api.prepararEnvio(request(lote), 3, 2)]);
    assert.equal(results[0].status, 'fulfilled');
    assert.equal(results[1].status, 'rejected');
    assert.equal((await r.api.leerEnvio(lote.id)).usuario, 1);
  } finally {r.db.close();}
});
test('capture binds owner and catalog IDs atomically; editions are isolated by operator', async () => {
 const r=repository();try{
  const form={...valid(),idProveedor:'4',idVehiculo:'5'};
  await r.api.guardarEdicion(form,'1:2');
  await r.api.guardarEdicion({...form,volumen:'80'},'3:2');
  assert.equal((await r.api.leerEdicion('1:2')).idProveedor,'4');
  assert.equal((await r.api.leerEdicion('3:2')).volumen,'80');
  const lote=await r.api.guardarLote(validarLote(form).datos,{usuario:1,centro:2,idProveedor:4,idVehiculo:5,clave:'1:2'});
  const envio=await r.api.leerEnvio(lote.id);
  assert.equal(envio.usuario,1);assert.equal(envio.centro,2);assert.equal(envio.solicitud.idProveedor,4);
  assert.equal(envio.resultado,null);assert.equal(await r.api.leerEdicion('1:2'),null);
  assert.equal((await r.api.leerEdicion('3:2')).volumen,'80');
 }finally{r.db.close();}
});
test('failed identity write rolls back lot and retains operator edition', async () => {
 const r=repository();try{
  await r.api.guardarEdicion(valid(),'1:2');
  r.db.exec("CREATE TRIGGER fail_owner BEFORE INSERT ON envio_lote_v1 BEGIN SELECT RAISE(ABORT,'test failure'); END;");
  await assert.rejects(r.api.guardarLote(validarLote(valid()).datos,{usuario:1,centro:2,idProveedor:4,idVehiculo:5,clave:'1:2'}));
  assert.equal((await r.api.listarLotes()).length,0);assert.ok(await r.api.leerEdicion('1:2'));
 }finally{r.db.close();}
});
