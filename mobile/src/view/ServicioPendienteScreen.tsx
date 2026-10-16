import { Text, View } from 'react-native';
import { Button } from '../components/Button';
import { Icon } from '../components/Icon';
import type { Pantalla } from '../navigation/routes';
import { screenStyles as s } from '../theme/screenStyles';
type Props = {
  pantalla: 'calidad' | 'tanque';
  navegar: (destino: Pantalla) => void;
};
export function ServicioPendienteScreen({ pantalla, navegar }: Props) {
  return <>

    <View style={s.largeIcon}>
      <Icon name={pantalla === 'calidad' ? '🔬' : '🛢️'} size={34} />
    </View>
    <Text style={s.title}>{pantalla === 'calidad' ? 'Resultados de calidad' : 'Destino de la recepción'}</Text>
    <Text style={s.intro}>{pantalla === 'calidad' ? 'Los resultados aparecerán cuando el servidor evalúe la recepción.' : 'La asignación se habilitará cuando existan lotes aprobados y un catálogo de tanques.'}</Text>
    <View style={s.review}>
      <Text style={s.recordTitle}>Pendiente de integración</Text>
      <Text style={s.intro}>{pantalla === 'calidad' ? 'Las mediciones locales todavía no tienen un dictamen de aprobación o rechazo.' : 'Todavía no hay capacidad ni disponibilidad de tanques conectada a esta app.'}</Text>
    </View>
    <Button title="Ver mis registros" onPress={() => navegar('lotes')} variant="outline" />

  </>;
}
