import { Alert, Text, TextInput, View } from 'react-native';
import {NoticeBox} from '../components/NoticeBox';
import { Button } from '../components/Button';
import { mediciones } from '../model/mediciones';
import { screenStyles as s } from '../theme/screenStyles';
import { theme } from '../theme/theme';
import { numero } from '../utils/formato';
import type { LotesViewModel } from '../viewmodel/types';
import { SelectorLocal } from '../components/SelectorLocal';
type Props = {
  vm: LotesViewModel;
  paso: number;
  columnas: boolean;
  siguiente: () => void;
  guardar: () => Promise<void>;
  volver: () => void;
  descartarEdicion: () => Promise<void>;
};
export function RegistroScreen({ vm, paso, columnas, siguiente, guardar, volver, descartarEdicion }: Props) {
  const bloqueado = vm.guardando || !vm.listoEdicion;
  function descartar() {
    Alert.alert('Descartar recepción en edición', 'Se borrarán solo estos campos. Los lotes confirmados no se modifican.', [{text: 'Conservar', style: 'cancel'}, {text: 'Descartar', style: 'destructive', onPress: () => {void descartarEdicion();}}]);
  }
  return <>
    {vm.estadoEdicion === 'error' ? <><NoticeBox variant="error" message={vm.listoEdicion ? 'No se pudo guardar la última edición. Tus campos siguen aquí; reintenta antes de cerrar.' : 'No se pudo recuperar la recepción anterior. Reintenta para evitar sobrescribirla.'}/><Button title="Reintentar" variant="outline" onPress={vm.reintentarEdicion}/></> : <Text accessibilityLiveRegion="polite" style={s.caption}>{!vm.listoEdicion ? 'Recuperando recepción…' : vm.recuperado ? 'Recepción recuperada de este celular' : vm.estadoEdicion === 'guardando' ? 'Guardando cambios…' : 'Guardado automático en este celular'}</Text>}


    <View style={s.steps}>
      {['Origen', 'Mediciones', 'Revisión'].map((titulo, i) => <View key={titulo} style={s.step}>
        <View style={[s.stepLine, i <= paso && s.stepLineActive]} />
        <Text style={[s.stepLabel, i === paso && s.stepLabelActive]}>{i + 1}. {titulo}</Text>
      </View>)}
    </View>

    <Text style={s.title}>{['¿De dónde viene?', 'Registra las mediciones', 'Todo listo para revisar'][paso]}</Text>
    <Text style={s.intro}>{['Identifica al proveedor y el punto de recepción.', 'Ingresa las lecturas tomadas durante la recepción.', 'Comprueba los datos antes de guardarlos en este celular.'][paso]}</Text>

    {paso === 0 && <View style={s.form}>

      <SelectorLocal
        titulo="Proveedor"
        valor={vm.form.proveedor}
        opciones={vm.sugerencias.proveedor}
        placeholder="Nombre o código del proveedor"
        error={vm.errores.proveedor}
        bloqueado={bloqueado}
        cambiar={valor => vm.cambiar('proveedor', valor)}
      />

      <SelectorLocal
        titulo="Placa del vehículo"
        valor={vm.form.vehiculo}
        opciones={vm.sugerencias.vehiculo}
        placeholder="ABC-123"
        error={vm.errores.vehiculo}
        bloqueado={bloqueado}
        mayusculas
        cambiar={valor => vm.cambiar('vehiculo', valor)}
      />

      <SelectorLocal
        titulo="Centro de acopio"
        valor={vm.form.centro}
        opciones={vm.sugerencias.centro}
        placeholder="Nombre del centro"
        error={vm.errores.centro}
        bloqueado={bloqueado}
        cambiar={valor => vm.cambiar('centro', valor)}
      />

      <Text style={s.caption}>El historial contiene datos ingresados en este celular.</Text>

    </View>}

    {paso === 1 && <>
      <View style={s.grid}>
        {mediciones.map(campo => <View key={campo.clave} style={[s.measurement, columnas && s.half]}>
          <Text style={s.label}>{campo.titulo}</Text>
          <View style={[s.measurementInput, !!vm.errores[campo.clave] && s.inputError]}>
            <TextInput
              accessibilityLabel={`${campo.titulo} en ${campo.unidad}`}
              value={vm.form[campo.clave]}
              onChangeText={valor => vm.cambiar(campo.clave, valor)}
              editable={!bloqueado}
              maxLength={18}
              keyboardType="numbers-and-punctuation"
              autoCorrect={false}
              placeholder={campo.ejemplo}
              placeholderTextColor={theme.colors.textMuted}
              style={s.numberInput}
            />
            <Text style={s.unit}>{campo.unidad}</Text>
          </View>
          {!!vm.errores[campo.clave] && <Text accessibilityLiveRegion="polite" style={s.error}>{vm.errores[campo.clave]}</Text>}
        </View>)}
      </View>
      <Text style={s.caption}>Usa coma o punto decimal. Los ejemplos no son límites de aprobación.</Text>
    </>}

    {paso === 2 && <>
      <View style={s.review}>
        <Text style={s.reviewProvider}>{vm.form.proveedor.trim()}</Text>
        <Text style={s.intro}>{vm.form.vehiculo.trim().toUpperCase()} · {vm.form.centro.trim()}</Text>
        <View style={s.grid}>
          {mediciones.map(campo => <View key={campo.clave} style={[s.reviewMetric, columnas && s.half]}>
            <Text style={s.caption}>{campo.titulo}</Text>
            <Text style={s.reviewValue}>{numero(Number(vm.form[campo.clave].replace(',', '.')))} <Text style={s.unit}>{campo.unidad}</Text></Text>
          </View>)}
        </View>
      </View>
      <Text style={s.saveNote}>Se guardará como borrador local, sin enviar ni evaluar la calidad.</Text>
    </>}

    <View style={s.actions}>
      <Button
        title={paso === 2 ? 'Guardar recepción' : 'Continuar'}
        onPress={paso === 2 ? guardar : siguiente}
        loading={vm.guardando}
        disabled={bloqueado}
      />
      {paso > 0 && <Button title="Volver al paso anterior" onPress={volver} variant="ghost" disabled={bloqueado} />}
    </View>

    {vm.tieneCambios && <Button title="Descartar recepción en edición" onPress={descartar} variant="ghost" disabled={bloqueado}/>}
  </>;
}
