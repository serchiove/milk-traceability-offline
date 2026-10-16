import { useEffect, useState } from 'react';
import { prepararAlmacenamiento } from '../model/loteRepository';
import type { SesionOperario } from '../services/authService';
import { InicioCarga } from '../view/InicioCarga';
import { LoginScreen } from '../view/LoginScreen';
import { AppNavigator } from './AppNavigator';
export function Application() {
  const [estado, setEstado] = useState<'cargando' | 'listo' | 'error'>('cargando');
  const [intento, setIntento] = useState(0);
  useEffect(() => {
    let activo = true;
    setEstado('cargando');
    prepararAlmacenamiento().then(() => {
      if(activo)
        setEstado('listo');
    }).catch(() => {
      if(activo)
        setEstado('error');
    });
    return () => { activo = false; };
  }, [intento]);
  if(estado === 'listo')
    return <Acceso />;
  return <InicioCarga error={estado === 'error'} reintentar={() => setIntento(valor => valor + 1)} />;
}
function Acceso() {
  const [local, setLocal] = useState(false);
  const [sesion, setSesion] = useState<SesionOperario | null>(null);
  if(!local && !sesion)
    return <LoginScreen onLocal={() => setLocal(true)} onAcceso={setSesion} />;
  return <AppNavigator sesion={sesion} salir={() => { setSesion(null); setLocal(false); }} />;
}
