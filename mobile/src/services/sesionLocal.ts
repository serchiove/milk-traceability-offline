import * as SecureStore from 'expo-secure-store';
import type { SesionOperario } from './authService';
import { consultarCatalogo, consultarCentro, type Centro, type Proveedor, type Vehiculo } from './catalogoService';
import { guardarConfiguracion, leerConfiguracion } from '../model/loteRepository';
export type CatalogosLocales={proveedores:Proveedor[];vehiculos:Vehiculo[];centro:Centro;actualizado:string};
const clave='acopio.sesion.v1';
export function venceSesion(sesion:SesionOperario):number {
  try {const raw=sesion.accessToken.split('.')[1].replace(/-/g,'+').replace(/_/g,'/');return JSON.parse(atob(raw.padEnd(Math.ceil(raw.length/4)*4,'='))).exp*1000;}catch{return 0;}
}
export function sesionVigente(sesion:SesionOperario):boolean {return Number.isFinite(venceSesion(sesion))&&venceSesion(sesion)>Date.now();}
export async function cargarCatalogosLocales(sesion:SesionOperario):Promise<CatalogosLocales|null>{return leerConfiguracion(`catalogos:${sesion.usuario.id}:${sesion.usuario.idCentro}`);}
export async function autorizarDispositivo(sesion:SesionOperario):Promise<void>{
  if(!sesionVigente(sesion))throw new Error('La sesión recibida ya venció.');
  async function todos(tipo:'proveedores'|'vehiculos') {
    const rows:(Proveedor|Vehiculo)[]=[];
    for(let pagina=0;;pagina++){
      const r=await consultarCatalogo(sesion.accessToken,tipo,'',pagina);rows.push(...r.elementos);
      if(rows.length>=r.total)return rows;
      if(!r.elementos.length||pagina>=399)throw new Error('El catálogo es demasiado grande o cambió durante la descarga. Reintenta.');
    }
  }
  const [proveedores,vehiculos,centro]=await Promise.all([todos('proveedores'),todos('vehiculos'),consultarCentro(sesion.accessToken)]);
  if(centro.id!==sesion.usuario.idCentro)throw new Error('El centro de la sesión cambió. Inicia sesión nuevamente.');
  await guardarConfiguracion(`catalogos:${sesion.usuario.id}:${sesion.usuario.idCentro}`,{proveedores,vehiculos,centro,actualizado:new Date().toISOString()});
  await SecureStore.setItemAsync(clave,JSON.stringify(sesion));
}
export async function recuperarSesion():Promise<SesionOperario|null>{
  const raw=await SecureStore.getItemAsync(clave);if(!raw)return null;
  const sesion=JSON.parse(raw) as SesionOperario;
  if(!sesionVigente(sesion)){await cerrarSesion();return null;}
  if(!await cargarCatalogosLocales(sesion))return null;
  return sesion;
}
export async function cerrarSesion(){await SecureStore.deleteItemAsync(clave);}
