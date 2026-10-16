import { useEffect, useRef, useState } from 'react';
import { Alert, BackHandler, Keyboard, ScrollView } from 'react-native';
import type { LoteLocal } from '../model/lote';
import type { SesionOperario } from '../services/authService';
import type { LotesViewModel } from '../viewmodel/types';
import type { Pantalla } from './routes';
export function useOperarioNavigation(vm: LotesViewModel, sesion: SesionOperario | null, salir: () => void) {
  const [pantalla, setPantalla] = useState<Pantalla>('inicio');
  const [paso, setPaso] = useState(0);
  const [detalle, setDetalle] = useState<LoteLocal | null>(null);
  const [guardado, setGuardado] = useState(false);
  const [codigo, setCodigo] = useState('');
  const [consultado, setConsultado] = useState<string | null>(null);
  const scroll = useRef<ScrollView>(null);
  function navegar(destino: Pantalla) {
    if(vm.guardando)
      return; Keyboard.dismiss(); setDetalle(null); setGuardado(false); setPantalla(destino);
  }
  function abrir(lote: LoteLocal) { navegar('lotes'); setDetalle(lote); }
  function volver() {
    if(vm.guardando)
      return;
    if(detalle) {
      setDetalle(null);
      setGuardado(false);
    }
    else if(pantalla === 'registro' && paso > 0)
      setPaso(paso - 1);
    else
      navegar(['conexion', 'pendientes', 'calidad', 'trazabilidad', 'tanque'].includes(pantalla) ? 'perfil' : 'inicio');
  }
  async function salirConEdicion(accion: () => void) {
    if (await vm.asegurarEdicion()) accion();
    else Alert.alert('No se pudo conservar la recepción', 'Continúa aquí y reintenta el guardado automático antes de salir.');
  }
  function solicitarSalida() {
    if (vm.guardando) return;
    Alert.alert(sesion ? 'Cerrar sesión' : 'Volver al acceso', vm.tieneCambios ? 'La recepción en edición quedará guardada en este celular. Podrás retomarla al volver.' : 'Tus registros guardados permanecerán en este celular.', [{text: 'Cancelar', style: 'cancel'}, {text: 'Continuar', onPress: () => {void salirConEdicion(salir);}}]);
  }
  useEffect(() => { const id = requestAnimationFrame(() => scroll.current?.scrollTo({ y: 0, animated: false })); return () => cancelAnimationFrame(id); }, [pantalla, paso, detalle?.id]);
  useEffect(() => {
    const listener = BackHandler.addEventListener('hardwareBackPress', () => {
      if(vm.guardando)
        return true;
      if(pantalla !== 'inicio' || detalle) {
        volver();
        return true;
      }
      if(vm.tieneCambios) {
        Alert.alert('Conservar recepción', 'La recepción en edición se conservará en este celular para retomarla después.', [{text: 'Continuar aquí', style: 'cancel'}, {text: 'Salir', onPress: () => {void salirConEdicion(() => BackHandler.exitApp());}}]);
        return true;
      }
      return false;
    });
    return () => listener.remove();
  }, [pantalla, paso, detalle, vm.guardando, vm.tieneCambios]);
  function siguiente() {
    Keyboard.dismiss();
    if(paso === 0 && vm.validarPaso(['proveedor', 'vehiculo', 'centro']))
      setPaso(1);
    if(paso === 1 && vm.prepararRevision())
      setPaso(2);
  }
  async function descartarEdicion() {
    if (await vm.descartarEdicion()) setPaso(0);
  }
  async function guardar() {
    const lote = await vm.guardar();
    if(lote) {
      setPaso(0);
      vm.setBusqueda('');
      abrir(lote);
      setGuardado(true);
    }
  }
  return { pantalla, paso, detalle, guardado, codigo, consultado, setCodigo, setConsultado, scroll, navegar, abrir, volver, solicitarSalida, siguiente, guardar, descartarEdicion };
}
