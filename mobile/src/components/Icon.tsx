import Feather from '@expo/vector-icons/Feather';
import type { ComponentProps } from 'react';
import type { StyleProp, TextStyle } from 'react-native';
import { theme } from '../theme/theme';
const nombres: Record<string, ComponentProps<typeof Feather>['name']> = {
  '🥛': 'droplet', '🏠': 'home', '➕': 'plus', '📋': 'clipboard', '📶': 'wifi',
  '📡': 'wifi', '🚛': 'truck', '🧪': 'thermometer', '🔬': 'activity', '🔍': 'search',
  '🛢️': 'database', '📊': 'bar-chart-2', '⏳': 'clock', '📱': 'smartphone',
  '📂': 'folder', '🔄': 'refresh-cw', '📍': 'map-pin', '⚠️': 'alert-triangle',
  '🛑': 'alert-circle', '✅': 'check-circle', 'ℹ️': 'info', 'ℹ': 'info',
  'eye': 'eye', 'eye-off': 'eye-off', 'home': 'home', 'clipboard': 'clipboard', 'plus': 'plus', 'arrow-left': 'arrow-left', 'arrow-right': 'arrow-right', 'chevron-right': 'chevron-right', 'wifi': 'wifi', 'search': 'search', 'truck': 'truck', 'droplet': 'droplet', 'check': 'check', 'log-out': 'log-out', 'refresh-cw': 'refresh-cw', 'user': 'user', '✓': 'check', '✕': 'x', '•': 'minus',
};
export function Icon({ name, size = 20, color = theme.colors.primary, style }: {
  name: string;
  size?: number;
  color?: string;
  style?: StyleProp<TextStyle>;
}) {
  return <Feather
    name={nombres[name] ?? 'circle'}
    size={size}
    color={color}
    style={style}
    accessible={false}
  />;
}
