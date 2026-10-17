const {test}=require('node:test');const assert=require('node:assert/strict');const fs=require('node:fs');const path=require('node:path');const ts=require('typescript');
function load(file,deps={}){const js=ts.transpileModule(fs.readFileSync(path.join(__dirname,'../src/services',file),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText;const m={exports:{}};new Function('require','module','exports',js)(name=>name in deps?deps[name]:require(name),m,m.exports);return m.exports;}
test('mobile fingerprint agrees with Java canonical format and SHA256',()=>{
 const {huellaSolicitud}=load('huellaSolicitud.ts');
 const req={idLote:'f4a1ba39-6c18-411a-9657-859c301ded22',idProveedor:3,idVehiculo:4,fechaHora:'2026-10-15T10:30:00-05:00',volumenLitros:120.50,mediciones:{temperaturaC:4,acidezDornic:16,densidadGml:1.0300}};
 const canonical='f4a1ba39-6c18-411a-9657-859c301ded22|3|4|1|2|2026-10-15T15:30:00Z|120.5|4|16|1.03';
 assert.equal(huellaSolicitud(req,1,2),require('node:crypto').createHash('sha256').update(canonical).digest('hex'));
 assert.notEqual(huellaSolicitud(req,2,2),huellaSolicitud(req,1,2));
});
test('offline access requires an unexpired saved session and matching local catalog',async()=>{
 let raw=null;const cache=new Map();
 const secure={getItemAsync:async()=>raw,setItemAsync:async(_k,v)=>{raw=v;},deleteItemAsync:async()=>{raw=null;}};
 const api=load('sesionLocal.ts',{'expo-secure-store':secure,'./catalogoService':{consultarCatalogo:async()=>({elementos:[],total:0}),consultarCentro:async()=>({id:2})},'../model/loteRepository':{guardarConfiguracion:async(k,v)=>cache.set(k,v),leerConfiguracion:async k=>cache.get(k)||null}});
 const token=exp=>'header.'+Buffer.from(JSON.stringify({exp})).toString('base64url')+'.signature';
 const s={accessToken:token(Math.floor(Date.now()/1000)+600),usuario:{id:1,idCentro:2}};
 assert.equal(await api.recuperarSesion(),null);await api.autorizarDispositivo(s);assert.deepEqual(await api.recuperarSesion(),s);
 await api.cerrarSesion();assert.equal(await api.recuperarSesion(),null);
 raw=JSON.stringify({...s,accessToken:token(1)});assert.equal(await api.recuperarSesion(),null);assert.equal(raw,null);
});
