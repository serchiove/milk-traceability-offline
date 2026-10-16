import { ActivityIndicator, Pressable, StyleSheet, Text, TextStyle, View, ViewStyle } from 'react-native';
import { theme } from '../theme/theme';
import { Icon } from './Icon';
type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
type Props = {
  title: string;
  onPress: () => void;
  variant?: ButtonVariant;
  disabled?: boolean;
  loading?: boolean;
  icon?: string;
  style?: ViewStyle;
  textStyle?: TextStyle;
  accessibilityLabel?: string;
};
export function Button({ title, onPress, variant = 'primary', disabled = false, loading = false, icon, style, textStyle, accessibilityLabel, }: Props) {
  const isInteractive = !disabled && !loading;
  const getContainerStyle = () => {
    switch(variant) {
      case 'primary':
        return [styles.base, styles.primary, disabled && styles.disabledPrimary];
      case 'secondary':
        return [styles.base, styles.secondary, disabled && styles.disabledSecondary];
      case 'outline':
        return [styles.base, styles.outline, disabled && styles.disabledOutline];
      case 'ghost':
        return [styles.base, styles.ghost, disabled && styles.disabledGhost];
      case 'danger':
        return [styles.base, styles.danger, disabled && styles.disabledPrimary];
      default:
        return [styles.base, styles.primary];
    }
  };
  const getTextStyle = () => {
    switch(variant) {
      case 'primary':
      case 'danger':
        return [styles.textPrimary];
      case 'secondary':
        return [styles.textSecondary];
      case 'outline':
        return [styles.textOutline, disabled && styles.textDisabled];
      case 'ghost':
        return [styles.textGhost, disabled && styles.textDisabled];
      default:
        return [styles.textPrimary];
    }
  };
  return (<Pressable
    accessibilityRole="button"
    accessibilityLabel={accessibilityLabel || title}
    accessibilityState={{ disabled: !isInteractive }}
    onPress={isInteractive ? onPress : undefined}
    style={({ pressed }) => [
      getContainerStyle(),
      pressed && isInteractive && styles.pressed,
      style,
    ]}
  >

    {loading ? (<View style={styles.content}>

      <ActivityIndicator size="small" color={variant === 'primary' || variant === 'danger' ? '#fff' : theme.colors.primary} />

      <Text style={[getTextStyle(), styles.loadingText, textStyle]}>{title}</Text>

    </View>) : (<View style={styles.content}>

      {icon ? <Icon name={icon} style={[styles.icon, getTextStyle()]} /> : null}

      <Text style={[getTextStyle(), textStyle]}>{title}</Text>

    </View>)}

  </Pressable>);
}
const styles = StyleSheet.create({
  base: {
    minHeight: 52,
    borderRadius: 14,
    paddingVertical: 13,
    paddingHorizontal: 18,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  primary: {
    backgroundColor: theme.colors.accent,
  },
  disabledPrimary: {
    opacity: 0.5,
  },
  secondary: {
    backgroundColor: theme.colors.primarySurface,
    borderWidth: 1,
    borderColor: theme.colors.primaryBorder,
  },
  disabledSecondary: {
    opacity: 0.5,
  },
  outline: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1.5,
    borderColor: theme.colors.border,
  },
  disabledOutline: {
    opacity: 0.5,
  },
  ghost: {
    backgroundColor: 'transparent',
  },
  disabledGhost: {
    opacity: 0.5,
  },
  danger: {
    backgroundColor: theme.colors.error,
  },
  pressed: {
    opacity: 0.85,
    transform: [{ scale: 0.99 }],
  },
  textPrimary: {
    color: theme.colors.textInverse,
    fontSize: 15, fontFamily: theme.typography.fontFamily,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  textSecondary: {
    color: theme.colors.primaryDark,
    fontSize: 15, fontFamily: theme.typography.fontFamily,
    fontWeight: '700',
  },
  textOutline: {
    color: theme.colors.textPrimary,
    fontSize: 15, fontFamily: theme.typography.fontFamily,
    fontWeight: '600',
  },
  textGhost: {
    color: theme.colors.primary,
    fontSize: 14, fontFamily: theme.typography.fontFamily,
    fontWeight: '600',
  },
  textDisabled: {
    color: theme.colors.textMuted,
  },
  loadingText: {
    marginLeft: 8,
  },
  icon: {
    fontSize: 16, fontFamily: theme.typography.fontFamily,
    marginRight: 4,
  },
});
