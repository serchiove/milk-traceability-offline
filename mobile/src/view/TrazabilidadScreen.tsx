import { Keyboard, Text, TextInput, View } from 'react-native';
import { Button } from '../components/Button';
import { LoteRow } from '../components/LoteRow';
import type { LoteLocal } from '../model/lote';
import { screenStyles as s } from '../theme/screenStyles';
import type { LotesViewModel } from '../viewmodel/types';
type Props = {
  vm: LotesViewModel;
  codigo: string;
  consultado: string | null;
  setCodigo: (valor: string) => void;
  setConsultado: (valor: string | null) => void;
  abrir: (lote: LoteLocal) => void;
};
export function TrazabilidadScreen({ vm, codigo, consultado, setCodigo, setConsultado, abrir }: Props) {
  return <>

    <Text style={s.title}>Encuentra una recepción</Text>
    <Text style={s.intro}>Pega el identificador completo de un registro guardado en este celular.</Text>
    <TextInput
      accessibilityLabel="Identificador completo del registro"
      value={codigo}
      onChangeText={valor => { setCodigo(valor); setConsultado(null); }}
      autoCapitalize="none"
      autoCorrect={false}
      placeholder="UUID del registro"
      style={s.plainInput}
    />
    <Button
      title="Buscar registro"
      onPress={() => { Keyboard.dismiss(); setConsultado(codigo.trim().toLowerCase()); }}
      disabled={!codigo.trim() || vm.cargando}
    />
    {consultado !== null && (vm.lotes.find(l => l.id.toLowerCase() === consultado) ? <View style={s.list}>
      <LoteRow lote={vm.lotes.find(l => l.id.toLowerCase() === consultado)!} abrir={abrir} />
    </View> : <Text accessibilityLiveRegion="polite" style={s.saveNote}>No se encontró ese identificador en este dispositivo.</Text>)}
    <Text style={s.footnote}>La lectura de QR y la trazabilidad central aún no están disponibles.</Text>

  </>;
}
