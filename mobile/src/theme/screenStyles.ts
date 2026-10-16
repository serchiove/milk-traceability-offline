import { StyleSheet } from 'react-native';
import { theme } from './theme';
const c = theme.colors;
export const screenStyles = StyleSheet.create({

  root: {
    flex: 1,
    backgroundColor: c.background
  },
  flex: { flex: 1 },

  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    minHeight: 62,
    gap: 8
  },
  headerTitle: {
    flex: 1,
    fontSize: 19,
    fontFamily: theme.typography.headingFamily,
    fontWeight: '700',
    color: c.textPrimary
  },
  iconButton: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center'
  },
  connectionPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    minHeight: 44,
    paddingHorizontal: 10
  },
  connectionLabel: {
    fontSize: 12,
    fontFamily: theme.typography.fontFamily,
    color: c.primary
  },

  page: {
    padding: 20,
    paddingTop: 12,
    paddingBottom: 32,
    flexGrow: 1
  },
  eyebrow: {
    fontSize: 11,
    fontFamily: theme.typography.fontFamily,
    letterSpacing: 1.5,
    fontWeight: '700',
    color: c.primary,
    marginBottom: 12
  },
  heroTitle: {
    fontSize: 30,
    fontFamily: theme.typography.headingFamily,
    lineHeight: 38,
    letterSpacing: -0.3,
    fontWeight: '700',
    color: c.textPrimary
  },
  title: {
    fontSize: 27,
    fontFamily: theme.typography.headingFamily,
    lineHeight: 34,
    fontWeight: '700',
    letterSpacing: 0,
    color: c.textPrimary
  },
  intro: {
    fontSize: 15,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 23,
    color: c.textSecondary,
    marginTop: 8,
    marginBottom: 22
  },

  heroAction: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    padding: 20,
    borderRadius: 22,
    backgroundColor: c.accent,
    minHeight: 102,
    marginBottom: 24
  },
  heroPressed: { backgroundColor: c.accentDark },
  plus: {
    width: 44,
    height: 44,
    borderRadius: 14,
    backgroundColor: '#ffffff18',
    alignItems: 'center',
    justifyContent: 'center'
  },
  heroActionTitle: {
    fontSize: 19,
    fontFamily: theme.typography.headingFamily,
    fontWeight: '700',
    color: '#fff'
  },
  heroActionCaption: {
    fontSize: 12,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 18,
    color: '#fff0f1',
    marginTop: 5
  },

  stats: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 24,
    marginBottom: 28
  },
  statValue: {
    fontSize: 28,
    fontFamily: theme.typography.headingFamily,
    fontWeight: '600',
    color: c.textPrimary,
    marginBottom: 5
  },
  statUnit: { fontSize: 15 },
  statDivider: {
    height: 35,
    width: 1,
    backgroundColor: c.border
  },

  sectionHeading: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  sectionTitle: {
    fontSize: 17,
    fontFamily: theme.typography.fontFamily,
    fontWeight: '700',
    color: c.textPrimary,
    marginTop: 16,
    marginBottom: 14
  },
  textButton: {
    minHeight: 44,
    justifyContent: 'center',
    paddingHorizontal: 4
  },
  link: {
    fontSize: 14,
    fontFamily: theme.typography.fontFamily,
    color: c.primary,
    fontWeight: '600'
  },
  caption: {
    fontSize: 12,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 18,
    color: c.textMuted
  },
  list: {
    backgroundColor: c.surface,
    borderRadius: 16,
    overflow: 'hidden',
    marginBottom: 16
  },
  record: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 14,
    borderBottomWidth: 1,
    borderBottomColor: c.borderLight,
    minHeight: 92
  },
  pressed: { backgroundColor: c.surfaceSubtle },
  recordIcon: {
    width: 38,
    height: 42,
    backgroundColor: c.surfaceSubtle,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center'
  },
  recordTitle: {
    fontSize: 14,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 21,
    fontWeight: '600',
    color: c.textPrimary
  },
  local: {
    fontSize: 11,
    fontFamily: theme.typography.fontFamily,
    color: c.warning,
    marginTop: 4
  },
  recordEnd: {
    alignItems: 'flex-end',
    gap: 10,
    maxWidth: '32%'
  },
  amount: {
    fontSize: 14,
    fontFamily: theme.typography.fontFamily,
    fontWeight: '700',
    color: c.primary
  },
  quietEmpty: {
    paddingVertical: 30,
    alignItems: 'center',
    gap: 12
  },

  steps: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 30
  },
  step: { flex: 1 },
  stepLine: {
    height: 3,
    borderRadius: 2,
    backgroundColor: c.border,
    marginBottom: 10
  },
  stepLineActive: { backgroundColor: c.primary },
  stepLabel: {
    fontSize: 12,
    fontFamily: theme.typography.fontFamily,
    color: c.textMuted
  },
  stepLabelActive: {
    color: c.primary,
    fontWeight: '700'
  },
  form: { marginTop: 4 },
  actions: {
    marginTop: 30,
    gap: 8
  },

  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    gap: 12,
    marginVertical: 14
  },
  measurement: {
    width: '100%',
    backgroundColor: c.surface,
    borderRadius: 16,
    padding: 14
  },
  half: { width: '47%' },
  label: {
    fontSize: 13,
    fontFamily: theme.typography.fontFamily,
    fontWeight: '600',
    color: c.textPrimary,
    marginBottom: 10
  },
  measurementInput: {
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: c.border,
    minHeight: 56
  },
  numberInput: {
    flex: 1,
    minWidth: 0,
    fontSize: 23,
    fontFamily: theme.typography.headingFamily,
    color: c.textPrimary,
    paddingVertical: 12
  },
  unit: {
    fontSize: 12,
    fontFamily: theme.typography.fontFamily,
    color: c.textMuted
  },
  inputError: { borderBottomColor: c.error },
  error: {
    fontSize: 12,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 18,
    color: c.error,
    marginTop: 8
  },

  review: {
    backgroundColor: c.surface,
    padding: 20,
    borderRadius: 18,
    marginVertical: 14
  },
  reviewProvider: {
    fontSize: 21,
    fontFamily: theme.typography.headingFamily,
    fontWeight: '600',
    color: c.textPrimary
  },
  reviewMetric: {
    width: '100%',
    paddingVertical: 12
  },
  reviewValue: {
    fontSize: 23,
    fontFamily: theme.typography.headingFamily,
    color: c.primaryDark,
    fontWeight: '600',
    marginTop: 6
  },
  saveNote: {
    fontSize: 13,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 21,
    color: c.textSecondary,
    paddingVertical: 16
  },
  detailValue: {
    fontSize: 16,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 24,
    color: c.textPrimary,
    marginTop: 6
  },
  divider: {
    height: 1,
    backgroundColor: c.borderLight,
    marginVertical: 18
  },
  uuid: {
    fontSize: 13,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 21,
    color: c.textMuted,
    marginBottom: 24
  },
  saved: {
    flexDirection: 'row',
    gap: 10,
    alignItems: 'center',
    backgroundColor: c.primarySurface,
    padding: 14,
    borderRadius: 12,
    marginBottom: 20
  },

  search: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: c.surface,
    borderRadius: 14,
    paddingHorizontal: 14,
    minHeight: 52
  },
  searchInput: {
    flex: 1,
    fontSize: 14,
    fontFamily: theme.typography.fontFamily,
    color: c.textPrimary,
    paddingVertical: 14
  },
  listCaption: {
    fontSize: 12,
    fontFamily: theme.typography.fontFamily,
    color: c.textMuted,
    marginVertical: 16
  },
  footnote: {
    fontSize: 12,
    fontFamily: theme.typography.fontFamily,
    lineHeight: 20,
    color: c.textMuted,
    marginVertical: 16
  },
  profile: {
    alignItems: 'center',
    paddingVertical: 16
  },
  avatar: {
    width: 72,
    height: 72,
    borderRadius: 24,
    backgroundColor: c.primarySurface,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16
  },
  settingsRow: {
    flexDirection: 'row',
    gap: 14,
    alignItems: 'center',
    padding: 18,
    minHeight: 76,
    borderBottomWidth: 1,
    borderBottomColor: c.borderLight
  },
  largeIcon: {
    width: 72,
    height: 72,
    borderRadius: 24,
    backgroundColor: c.primarySurface,
    justifyContent: 'center',
    alignItems: 'center',
    marginVertical: 20
  },
  plainInput: {
    minHeight: 54,
    padding: 16,
    borderRadius: 12,
    backgroundColor: c.surface,
    fontSize: 14,
    fontFamily: theme.typography.fontFamily,
    color: c.textPrimary,
    marginBottom: 20
  },

});
