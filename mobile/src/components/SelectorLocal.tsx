import { useState } from 'react';
import { Modal, Pressable, ScrollView, Text, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Button } from './Button';
import { Icon } from './Icon';
import { NoticeBox } from './NoticeBox';
import { theme } from '../theme/theme';
import { styles as s } from './styles/SelectorLocal.styles';
type Props = {
  titulo: string;
  valor: string;
  opciones: string[];
  placeholder: string;
  error?: string;
  bloqueado: boolean;
  mayusculas?: boolean;
  cambiar: (valor: string) => void;
};
const normalizar = (valor: string) => valor
  .normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '')
  .toLowerCase()
  .trim();
export function SelectorLocal({ titulo, valor, opciones, placeholder, error, bloqueado, mayusculas, cambiar, }: Props) {
  const [abierto, setAbierto] = useState(false);
  const [busqueda, setBusqueda] = useState('');
  const visibles = opciones.filter(opcion => normalizar(opcion).includes(normalizar(busqueda)));
  function cerrar() {
    setAbierto(false);
    setBusqueda('');
  }
  return (<View style={s.field}>

    <Text style={s.label}>
      {titulo} <Text style={s.required}>*</Text>
    </Text>

    <TextInput
      accessibilityLabel={titulo}
      editable={!bloqueado}
      value={valor}
      onChangeText={cambiar}
      placeholder={placeholder}
      placeholderTextColor={theme.colors.textMuted}
      autoCapitalize={mayusculas ? 'characters' : 'sentences'}
      autoCorrect={false}
      maxLength={180}
      style={[s.input, !!error && s.inputError]}
    />

    {!!error && (<View style={s.errorContainer}>

      <Icon style={s.errorIcon} name="✕" />

      <Text accessibilityLiveRegion="polite" style={s.error}>
        {error}
      </Text>

    </View>)}

    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`Elegir ${titulo.toLowerCase()} de registros anteriores`}
      disabled={bloqueado}
      onPress={() => {
        setBusqueda('');
        setAbierto(true);
      }}
      style={s.linkButton}
    >

      <Text style={s.linkText}>
        Elegir de historial local ({opciones.length})
      </Text>

    </Pressable>

    <Modal visible={abierto} animationType="slide" onRequestClose={cerrar}>

      <SafeAreaView style={s.root} edges={['top', 'bottom', 'left', 'right']}>

        <View style={s.modalHeader}>

          <View style={s.modalTitleContainer}>

            <Text style={s.eyebrow}>HISTORIAL LOCAL</Text>

            <Text style={s.title}>{titulo}</Text>

          </View>

          <Button title="Cerrar" onPress={cerrar} variant="outline" style={s.closeButton} />

        </View>

        <NoticeBox
          variant="info"
          message="Sugerencias obtenidas únicamente de registros guardados en este celular. No constituyen un catálogo oficial validado por el servidor."
          style={s.modalNotice}
        />

        <View style={s.searchContainer}>

          <TextInput
            accessibilityLabel={`Buscar ${titulo.toLowerCase()} en el historial local`}
            value={busqueda}
            onChangeText={setBusqueda}
            placeholder="Buscar coincidencia..."
            placeholderTextColor={theme.colors.textMuted}
            autoCapitalize="none"
            autoCorrect={false}
            style={s.searchInput}
          />

        </View>

        <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={s.options}>

          {visibles.map(opcion => (<Pressable
            accessibilityRole="button"
            accessibilityLabel={`Seleccionar ${opcion}`}
            key={opcion}
            onPress={() => {
              cambiar(opcion);
              cerrar();
            }}
            style={({ pressed }) => [s.option, pressed && s.optionPressed]}
          >

            <View style={s.optionContent}>

              <Text style={s.optionBullet}>•</Text>

              <Text style={s.optionText}>{opcion}</Text>

            </View>

            <Text style={s.selectAction}>Usar valor →</Text>

          </Pressable>))}

          {visibles.length === 0 && (<View style={s.emptyContainer}>

            <Icon style={s.emptyIcon} name="🔍" />

            <Text style={s.emptyText}>
              {opciones.length === 0
                ? 'Aún no hay valores previos registrados en este celular. Puedes ingresar el dato manualmente en el formulario.'
                : 'No hay sugerencias que coincidan con la búsqueda. Puedes ingresar un nuevo valor en el formulario.'}
            </Text>

          </View>)}

        </ScrollView>

      </SafeAreaView>

    </Modal>

  </View>);
}
