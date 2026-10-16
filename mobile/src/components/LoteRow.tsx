import { Pressable, Text, View } from 'react-native';
import type { LoteLocal } from '../model/lote';
import { screenStyles as s } from '../theme/screenStyles';
import { fecha, numero } from '../utils/formato';
import { Icon } from './Icon';
export function LoteRow({ lote, abrir }: {
  lote: LoteLocal;
  abrir: (lote: LoteLocal) => void;
}) {
  return <Pressable
    key={lote.id}
    accessibilityRole="button"
    accessibilityLabel={`Ver recepción de ${lote.proveedor}`}
    onPress={() => abrir(lote)}
    style={({ pressed }) => [s.record, pressed && s.pressed]}
  >

    <View style={s.recordIcon}>
      <Icon name="truck" size={21} />
    </View>

    <View style={s.flex}>
      <Text numberOfLines={1} style={s.recordTitle}>{lote.proveedor}</Text>
      <Text style={s.caption}>{lote.vehiculo} · {fecha(lote.fecha)}</Text>
      <Text style={s.local}>Local · Sin enviar</Text>
    </View>

    <View style={s.recordEnd}>
      <Text style={s.amount}>{numero(lote.volumen)} L</Text>
      <Icon name="chevron-right" size={18} />
    </View>

  </Pressable>;
}
