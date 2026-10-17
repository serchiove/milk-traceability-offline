import { Alert } from 'react-native';
import { recuperarSesion, cerrarSesion } from '../services/sesionLocal';
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
  const [sesion,setSesion]=useState<SesionOperario|null>(null);
  const [cargando,setCargando]=useState(true);
  async function recuperar(manual=false){setCargando(true);try{const guardada=await recuperarSesion();setSesion(guardada);if(manual&&!guardada)Alert.alert('Acceso offline no disponible','Inicia sesión con conexión para autorizar el dispositivo y descargar los catálogos.');}catch{Alert.alert('No se pudo recuperar el acceso','Inicia sesión con conexión para volver a autorizar este dispositivo.');}finally{setCargando(false);}}
  useEffect(()=>{void recuperar();},[]);
  if(cargando)return <InicioCarga error={false} reintentar={()=>{void recuperar();}}/>;
  if(!sesion)return <LoginScreen onLocal={()=>{void recuperar(true);}} onAcceso={setSesion}/>;
  return <AppNavigator key={`${sesion.usuario.id}:${sesion.usuario.idCentro}`} sesion={sesion} salir={()=>{void cerrarSesion().then(()=>setSesion(null)).catch(()=>Alert.alert('No se pudo cerrar la sesión','Reintenta para borrar el acceso guardado.'));}}/>;
}
