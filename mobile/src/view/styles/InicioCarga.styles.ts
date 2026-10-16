import { StyleSheet } from 'react-native';
import { theme } from '../../theme/theme';
const c = theme.colors;
export const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: c.surface,
    padding: 24
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center'
  },
  emblem: {
    width: 124,
    height: 124,
    borderRadius: 62,
    backgroundColor: c.surfaceMuted,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 28
  },
  inner: {
    width: 90,
    height: 90,
    borderRadius: 32,
    backgroundColor: c.primarySurface,
    justifyContent: 'center',
    alignItems: 'center'
  },
  brand: {
    fontFamily: theme.typography.headingFamily,
    fontSize: 38,
    fontWeight: '700',
    color: c.accent,
    letterSpacing: 2
  },
  line: {
    width: 36,
    height: 3,
    borderRadius: 2,
    backgroundColor: c.accent,
    marginVertical: 16
  },
  product: {
    fontFamily: theme.typography.fontFamily,
    fontSize: 12,
    letterSpacing: 2,
    fontWeight: '600',
    color: c.primary
  },
  subtitle: {
    fontFamily: theme.typography.fontFamily,
    fontSize: 14,
    color: c.textMuted,
    marginTop: 12
  },
  status: {
    width: '100%',
    maxWidth: 340,
    gap: 16,
    marginTop: 54
  },
  message: {
    fontFamily: theme.typography.fontFamily,
    fontSize: 13,
    lineHeight: 21,
    color: c.textMuted,
    textAlign: 'center'
  },
  errorTitle: {
    fontFamily: theme.typography.fontFamily,
    fontSize: 17,
    lineHeight: 24,
    fontWeight: '600',
    color: c.textPrimary,
    textAlign: 'center'
  },
  footer: {
    fontFamily: theme.typography.fontFamily,
    fontSize: 11,
    color: c.textMuted,
    textAlign: 'center',
    paddingBottom: 16
  }
});
