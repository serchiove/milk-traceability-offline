import { Pressable, Text, View } from 'react-native';
import type { Pantalla } from '../navigation/routes';
import { titulos } from '../navigation/routes';
import { screenStyles as s } from '../theme/screenStyles';
import { Icon } from './Icon';
type Props = {
  pantalla: Pantalla;
  detalle: boolean;
  estadoRed: string;
  bloqueado: boolean;
  volver: () => void;
  navegar: (destino: Pantalla) => void;
};
export function AppHeader({ pantalla, detalle, estadoRed, bloqueado, volver, navegar }: Props) {
  return <View style={s.header}>

    {pantalla !== 'inicio' && <Pressable
      accessibilityRole="button"
      accessibilityLabel="Volver"
      onPress={volver}
      disabled={bloqueado}
      style={s.iconButton}
    >
      <Icon name="arrow-left" />
    </Pressable>}

    <Text numberOfLines={1} style={s.headerTitle}>{detalle ? 'Detalle de recepción' : titulos[pantalla]}</Text>

    <Pressable
      accessibilityRole="button"
      accessibilityLabel="Ver estado de conexión"
      onPress={() => navegar('conexion')}
      style={s.connectionPill}
    >
      <Icon name="wifi" size={15} />
      <Text style={s.connectionLabel}>{estadoRed.includes('PostgreSQL conectado') ? 'Servidor' : 'Local'}</Text>
    </Pressable>

  </View>;
}
