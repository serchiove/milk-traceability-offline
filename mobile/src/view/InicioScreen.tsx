import { Pressable, Text, View } from 'react-native';
import { Icon } from '../components/Icon';
import { LoteRow } from '../components/LoteRow';
import type { LoteLocal } from '../model/lote';
import type { Pantalla } from '../navigation/routes';
import { screenStyles as s } from '../theme/screenStyles';
import { numero } from '../utils/formato';
import type { LotesViewModel } from '../viewmodel/types';
type Props = {
  vm: LotesViewModel;
  navegar: (destino: Pantalla) => void;
  abrir: (lote: LoteLocal) => void;
};
export function InicioScreen({ vm, navegar, abrir }: Props) {
  const litros = vm.lotes.reduce((total, lote) => total + Math.round(lote.volumen * 100), 0) / 100;
  return <>

    <Text style={s.eyebrow}>LECHE GLORIA · RECEPCIÓN</Text>
    <Text style={s.heroTitle}>Cada recepción,{"\n"}un paso más claro.</Text>

    <Text style={s.intro}>Registra en el momento. Conserva los datos en tu celular.</Text>

    <Pressable
      accessibilityRole="button"
      onPress={() => navegar('registro')}
      style={({ pressed }) => [s.heroAction, pressed && s.heroPressed]}
    >
      <View style={s.plus}>
        <Icon name="plus" color="#fff" size={26} />
      </View>
      <View style={s.flex}>
        <Text style={s.heroActionTitle}>{vm.tieneCambios ? 'Continuar recepción' : 'Nueva recepción'}</Text>
        <Text style={s.heroActionCaption}>Origen, mediciones y confirmación</Text>
      </View>
      <Icon name="arrow-right" color="#fff" />
    </Pressable>

    {vm.recuperado && <Text style={s.caption}>Tienes una recepción recuperada para continuar.</Text>}
    <View style={s.stats}>
      <View style={s.flex}>
        <Text style={s.statValue}>{vm.cargando ? '—' : vm.error ? '—' : vm.lotes.length}</Text>
        <Text style={s.caption}>Registros locales</Text>
      </View>
      <View style={s.statDivider} />
      <View style={s.flex}>
        <Text style={s.statValue}>{vm.cargando || vm.error ? '—' : numero(litros)} <Text style={s.statUnit}>L</Text></Text>
        <Text style={s.caption}>Acumulado local</Text>
      </View>
    </View>

    <View style={s.sectionHeading}>
      <Text style={s.sectionTitle}>Últimas recepciones</Text>
      <Pressable accessibilityRole="button" onPress={() => navegar('lotes')} style={s.textButton}>
        <Text style={s.link}>Ver todas</Text>
      </Pressable>
    </View>

    {!vm.cargando && !vm.error && vm.lotes.length === 0 ? <View style={s.quietEmpty}>
      <Icon name="droplet" size={32} />
      <Text style={s.recordTitle}>Tu primera recepción empieza aquí</Text>
      <Text style={s.caption}>Los lotes guardados aparecerán en esta lista.</Text>
    </View> : <View style={s.list}>
      {vm.lotes.slice(0, 3).map(lote => <LoteRow key={lote.id} lote={lote} abrir={abrir} />)}
    </View>}

  </>;
}
