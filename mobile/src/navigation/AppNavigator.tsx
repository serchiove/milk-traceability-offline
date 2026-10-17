import { CentralScreen } from '../view/CentralScreen';
import { CatalogosScreen } from '../view/CatalogosScreen';
import { StatusBar } from 'expo-status-bar';
import { KeyboardAvoidingView, Platform, RefreshControl, ScrollView, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AppHeader } from '../components/AppHeader';
import { BottomNavigation } from '../components/BottomNavigation';
import { NoticeBox } from '../components/NoticeBox';
import type { SesionOperario } from '../services/authService';
import { screenStyles as s } from '../theme/screenStyles';
import { theme } from '../theme/theme';
import { ConexionScreen } from '../view/ConexionScreen';
import { DetalleScreen } from '../view/DetalleScreen';
import { InicioScreen } from '../view/InicioScreen';
import { PerfilScreen } from '../view/PerfilScreen';
import { RegistroScreen } from '../view/RegistroScreen';
import { RegistrosScreen } from '../view/RegistrosScreen';
import { useEntornoViewModel } from '../viewmodel/useEntornoViewModel';
import { useLotesViewModel } from '../viewmodel/useLotesViewModel';
import { useOperarioNavigation } from './useOperarioNavigation';
export function AppNavigator({ sesion, salir }: {
  sesion: SesionOperario | null;
  salir: () => void;
}) {
  const vm = useLotesViewModel(sesion);
  const red = useEntornoViewModel();
  const nav = useOperarioNavigation(vm, sesion, salir);
  const { width, fontScale } = useWindowDimensions();
  const columnas = width >= 360 && fontScale <= 1.2;
  function contenido() {
    if(nav.detalle)
      return <DetalleScreen
        detalle={vm.lotes.find(lote => lote.id === nav.detalle?.id) ?? nav.detalle}
        sesion={sesion}
        actualizado={() => {void vm.recargar();}}
        guardado={nav.guardado}
        columnas={columnas}
        navegar={nav.navegar}
      />;
    switch(nav.pantalla) {
      case 'inicio': return <InicioScreen vm={vm} navegar={nav.navegar} abrir={nav.abrir} />;
      case 'registro': return <RegistroScreen
          descartarEdicion={nav.descartarEdicion}
        vm={vm}
        paso={nav.paso}
        columnas={columnas}
        siguiente={nav.siguiente}
        guardar={nav.guardar}
        volver={nav.volver}
      />;
      case 'lotes':
      case 'pendientes': return <RegistrosScreen
        vm={vm}
        pendientes={nav.pantalla === 'pendientes'}
        navegar={nav.navegar}
        abrir={nav.abrir}
      />;
      case 'perfil': return <PerfilScreen
        sesion={sesion}
        cantidad={vm.lotes.filter(lote => !lote.enviado).length}
        navegar={nav.navegar}
        solicitarSalida={nav.solicitarSalida}
      />;
      case 'catalogos': return <CatalogosScreen sesion={sesion} />;
      case 'conexion': return <ConexionScreen red={red} />;
      case 'trazabilidad':
      case 'calidad':
      case 'tanque': return sesion ? <CentralScreen key={nav.pantalla} sesion={sesion} modo={nav.pantalla}/> : <NoticeBox variant="warning" message="Inicia sesión para consultar el servidor."/>;
    }
  }
  const permiteRecarga = ['inicio', 'lotes', 'pendientes'].includes(nav.pantalla) && !nav.detalle;
  return <SafeAreaView style={s.root}>

    <StatusBar style="dark" />

    <KeyboardAvoidingView style={s.flex} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>

      <AppHeader
        pantalla={nav.pantalla}
        detalle={!!nav.detalle}
        estadoRed={red.estado}
        bloqueado={vm.guardando}
        volver={nav.volver}
        navegar={nav.navegar}
      />

      <ScrollView
        ref={nav.scroll}
        keyboardShouldPersistTaps="handled"
        keyboardDismissMode="on-drag"
        contentContainerStyle={s.page}
        refreshControl={permiteRecarga ? <RefreshControl refreshing={vm.cargando} onRefresh={vm.recargar} tintColor={theme.colors.primary} /> : undefined}
      >

        {!!vm.error && <NoticeBox variant="error" message={vm.error} />}

        {contenido()}

      </ScrollView>

      {nav.pantalla !== 'registro' && <BottomNavigation actual={nav.pantalla} cambiar={nav.navegar} />}

    </KeyboardAvoidingView>

  </SafeAreaView>;
}
