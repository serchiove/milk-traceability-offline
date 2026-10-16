import { ActivityIndicator, Text, TextInput, View } from 'react-native';
import { Button } from '../components/Button';
import { EmptyState } from '../components/EmptyState';
import { Icon } from '../components/Icon';
import { LoteRow } from '../components/LoteRow';
import type { LoteLocal } from '../model/lote';
import type { Pantalla } from '../navigation/routes';
import { screenStyles as s } from '../theme/screenStyles';
import { theme } from '../theme/theme';
import { numero } from '../utils/formato';
import type { LotesViewModel } from '../viewmodel/types';
type Props = {
  vm: LotesViewModel;
  pendientes: boolean;
  navegar: (destino: Pantalla) => void;
  abrir: (lote: LoteLocal) => void;
};
export function RegistrosScreen({ vm, pendientes, navegar, abrir }: Props) {
  return <>

    <Text style={s.title}>{pendientes ? 'Pendientes de envío' : 'Tus recepciones'}</Text>
    <Text style={s.intro}>Guardadas en este celular.</Text>

    <View style={s.search}>
      <Icon name="search" size={19} />
      <TextInput
        accessibilityLabel="Buscar por proveedor, placa, centro o identificador"
        value={vm.busqueda}
        onChangeText={vm.setBusqueda}
        placeholder="Proveedor, placa o identificador"
        placeholderTextColor={theme.colors.textMuted}
        autoCorrect={false}
        style={s.searchInput}
      />
    </View>

    {!!vm.busqueda && <Button title="Limpiar búsqueda" onPress={() => vm.setBusqueda('')} variant="ghost" />}

    <Text style={s.listCaption}>{vm.visibles.length} registros · {numero(vm.litrosVisibles)} L</Text>

    {vm.cargando ? <ActivityIndicator color={theme.colors.primary} /> : !vm.error && vm.visibles.length === 0 ? <EmptyState
      title={vm.busqueda ? 'Sin coincidencias' : 'Todavía no hay recepciones'}
      description={vm.busqueda ? 'Prueba con otro proveedor o placa.' : 'Registra una recepción para verla aquí.'}
      actionTitle={vm.busqueda ? 'Limpiar búsqueda' : 'Nueva recepción'}
      onAction={() => vm.busqueda ? vm.setBusqueda('') : navegar('registro')}
    /> : <View style={s.list}>
      {vm.visibles.map(lote => <LoteRow key={lote.id} lote={lote} abrir={abrir} />)}
    </View>}

    <Text style={s.footnote}>Desliza hacia abajo para actualizar.</Text>

  </>;
}
