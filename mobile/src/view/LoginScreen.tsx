import { StatusBar } from 'expo-status-bar';
import { Keyboard, KeyboardAvoidingView, Platform, Pressable, ScrollView, Text, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Button } from '../components/Button';
import { Icon } from '../components/Icon';
import { NoticeBox } from '../components/NoticeBox';
import type { SesionOperario } from '../services/authService';
import { theme } from '../theme/theme';
import { useLoginViewModel } from '../viewmodel/useLoginViewModel';
import { styles as s } from './styles/LoginScreen.styles';
type Props = {
  onAcceso: (sesion: SesionOperario) => void;
  onLocal: () => void;
};
export function LoginScreen({ onAcceso, onLocal }: Props) {
  const vm = useLoginViewModel();
  async function entrar() {
    Keyboard.dismiss(); const sesion = await vm.entrar(); if(sesion)
      onAcceso(sesion);
  }
  return <SafeAreaView style={s.root}>
    <StatusBar style="dark" />
    <KeyboardAvoidingView style={s.root} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>

      <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={s.page}>

        <View style={s.brandRow}>
          <Icon name="droplet" size={22} />
          <View>
            <Text style={s.brand}>GLORIA</Text>
            <Text style={s.brandCaption}>ACOPIO DE LECHE</Text>
          </View>
        </View>

        <View style={s.symbol}>
          <Icon name="droplet" size={45} />
        </View>

        <Text style={s.title}>La calidad empieza{"\n"}en la recepción.</Text>
        <Text style={s.description}>Recepción y trazabilidad de leche Gloria.</Text>

        <Text style={s.label}>Correo electrónico</Text>

        <TextInput
          accessibilityLabel="Correo electrónico"
          editable={!vm.ocupado}
          value={vm.email}
          onChangeText={vm.cambiarEmail}
          keyboardType="email-address"
          autoCapitalize="none"
          autoCorrect={false}
          autoComplete="email"
          placeholder="operario@ejemplo.com"
          placeholderTextColor={theme.colors.textMuted}
          maxLength={150}
          style={[s.input, !!vm.errores.email && s.inputError]}
        />

        {!!vm.errores.email && <Text accessibilityLiveRegion="polite" style={s.error}>{vm.errores.email}</Text>}

        <Text style={s.label}>Contraseña</Text>

        <View style={[s.passwordRow, !!vm.errores.password && s.inputError]}>
          <TextInput
            accessibilityLabel="Contraseña"
            editable={!vm.ocupado}
            value={vm.password}
            onChangeText={vm.cambiarPassword}
            secureTextEntry={!vm.visible}
            autoCapitalize="none"
            autoCorrect={false}
            autoComplete="current-password"
            placeholder="Tu contraseña"
            placeholderTextColor={theme.colors.textMuted}
            maxLength={256}
            onSubmitEditing={entrar}
            returnKeyType="go"
            style={s.passwordInput}
          />
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={vm.visible ? 'Ocultar contraseña' : 'Mostrar contraseña'}
            onPress={vm.alternarVisible}
            disabled={vm.ocupado}
            style={s.eye}
          >
            <Icon name={vm.visible ? 'eye-off' : 'eye'} size={20} />
          </Pressable>
        </View>

        {!!vm.errores.password && <Text accessibilityLiveRegion="polite" style={s.error}>{vm.errores.password}</Text>}

        {!!vm.error && <NoticeBox variant="error" message={vm.error} />}

        <View style={s.actions}>
          <Button title="Iniciar sesión" onPress={entrar} loading={vm.ocupado} disabled={vm.ocupado} />
          <Button
            title="Recuperar acceso offline autorizado"
            onPress={() => { Keyboard.dismiss(); onLocal(); }}
            variant="outline"
            disabled={vm.ocupado}
          />
        </View>

        <Text style={s.help}>El primer acceso requiere conexión para descargar los catálogos. Después podrás capturar sin red mientras tu sesión autorizada siga vigente.</Text>

        <Text style={s.footer}>Para solicitar acceso, contacta con tu administrador.</Text>

      </ScrollView>

    </KeyboardAvoidingView>
  </SafeAreaView>;
}
