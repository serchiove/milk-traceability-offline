import {useState} from 'react';
import {consultarEstadoServidor} from '../services/entornoService';

export function useEntornoViewModel() {
  const [estado, setEstado] = useState('Conexión sin comprobar');
  const [busy, setBusy] = useState(false);

  async function comprobarApi() {
    setBusy(true);
    setEstado('Conectando…');
    try {
      const datos = await consultarEstadoServidor();
      setEstado(`PostgreSQL conectado · ${datos.tablas} tablas`);
    } catch {
      setEstado('Sin conexión. Revisa el backend y el enlace USB/emulador.');
    } finally {
      setBusy(false);
    }
  }

  return {estado, busy, comprobarApi};
}
