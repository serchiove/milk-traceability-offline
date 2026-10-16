import { StyleSheet } from 'react-native';
import { theme } from '../../theme/theme';
const c = theme.colors;
export const styles = StyleSheet.create({

  field: {
    marginBottom: 24,
  },

  label: {

    fontSize: 14,
    fontFamily: theme.typography.fontFamily,

    fontWeight: '600',

    color: theme.colors.textPrimary,

    marginBottom: 6,

  },

  required: {

    color: theme.colors.warning,

    fontWeight: '700',

  },

  input: {

    minHeight: 54,

    borderWidth: 1,

    borderColor: theme.colors.borderLight,

    borderRadius: 14,

    paddingHorizontal: 14,

    paddingVertical: 12,

    fontSize: 16,
    fontFamily: theme.typography.fontFamily,

    color: theme.colors.textPrimary,

    backgroundColor: theme.colors.surface,

  },

  inputError: {

    borderColor: theme.colors.error,

    backgroundColor: theme.colors.errorSurface,

  },

  errorContainer: {

    flexDirection: 'row',

    alignItems: 'center',

    marginTop: 5,

  },

  errorIcon: {

    color: theme.colors.error,

    fontSize: 13,
    fontFamily: theme.typography.fontFamily,

    marginRight: 4,

    fontWeight: '700',

  },

  error: {

    fontSize: 13,
    fontFamily: theme.typography.fontFamily,

    color: theme.colors.error,

    fontWeight: '500',

    flex: 1,

  },

  linkButton: {

    minHeight: 44,

    justifyContent: 'center',

    paddingVertical: 8,

    alignSelf: 'flex-start',

    marginTop: 2,

  },

  linkText: {

    fontSize: 13,
    fontFamily: theme.typography.fontFamily,

    fontWeight: '700',

    color: theme.colors.primary,

  },

  root: {

    flex: 1,

    paddingHorizontal: 20,

    backgroundColor: theme.colors.background,

  },

  modalHeader: {

    flexDirection: 'row',

    alignItems: 'center',

    justifyContent: 'space-between',

    paddingTop: theme.spacing.md,

    paddingBottom: theme.spacing.sm,

  },

  modalTitleContainer: {
    flex: 1,
  },

  eyebrow: {

    fontSize: 13,
    fontFamily: theme.typography.fontFamily,

    letterSpacing: 1.2,

    fontWeight: '700',

    color: theme.colors.primary,

    textTransform: 'uppercase',

  },

  title: {

    fontSize: 22,
    fontFamily: theme.typography.headingFamily,

    fontWeight: '700',

    color: theme.colors.textPrimary,

    marginTop: 2,

  },

  closeButton: {

    minHeight: 54,

    paddingVertical: 8,

    paddingHorizontal: 14,

  },

  modalNotice: {
    marginVertical: theme.spacing.sm,
  },

  searchContainer: {
    marginVertical: theme.spacing.sm,
  },

  searchInput: {

    minHeight: 54,

    borderWidth: 1,

    borderColor: theme.colors.borderLight,

    borderRadius: 14,

    paddingHorizontal: 14,

    paddingVertical: 12,

    fontSize: 15,
    fontFamily: theme.typography.fontFamily,

    color: theme.colors.textPrimary,

    backgroundColor: theme.colors.surface,

  },

  options: {

    paddingVertical: theme.spacing.sm,

    paddingBottom: 40,

  },

  option: {

    padding: theme.spacing.md,

    backgroundColor: theme.colors.surface,

    borderRadius: 14,

    borderWidth: 1,

    borderColor: theme.colors.borderLight,

    marginBottom: theme.spacing.sm,

    flexDirection: 'row',

    alignItems: 'center',

    justifyContent: 'space-between',

  },

  optionPressed: {
    backgroundColor: theme.colors.surfaceSubtle,
  },

  optionContent: {

    flexDirection: 'row',

    alignItems: 'center',

    flex: 1,

    marginRight: 10,

  },

  optionBullet: {

    fontSize: 16,
    fontFamily: theme.typography.fontFamily,

    color: theme.colors.primary,

    marginRight: 8,

  },

  optionText: {

    fontSize: 15,
    fontFamily: theme.typography.fontFamily,

    fontWeight: '600',

    color: theme.colors.textPrimary,

    flexShrink: 1,

  },

  selectAction: {

    fontSize: 13,
    fontFamily: theme.typography.fontFamily,

    fontWeight: '700',

    color: theme.colors.primary,

  },

  emptyContainer: {

    padding: theme.spacing.xl,

    backgroundColor: theme.colors.surface,

    borderRadius: theme.radii.lg,

    borderWidth: 1,

    borderColor: theme.colors.borderLight,

    alignItems: 'center',

    marginVertical: theme.spacing.md,

  },

  emptyIcon: {

    fontSize: 24,
    fontFamily: theme.typography.headingFamily,

    marginBottom: 8,

  },

  emptyText: {

    fontSize: 13.5,
    fontFamily: theme.typography.fontFamily,

    color: theme.colors.textSecondary,

    textAlign: 'center',

    lineHeight: 20,

  },

});
