import { useEffect, useState } from 'react';
import type { SesionOperario } from '../services/authService';
import { consultarCatalogo, consultarCentro, type Centro, type Pagina, type Proveedor, type Vehiculo } from '../services/catalogoService';
export function useCatalogosViewModel(sesion: SesionOperario | null) {
  const [tipo, setTipo] = useState<'proveedores' | 'vehiculos'>('proveedores');
  const [texto, setTexto] = useState('');
  const [buscar, setBuscar] = useState('');
  const [pagina, setPagina] = useState(0);
  const [intento, setIntento] = useState(0);
  const [datos, setDatos] = useState<Pagina<Proveedor | Vehiculo> | null>(null);
  const [centro, setCentro] = useState<Centro | null>(null);
  const [error, setError] = useState('');
  const [cargando, setCargando] = useState(false);
  useEffect(() => {
    if (!sesion) return;
    let vigente = true;
    setCargando(true); setError(''); setDatos(null); setCentro(null);
    Promise.all([consultarCatalogo(sesion.accessToken, tipo, buscar, pagina), consultarCentro(sesion.accessToken)])
      .then(([lista, lugar]) => { if (vigente) { setDatos(lista); setCentro(lugar); } })
      .catch(problema => { if (vigente) setError(problema instanceof Error ? problema.message : 'No se pudo cargar el catálogo.'); })
      .finally(() => { if (vigente) setCargando(false); });
    return () => { vigente = false; };
  }, [sesion, tipo, buscar, pagina, intento]);
  return {tipo, setTipo, texto, setTexto, buscar, setBuscar, pagina, setPagina, setIntento, datos, centro, error, cargando};
}
