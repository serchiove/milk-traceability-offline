import { Text, View } from 'react-native';
import { Button } from '../components/Button';
import { Icon } from '../components/Icon';
import { SettingsRow } from '../components/SettingsRow';
import type { Pantalla } from '../navigation/routes';
import type { SesionOperario } from '../services/authService';
import { screenStyles as s } from '../theme/screenStyles';
import { theme } from '../theme/theme';
type Props = {
  sesion: SesionOperario | null;
  cantidad: number;
  navegar: (destino: Pantalla) => void;
  solicitarSalida: () => void;
};
export function PerfilScreen({ sesion, cantidad, navegar, solicitarSalida }: Props) {
  return <>

    <View style={s.profile}>
      <View style={s.avatar}>
        <Icon name="user" size={30} color={theme.colors.primary} />
      </View>
      <Text style={s.title}>{sesion ? sesion.usuario.nombre : 'Modo local'}</Text>
      <Text style={s.intro}>{sesion ? sesion.usuario.centro : 'Sin sesión central autenticada'}</Text>
    </View>

    <Text style={s.sectionTitle}>Dispositivo y conexión</Text>
    <View style={s.list}>
      <SettingsRow
        titulo="Conexión al servidor"
        descripcion="Consulta la disponibilidad del servicio"
        destino="conexion"
        navegar={navegar}
      />
      <SettingsRow
        titulo="Pendientes de envío"
        descripcion={`${cantidad} borradores locales`}
        destino="pendientes"
        navegar={navegar}
      />
      <SettingsRow
        titulo="Buscar por identificador"
        descripcion="Consulta por UUID o escanea un QR"
        destino="trazabilidad"
        navegar={navegar}
      />
    </View>

    <Text style={s.sectionTitle}>Servicios de planta</Text>
    <SettingsRow titulo="Catálogos de recepción" descripcion="Proveedores, vehículos y tu centro" destino="catalogos" navegar={navegar} />
    <View style={s.list}>
      <SettingsRow
        titulo="Resultados de calidad"
        descripcion="Consulta central actualizada"
        destino="calidad"
        navegar={navegar}
      />
      <SettingsRow
        titulo="Tanques de destino"
        descripcion="Consulta central actualizada"
        destino="tanque"
        navegar={navegar}
      />
    </View>

    <Text style={s.footnote}>Las nuevas recepciones quedan asociadas a tu usuario y centro. El envío se confirma desde cada recepción.</Text>
    <Button
      title={sesion ? 'Cerrar sesión' : 'Volver al acceso'}
      onPress={solicitarSalida}
      variant="outline"
    />

  </>;
}
