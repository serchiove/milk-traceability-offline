import { Text, View } from 'react-native';
import { Button } from '../components/Button';
import { Icon } from '../components/Icon';
import type { LoteLocal } from '../model/lote';
import { mediciones } from '../model/mediciones';
import type { Pantalla } from '../navigation/routes';
import { screenStyles as s } from '../theme/screenStyles';
import { fecha, numero } from '../utils/formato';
type Props = {
  detalle: LoteLocal;
  guardado: boolean;
  columnas: boolean;
  navegar: (destino: Pantalla) => void;
};
export function DetalleScreen({ detalle, guardado, columnas, navegar }: Props) {
  return <>

    {guardado && <View accessibilityLiveRegion="polite" style={s.saved}>
      <Icon name="check" />
      <Text style={s.link}>Recepción guardada</Text>
    </View>}

    <Text style={s.eyebrow}>LOCAL · SIN ENVIAR</Text>
    <Text style={s.title}>{detalle.proveedor}</Text>
    <Text style={s.intro}>{fecha(detalle.fecha)}</Text>

    <View style={s.review}>
      <Text style={s.caption}>Vehículo</Text>
      <Text style={s.detailValue}>{detalle.vehiculo}</Text>
      <View style={s.divider} />
      <Text style={s.caption}>Centro de acopio</Text>
      <Text style={s.detailValue}>{detalle.centro}</Text>
    </View>

    <Text style={s.sectionTitle}>Mediciones registradas</Text>
    <View style={s.grid}>
      {mediciones.map(campo => <View key={campo.clave} style={[s.measurement, columnas && s.half]}>
        <Text style={s.caption}>{campo.titulo}</Text>
        <Text style={s.reviewValue}>{numero(detalle[campo.clave])} <Text style={s.unit}>{campo.unidad}</Text></Text>
      </View>)}
    </View>

    <Text style={s.saveNote}>Sin dictamen de calidad. El envío al servidor aún no está disponible.</Text>
    <Text style={s.label}>Identificador del registro</Text>
    <Text selectable style={s.uuid}>{detalle.id}</Text>

    <Button title="Nueva recepción" onPress={() => navegar('registro')} variant="outline" />

  </>;
}
