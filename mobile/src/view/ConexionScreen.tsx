import { Text, View } from 'react-native';
import { Button } from '../components/Button';
import { Icon } from '../components/Icon';
import { screenStyles as s } from '../theme/screenStyles';
import type { EntornoViewModel } from '../viewmodel/types';
type Props = {
  red: EntornoViewModel;
};
export function ConexionScreen({ red }: Props) {
  return <>

    <View style={s.largeIcon}>
      <Icon name="wifi" size={34} />
    </View>
    <Text style={s.title}>Conexión al servidor</Text>
    <Text style={s.intro}>Puedes seguir registrando aunque el servidor no esté disponible.</Text>
    <View style={s.review}>
      <Text style={s.caption}>Estado de la última comprobación</Text>
      <Text accessibilityLiveRegion="polite" style={s.detailValue}>{red.estado}</Text>
    </View>
    <Button
      title="Comprobar conexión"
      onPress={red.comprobarApi}
      loading={red.busy}
      disabled={red.busy}
    />
    <Text style={s.footnote}>Esta consulta no envía tus registros. Puedes enviar cada recepción desde su detalle con una sesión de operario.</Text>

  </>;
}
