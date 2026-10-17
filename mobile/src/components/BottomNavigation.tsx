import { Keyboard, Pressable, StyleSheet, Text, View } from 'react-native';
import { theme } from '../theme/theme';
import { Icon } from './Icon';
export type DestinoPrincipal = 'inicio' | 'lotes' | 'perfil';
export function BottomNavigation({ actual, cambiar }: {
  actual: string;
  cambiar: (destino: DestinoPrincipal) => void;
}) {
  const seleccionado = actual === 'registro' ? 'inicio' : ['conexion', 'pendientes', 'calidad', 'trazabilidad', 'tanque', 'catalogos'].includes(actual) ? 'perfil' : actual;
  return <View accessibilityRole="tablist" style={s.bar}>

    {([['inicio', 'Inicio', 'home'], ['lotes', 'Registros', 'clipboard'], ['perfil', 'Perfil', 'user']] as const).map(([id, titulo, icono]) => <Pressable
      key={id}
      accessibilityRole="tab"
      accessibilityState={{ selected: seleccionado === id }}
      onPress={() => { Keyboard.dismiss(); cambiar(id); }}
      style={s.item}
    >

      <Icon
        name={icono}
        size={23}
        color={seleccionado === id ? theme.colors.primary : theme.colors.textMuted}
      />

      <Text style={[s.label, seleccionado === id && s.selected]}>{titulo}</Text>

      {seleccionado === id && <View style={s.dot} />}

    </Pressable>)}

  </View>;
}
const s = StyleSheet.create({ bar: { flexDirection: 'row', borderTopWidth: 1, borderTopColor: theme.colors.borderLight, backgroundColor: theme.colors.surface, paddingVertical: 8 }, item: { flex: 1, minHeight: 58, alignItems: 'center', justifyContent: 'center', gap: 5 }, label: { fontSize: 12, fontFamily: theme.typography.fontFamily, color: theme.colors.textMuted }, selected: { color: theme.colors.primary, fontWeight: '700' }, dot: { width: 4, height: 4, borderRadius: 2, backgroundColor: theme.colors.primary } });
