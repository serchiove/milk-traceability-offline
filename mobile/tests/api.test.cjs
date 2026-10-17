const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const path = require('node:path');
const ts = require('typescript');
function load(file, fetch, env = {}) {
  const js = ts.transpileModule(readFileSync(path.join(__dirname, '../src/services', file), 'utf8'), {
    compilerOptions: {module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022},
  }).outputText;
  const module = {exports: {}};
  new Function('module', 'exports', 'fetch', 'process', js)(module, module.exports, fetch, {env});
  return module.exports;
}
const reply = (status, data) => ({status, ok: status >= 200 && status < 300, json: async () => data});
const session = {accessToken: 'test-token', usuario: {id: 1, nombre: 'Operario de prueba', rol: 'OPERARIO', idCentro: 1, centro: 'Centro de prueba'}};
test('login uses the real default route and agreed contract', async () => {
  const api = load('authService.ts', async (url, options) => {
    assert.equal(url, 'http://127.0.0.1:18080/api/auth/login');
    assert.deepEqual(JSON.parse(options.body), {email: 'test@example.com', password: 'test'});
    assert.equal(options.method, 'POST');
    return reply(200, session);
  });
  assert.deepEqual(await api.iniciarSesion('test@example.com', 'test'), session);
});
test('login refuses incorrect credentials, non-operator roles and incomplete sessions', async () => {
  await assert.rejects(load('authService.ts', async () => reply(401)).iniciarSesion('a', 'b'), /incorrectos/);
  await assert.rejects(load('authService.ts', async () => reply(200, {...session, usuario: {...session.usuario, rol: 'JEFATURA'}})).iniciarSesion('a', 'b'), /operario/);
  await assert.rejects(load('authService.ts', async () => reply(200, {accessToken: 'x'})).iniciarSesion('a', 'b'), /contrato/);
});
test('catalog search encodes user input, paginates and authenticates', async () => {
  const data = {elementos: [{id: 2, placa: 'ABC-123', capacidadLitros: 1000}], total: 26, pagina: 1, tamano: 25};
  const api = load('catalogoService.ts', async (url, options) => {
    assert.equal(url, 'http://server/api/catalogos/vehiculos?buscar=ABC%26%3F&pagina=1&tamano=25');
    assert.equal(options.headers.Authorization, 'Bearer test-token');
    return reply(200, data);
  }, {EXPO_PUBLIC_API_URL: 'http://server/'});
  assert.deepEqual(await api.consultarCatalogo('test-token', 'vehiculos', 'ABC&?', 1), data);
});
test('center comes from authenticated server endpoint without caller-supplied center id', async () => {
  const centro = {id: 5, nombre: 'Centro', region: 'Arequipa', capacidadLitros: 1000};
  const api = load('catalogoService.ts', async (url, options) => {
    assert.equal(url, 'http://127.0.0.1:18080/api/catalogos/centro');
    assert.equal(options.headers.Authorization, 'Bearer test-token');
    return reply(200, centro);
  });
  assert.deepEqual(await api.consultarCentro('test-token'), centro);
});
test('catalog errors distinguish expired sessions, permissions and disconnection', async () => {
  for (const [status, message] of [[401, /sesión/], [403, /permiso/], [500, /consultar/]]) {
    await assert.rejects(load('catalogoService.ts', async () => reply(status)).consultarCatalogo('x', 'proveedores'), message);
  }
  await assert.rejects(load('catalogoService.ts', async () => {throw new TypeError('network');}).consultarCentro('x'), /contactar/);
  await assert.rejects(load('catalogoService.ts', async () => {throw Object.assign(new Error(), {name: 'AbortError'});}).consultarCentro('x'), /tardó/);
});
test('invalid catalog and center responses cannot reach the screen', async () => {
  for (const data of [null, {}, {elementos: [null], total: 1, pagina: 0, tamano: 25}]) {
    await assert.rejects(load('catalogoService.ts', async () => reply(200, data)).consultarCatalogo('x', 'proveedores'), /no válido/);
  }
  await assert.rejects(load('catalogoService.ts', async () => reply(200, {id: 0})).consultarCentro('x'), /no válido/);
});
