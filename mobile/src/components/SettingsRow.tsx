import { Pressable, Text, View } from 'react-native';
import type { Pantalla } from '../navigation/routes';
import { screenStyles as s } from '../theme/screenStyles';
import { Icon } from './Icon';
export function SettingsRow({ titulo, descripcion, destino, navegar, icono = 'chevron-right' }: {
  titulo: string;
  descripcion: string;
  destino: Pantalla;
  navegar: (destino: Pantalla) => void;
  icono?: string;
}) {
  return <Pressable accessibilityRole="button" onPress={() => navegar(destino)} style={s.settingsRow}>
    <View style={s.flex}>
      <Text style={s.recordTitle}>{titulo}</Text>
      <Text style={s.caption}>{descripcion}</Text>
    </View>
    <Icon name={icono} size={19} />
  </Pressable>;
}
