import { StyleSheet } from 'react-native';
import { theme } from '../../theme/theme';
const c = theme.colors;
export const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: c.background
  },
  page: {
    padding: 24,
    paddingBottom: 32,
    flexGrow: 1
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 28
  },
  brandCaption: {
    fontSize: 10,
    fontFamily: theme.typography.fontFamily,
    letterSpacing: 2,
    color: c.textMuted,
    marginTop: 2
  },
  brand: {
    fontSize: 29,
    fontFamily: theme.typography.headingFamily,
    fontWeight: '700',
    color: c.accent,
    letterSpacing: 1
  },
  symbol: {
    borderWidth: 1,
    borderColor: c.primaryBorder,
    width: 86,
    height: 86,
    backgroundColor: c.primarySurface,
    borderRadius: 28,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 24
  },
  title: {
    fontSize: 30,
    fontFamily: theme.typography.headingFamily,
    lineHeight: 38,
    letterSpacing: -0.3,
    fontWeight: '700',
    color: c.textPrimary
  },
  description: {
    fontSize: 15,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 23,
    color: c.textSecondary,
    marginTop: 10,
    marginBottom: 24
  },
  label: {
    fontSize: 13,
    fontFamily: theme.typography.fontFamily,
    fontWeight: '600',
    color: c.textPrimary,
    marginBottom: 9,
    marginTop: 14
  },
  input: {
    minHeight: 54,
    fontSize: 15,
    fontFamily: theme.typography.fontFamily,
    padding: 16,
    borderWidth: 1,
    borderColor: c.borderLight,
    borderRadius: 14,
    color: c.textPrimary,
    backgroundColor: c.surface
  },
  passwordRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: c.surface,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: c.borderLight
  },
  passwordInput: {
    flex: 1,
    minWidth: 0,
    minHeight: 54,
    padding: 16,
    fontSize: 15,
    fontFamily: theme.typography.fontFamily,
    color: c.textPrimary
  },
  eye: {
    width: 48,
    minHeight: 48,
    alignItems: 'center',
    justifyContent: 'center'
  },
  inputError: { borderColor: c.error },
  error: {
    fontSize: 13,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 20,
    color: c.error,
    marginTop: 6
  },
  actions: {
    gap: 12,
    marginTop: 26
  },
  help: {
    fontSize: 12,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 20,
    color: c.textMuted,
    marginTop: 20
  },
  footer: {
    fontSize: 12,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 20,
    color: c.textMuted,
    textAlign: 'center',
    marginTop: 28
  }
});
