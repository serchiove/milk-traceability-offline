import type { SesionOperario } from './authService';
import type { SolicitudLote, ResultadoEnvio } from '../model/envio';
import { prepararEnvio, confirmarEnvio } from '../model/loteRepository';
import { huellaSolicitud } from './huellaSolicitud';
import { sesionVigente } from './sesionLocal';
const API = (process.env.EXPO_PUBLIC_API_URL || 'http://127.0.0.1:18080').replace(/\/$/, '');
export async function enviarRecepcion(sesion: SesionOperario, solicitud: SolicitudLote): Promise<ResultadoEnvio> {
  if(!sesionVigente(sesion))throw new Error('Tu sesión venció. Inicia sesión nuevamente con el mismo operario.');
  const envio = await prepararEnvio(solicitud, sesion.usuario.id, sesion.usuario.idCentro);
  if (envio.resultado) return envio.resultado;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetch(`${API}/api/lotes`, {
      method: 'POST', headers: {Authorization: `Bearer ${sesion.accessToken}`, 'Content-Type': 'application/json'},
      body: JSON.stringify({...envio.solicitud,huellaSolicitud:huellaSolicitud(envio.solicitud,sesion.usuario.id,sesion.usuario.idCentro)}), signal: controller.signal,
    });
    if (response.status === 401) throw new Error('La sesión ya no es válida. Vuelve a iniciar sesión con el mismo operario.');
    if (response.status === 403) throw new Error('Tu cuenta no tiene permiso para registrar recepciones.');
    if (response.status === 409) throw new Error('El servidor detectó un conflicto con este identificador. Conserva el registro y consulta al administrador.');
    if (response.status === 400) throw new Error('El servidor rechazó los datos o el catálogo dejó de estar activo. Conserva el registro para su revisión.');
    if (!response.ok) throw new Error('No se confirmó la recepción. Puedes reintentar sin crear otro registro.');
    const datos: ResultadoEnvio = await response.json();
    if (!datos || datos.idLote !== solicitud.idLote || !['APROBADO', 'RECHAZADO', 'PENDIENTE'].includes(datos.estadoEvaluacion) ||
      typeof datos.idempotente !== 'boolean' || typeof datos.recibidoEn !== 'string' || !Number.isFinite(Date.parse(datos.recibidoEn)) ||
      !(datos.motivo === null || typeof datos.motivo === 'string') || !(datos.codigoQr === null || typeof datos.codigoQr === 'string') ||
      !(datos.versionReglas === null || typeof datos.versionReglas === 'string')) throw new Error('Respuesta no válida. Reintenta con el mismo registro.');
    await confirmarEnvio(solicitud.idLote, datos);
    return datos;
  } catch (error) {
    if (error instanceof Error && (error.name === 'AbortError' || error instanceof TypeError))
      throw new Error('Se perdió la conexión o se agotó el tiempo. El registro se conserva; reintenta para confirmar si llegó al servidor.');
    throw error;
  } finally { clearTimeout(timer); }
}
