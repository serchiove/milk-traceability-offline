import { StyleSheet, Text, View, ViewStyle } from 'react-native';
import { theme } from '../theme/theme';
import { Button } from './Button';
import { Icon } from './Icon';
type Props = {
  title: string;
  description: string;
  actionTitle?: string;
  onAction?: () => void;
  icon?: string;
  style?: ViewStyle;
};
export function EmptyState({ title, description, actionTitle, onAction, icon = '📂', style, }: Props) {
  return (<View style={[styles.container, style]}>

    <View style={styles.iconCircle}>

      <Icon name={icon} style={styles.icon} />

    </View>

    <Text style={styles.title}>{title}</Text>

    <Text style={styles.description}>{description}</Text>

    {actionTitle && onAction ? (<Button title={actionTitle} onPress={onAction} variant="primary" style={styles.button} />) : null}

  </View>);
}
const styles = StyleSheet.create({
  container: {
    padding: theme.spacing.xl,
    borderRadius: theme.radii.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.borderLight,
    alignItems: 'center',
    marginVertical: theme.spacing.md,
  },
  iconCircle: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: theme.colors.surfaceSubtle,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme.spacing.md,
  },
  icon: {
    fontSize: 26, fontFamily: theme.typography.headingFamily,
  },
  title: {
    fontSize: 17, fontFamily: theme.typography.fontFamily,
    fontWeight: '700',
    color: theme.colors.textPrimary,
    textAlign: 'center',
    marginBottom: 6,
  },
  description: {
    fontSize: 14, fontFamily: theme.typography.fontFamily,
    color: theme.colors.textSecondary,
    textAlign: 'center',
    lineHeight: 21,
    marginBottom: theme.spacing.md,
  },
  button: {
    marginTop: theme.spacing.sm,
    width: '100%',
  },
});
