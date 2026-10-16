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
import { ServicioPendienteScreen } from '../view/ServicioPendienteScreen';
import { TrazabilidadScreen } from '../view/TrazabilidadScreen';
import { useEntornoViewModel } from '../viewmodel/useEntornoViewModel';
import { useLotesViewModel } from '../viewmodel/useLotesViewModel';
import { useOperarioNavigation } from './useOperarioNavigation';
export function AppNavigator({ sesion, salir }: {
  sesion: SesionOperario | null;
  salir: () => void;
}) {
  const vm = useLotesViewModel();
  const red = useEntornoViewModel();
  const nav = useOperarioNavigation(vm, sesion, salir);
  const { width, fontScale } = useWindowDimensions();
  const columnas = width >= 360 && fontScale <= 1.2;
  function contenido() {
    if(nav.detalle)
      return <DetalleScreen
        detalle={nav.detalle}
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
        cantidad={vm.lotes.length}
        navegar={nav.navegar}
        solicitarSalida={nav.solicitarSalida}
      />;
      case 'conexion': return <ConexionScreen red={red} />;
      case 'trazabilidad': return <TrazabilidadScreen
        vm={vm}
        codigo={nav.codigo}
        consultado={nav.consultado}
        setCodigo={nav.setCodigo}
        setConsultado={nav.setConsultado}
        abrir={nav.abrir}
      />;
      case 'calidad':
      case 'tanque': return <ServicioPendienteScreen pantalla={nav.pantalla} navegar={nav.navegar} />;
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
