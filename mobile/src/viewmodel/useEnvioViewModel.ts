import { useEffect, useRef, useState } from 'react';
import type { LoteLocal } from '../model/lote';
import type { EnvioLocal } from '../model/envio';
import { leerEnvio } from '../model/loteRepository';
import { enviarRecepcion } from '../services/envioService';
import type { SesionOperario } from '../services/authService';
import type { Proveedor, Vehiculo } from '../services/catalogoService';
export function useEnvioViewModel(lote: LoteLocal, sesion: SesionOperario | null, actualizado: () => void) {
  const [envio, setEnvio] = useState<EnvioLocal | null>(null);
  const [proveedor, setProveedor] = useState<Proveedor | null>(null);
  const [vehiculo, setVehiculo] = useState<Vehiculo | null>(null);
  const [listo, setListo] = useState(false);
  const [ocupado, setOcupado] = useState(false);
  const [error, setError] = useState('');
  const [intento, setIntento] = useState(0);
  const bloqueo = useRef(false);
  useEffect(() => {
    let activo = true;
    setListo(false); setEnvio(null); setError(''); setProveedor(null); setVehiculo(null);
    leerEnvio(lote.id).then(valor => { if (activo) { setEnvio(valor); setListo(true); } })
      .catch(() => { if (activo) setError('No se pudo leer el estado del envío. Reintenta antes de enviar.'); });
    return () => { activo = false; };
  }, [lote.id, intento]);
  const propio = !envio || (envio.usuario === sesion?.usuario.id && envio.centro === sesion?.usuario.idCentro);
  async function enviar() {
    if (!sesion || !listo || !propio || bloqueo.current || (!envio && (!proveedor || !vehiculo))) return;
    bloqueo.current = true; setOcupado(true); setError('');
    const solicitud = envio?.solicitud ?? {
      idLote: lote.id, idProveedor: proveedor!.id, idVehiculo: vehiculo!.id,
      fechaHora: lote.fecha, volumenLitros: lote.volumen,
      mediciones: {temperaturaC: lote.temperatura, acidezDornic: lote.acidez, densidadGml: lote.densidad},
    };
    try { await enviarRecepcion(sesion, solicitud); actualizado(); }
    catch (problema) { setError(problema instanceof Error ? problema.message : 'No se pudo confirmar el envío.'); }
    finally {
      try { setEnvio(await leerEnvio(lote.id)); }
      catch { setListo(false); setError('No se pudo leer la confirmación local. Reintenta la lectura.'); }
      bloqueo.current = false; setOcupado(false);
    }
  }
  return {envio, proveedor, vehiculo, setProveedor, setVehiculo, listo, ocupado, error, propio, enviar, reintentar: () => setIntento(n => n + 1)};
}
