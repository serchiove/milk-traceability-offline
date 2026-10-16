import { useState } from 'react';
import type { ViewStyle } from 'react-native';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { theme } from '../theme/theme';
import { Icon } from './Icon';
export type NoticeVariant = 'info' | 'warning' | 'error' | 'success' | 'neutral';
type Props = {
  message: string;
  variant?: NoticeVariant;
  title?: string;
  style?: ViewStyle;
};
export function NoticeBox({ message, variant = 'info', title, style }: Props) {
  const [expandido, setExpandido] = useState(false);
  const plegable = variant === 'info' || variant === 'neutral';
  const color = variant === 'error' ? theme.colors.error : variant === 'warning' ? theme.colors.warning : theme.colors.textSecondary;
  const fondo = variant === 'error' ? theme.colors.errorSurface : variant === 'warning' ? theme.colors.warningSurface : variant === 'success' ? theme.colors.primarySurface : 'transparent';
  if(plegable)
    return <View style={[s.help, style]}>

      <Pressable
        accessibilityRole="button"
        accessibilityState={{ expanded: expandido }}
        onPress={() => setExpandido(valor => !valor)}
        style={s.helpAction}
      >

        <Icon name="ℹ" size={17} color={theme.colors.textMuted} />
        <Text style={s.helpLabel}>{title || 'Información del registro'}</Text>
        <Text style={s.chevron}>{expandido ? '−' : '+'}</Text>

      </Pressable>

      {expandido && <Text style={s.message}>{message}</Text>}

    </View>;
  return <View
    accessibilityRole={variant === 'error' ? 'alert' : undefined}
    accessibilityLiveRegion="polite"
    style={[s.box, { backgroundColor: fondo }, style]}
  >

    {title && <Text style={[s.title, { color }]}>{title}</Text>}

    <Text style={[s.message, { color }]}>{message}</Text>

  </View>;
}
const s = StyleSheet.create({ help: { marginVertical: 6 }, helpAction: { flexDirection: 'row', alignItems: 'center', minHeight: 44, gap: 8 }, helpLabel: { flex: 1, fontSize: 13, fontFamily: theme.typography.fontFamily, color: theme.colors.textSecondary }, chevron: { fontSize: 20, fontFamily: theme.typography.headingFamily, color: theme.colors.textMuted }, box: { borderRadius: 10, padding: 12, marginVertical: 8 }, title: { fontSize: 14, fontFamily: theme.typography.fontFamily, fontWeight: '600', marginBottom: 4 }, message: { fontSize: 13, fontFamily: theme.typography.fontFamily, lineHeight: 20, color: theme.colors.textSecondary, paddingBottom: 2 } });
