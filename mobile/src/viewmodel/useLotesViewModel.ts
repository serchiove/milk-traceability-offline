import type { SesionOperario } from '../services/authService';
import { cargarCatalogosLocales, sesionVigente, type CatalogosLocales } from '../services/sesionLocal';
import { leerEnvio } from '../model/loteRepository';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import type { ErroresLote, FormularioLote, LoteLocal } from '../model/lote';
import { formularioVacio, validarLote } from '../model/lote';
import { guardarEdicion, guardarLote, leerEdicion, listarLotes } from '../model/loteRepository';
export function useLotesViewModel(sesion:SesionOperario|null) {
  const clave=sesion?`${sesion.usuario.id}:${sesion.usuario.idCentro}`:undefined;
  const [catalogos,setCatalogos]=useState<CatalogosLocales|null>(null);
  useEffect(()=>{if(sesion)void cargarCatalogosLocales(sesion).then(setCatalogos).catch(()=>setError('No se pudieron leer los catálogos locales.'));},[sesion]);
  const [form, setForm] = useState(formularioVacio);
  const actual = useRef(formularioVacio());
  const [intentoEdicion, setIntentoEdicion] = useState(0);
  const [listoEdicion, setListoEdicion] = useState(false);
  const [estadoEdicion, setEstadoEdicion] = useState<'guardando' | 'guardado' | 'error'>('guardado');
  const [recuperado, setRecuperado] = useState(false);
  const pendiente = useRef<Promise<void>>(Promise.resolve());
  const version = useRef(0);
  const montado = useRef(true);
  useEffect(() => {
    montado.current = true;
    let activo = true;
    leerEdicion(clave).then(edicion => {
      if (!activo) return;
      if (edicion) {actual.current = edicion; setForm(edicion); setRecuperado(true);}
      setListoEdicion(true);
    }).catch(() => {
      if (activo) setEstadoEdicion('error');
    });
    return () => {activo = false; montado.current = false;};
  }, [intentoEdicion]);
  const [errores, setErrores] = useState<ErroresLote>({});
  const [lotes, setLotes] = useState<LoteLocal[]>([]);
  const [cargando, setCargando] = useState(true);
  const [guardando, setGuardando] = useState(false);
  const [error, setError] = useState('');
  const [busqueda, setBusqueda] = useState('');
  const normalizar = (texto: string) => texto.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
  const visibles = useMemo(() => {
    const termino = normalizar(busqueda);
    return lotes.filter(lote => [lote.proveedor, lote.vehiculo, lote.centro, lote.id].some(valor => normalizar(valor).includes(termino)));
  }, [lotes, busqueda]);
  // Suma en centésimas de litro para evitar residuos de coma flotante.
  const litrosVisibles = useMemo(() => visibles.reduce((total, lote) => total + Math.round(lote.volumen * 100), 0) / 100, [visibles]);
  const sugerencias = useMemo(() => {
    function valores(campo: 'proveedor' | 'vehiculo' | 'centro') {
      const unicos = new Map<string, string>();
      for(const lote of lotes) {
        const valor = lote[campo].trim();
        const clave = normalizar(valor);
        if(clave && !unicos.has(clave))
          unicos.set(clave, valor);
      }
      return [...unicos.values()].sort((a, b) => a.localeCompare(b, 'es'));
    }
    return { proveedor: valores('proveedor'), vehiculo: valores('vehiculo'), centro: valores('centro') };
  }, [lotes]);
  const bloqueo = useRef(false);
  const recargar = useCallback(async () => {
    setCargando(true);
    setError('');
    try {
      const locales=await listarLotes();
      const accesibles=await Promise.all(locales.map(async lote=>{const envio=await leerEnvio(lote.id);return !envio || (envio.usuario===sesion?.usuario.id&&envio.centro===sesion?.usuario.idCentro)?lote:null;}));
      setLotes(accesibles.filter((lote):lote is LoteLocal=>lote!==null));
    }
    catch {
      setError('No se pudieron leer los registros del dispositivo. Vuelve a intentarlo.');
    }
    finally {
      setCargando(false);
    }
  }, [sesion]);
  useEffect(() => { void recargar(); }, [recargar]);
  function persistirEdicion(valor: FormularioLote) {
    const revision = ++version.current;
    setEstadoEdicion('guardando');
    const tarea = guardarEdicion(valor, clave);
    pendiente.current = tarea;
    void tarea.then(() => {
      if (montado.current && revision === version.current) setEstadoEdicion('guardado');
    }).catch(() => {
      if (montado.current && revision === version.current) setEstadoEdicion('error');
    });
  }
  function seleccionarCatalogo(campo:'proveedor'|'vehiculo',id:number,nombre:string){
    if(!listoEdicion||bloqueo.current||!sesion||!catalogos)return;
    const siguiente={...actual.current,[campo]:nombre,[campo==='proveedor'?'idProveedor':'idVehiculo']:String(id),centro:catalogos.centro.nombre};
    actual.current=siguiente;setForm(siguiente);setErrores({});persistirEdicion(siguiente);
  }
  function cambiar(campo: keyof FormularioLote, valor: string) {
    if (!listoEdicion || bloqueo.current) return;
    const siguiente = {...actual.current, [campo]: valor};
    actual.current = siguiente;
    setForm(siguiente);
    setRecuperado(false);
    setErrores(anterior => ({...anterior, [campo]: undefined}));
    persistirEdicion(siguiente);
  }
  async function asegurarEdicion(): Promise<boolean> {
    if (!listoEdicion) return false;
    // Retry the latest snapshot, including a previously failed autosave.
    persistirEdicion(actual.current);
    try {await pendiente.current; return true;} catch {return false;}
  }
  async function descartarEdicion() {
    if (!listoEdicion || bloqueo.current) return;
    bloqueo.current = true;
    setGuardando(true);
    const vacio = formularioVacio();
    try {
      await guardarEdicion(vacio, clave);
      actual.current = vacio;
      setForm(vacio);
      setErrores({});
      setRecuperado(false);
      ++version.current;
      setEstadoEdicion('guardado');
      return true;
    } catch {setEstadoEdicion('error'); return false;}
    finally {bloqueo.current = false; setGuardando(false);}
  }
  const tieneCambios = Object.values(form).some(valor => valor.trim().length > 0);
  function accesoCaptura(){
    if(!sesion||!sesionVigente(sesion)){setError('La sesión venció. Inicia sesión nuevamente; la edición se conserva.');return false;}
    if(!catalogos||!catalogos.proveedores.some(p=>p.id===Number(form.idProveedor))||!catalogos.vehiculos.some(v=>v.id===Number(form.idVehiculo))){setError('Selecciona proveedor y vehículo del catálogo descargado.');return false;}
    setError('');return true;
  }
  function validarPaso(campos: (keyof FormularioLote)[]) {
    if(!accesoCaptura())return false;
    const validacion = validarLote(form);
    const erroresPaso = Object.fromEntries(campos.filter(campo => validacion.errores[campo]).map(campo => [campo, validacion.errores[campo]]));
    setErrores(erroresPaso);
    return Object.keys(erroresPaso).length === 0;
  }
  function prepararRevision() {
    if(!accesoCaptura())return null;
    const validacion = validarLote(form);
    setErrores(validacion.errores);
    setError('');
    return validacion.datos ?? null;
  }
  async function guardar(): Promise<LoteLocal | null> {
    if(!accesoCaptura() || bloqueo.current || !listoEdicion)
      return null;
    const validacion = validarLote(form);
    setErrores(validacion.errores);
    setError('');
    if(!validacion.datos)
      return null;
    bloqueo.current = true;
    setGuardando(true);
    try {
      if(!sesion||!sesionVigente(sesion))throw new Error('Sesión vencida');
      if(!catalogos||!catalogos.proveedores.some(p=>p.id===Number(form.idProveedor))||!catalogos.vehiculos.some(v=>v.id===Number(form.idVehiculo)))throw new Error('Selecciona datos oficiales');
      const lote = await guardarLote(validacion.datos,{usuario:sesion.usuario.id,centro:sesion.usuario.idCentro,idProveedor:Number(form.idProveedor),idVehiculo:Number(form.idVehiculo),clave:clave!});
      setLotes(anteriores => [lote, ...anteriores]);
      ++version.current;
      actual.current = formularioVacio();
      setForm(actual.current);
      setRecuperado(false);
      setEstadoEdicion('guardado');
      return lote;
    }
    catch {
      setError('No se pudo guardar. Tus campos siguen disponibles para volver a intentarlo.');
      return null;
    }
    finally {
      bloqueo.current = false;
      setGuardando(false);
    }
  }
  function reintentarEdicion() {
    if (listoEdicion) void asegurarEdicion();
    else {setEstadoEdicion('guardando'); setIntentoEdicion(valor => valor + 1);}
  }
  return { catalogos, seleccionarCatalogo, reintentarEdicion, listoEdicion, estadoEdicion, recuperado, asegurarEdicion, descartarEdicion, validarPaso, form, errores, tieneCambios, prepararRevision, lotes, sugerencias, visibles, litrosVisibles, busqueda, setBusqueda, cargando, guardando, error, cambiar, guardar, recargar };
}
