import { StatusBar } from 'expo-status-bar';
import { ActivityIndicator, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Button } from '../components/Button';
import { Icon } from '../components/Icon';
import { theme } from '../theme/theme';
import { styles as s } from './styles/InicioCarga.styles';
export function InicioCarga({ error, reintentar }: {
  error: boolean;
  reintentar: () => void;
}) {
  return <SafeAreaView style={s.root}>
    <StatusBar style="dark" />

    <View style={s.center}>

      <View style={s.emblem}>
        <View style={s.inner}>
          <Icon name="droplet" color={theme.colors.primary} size={46} />
        </View>
      </View>

      <Text style={s.brand}>GLORIA</Text>
      <View style={s.line} />
      <Text style={s.product}>ACOPIO DE LECHE</Text>

      <Text style={s.subtitle}>Recepción y trazabilidad</Text>

      <View accessibilityLiveRegion="polite" style={s.status}>

        {error ? <>
          <Text style={s.errorTitle}>No pudimos preparar el almacenamiento</Text>
          <Text style={s.message}>Vuelve a intentarlo. No se han borrado tus registros.</Text>
          <Button title="Reintentar" onPress={reintentar} />
        </> : <>
          <ActivityIndicator color={theme.colors.primary} size="small" />
          <Text style={s.message}>Preparando tu espacio de trabajo…</Text>
        </>}

      </View>

    </View>
    <Text style={s.footer}>Preparación local · No requiere conexión</Text>

  </SafeAreaView>;
}
