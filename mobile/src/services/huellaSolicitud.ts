import { sha256 } from '@noble/hashes/sha2.js';
import { bytesToHex, utf8ToBytes } from '@noble/hashes/utils.js';
import type { SolicitudLote } from '../model/envio';
export function huellaSolicitud(s:SolicitudLote,usuario:number,centro:number):string{
  const fecha=new Date(s.fechaHora).toISOString().replace('.000Z','Z');
  const cadena=[s.idLote,s.idProveedor,s.idVehiculo,usuario,centro,fecha,s.volumenLitros,s.mediciones.temperaturaC,s.mediciones.acidezDornic,s.mediciones.densidadGml].join('|');
  return bytesToHex(sha256(utf8ToBytes(cadena)));
}
