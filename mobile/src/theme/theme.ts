import { Platform } from 'react-native';
export const theme = {

  colors: {
    // Identidad visual inspirada en Leche Gloria

    primary: '#153f82', // Azul principal

    accent: '#d72532',

    accentDark: '#b71926',

    accentSurface: '#fff0f1',

    primaryDark: '#102b59',

    primaryLight: '#2d60a5',

    primarySurface: '#eaf0fa', // Superficies azules suaves

    primaryBorder: '#cddbf2',
    // Fondos y superficies

    background: '#f5f7fb', // Fondo claro operativo

    surface: '#ffffff', // Fondo tarjetas y campos

    surfaceSubtle: '#edf2fa', // Superficie secundaria / chips

    surfaceMuted: '#f8faff',
    // Textos

    textPrimary: '#182945', // Títulos y valores destacados

    textSecondary: '#485773', // Descripciones y etiquetas

    textMuted: '#5c6b81', // Ayudas y subtítulos

    textInverse: '#ffffff', // Texto sobre primary
    // Bordes y separadores

    border: '#d8e0ee',

    borderLight: '#e6ebf4',

    borderFocus: '#153f82',
    // Estados

    warning: '#945c11', // Ámbar accesible

    warningSurface: '#fdf5e8',

    warningBorder: '#f2dcba',

    error: '#aa2a20', // Rojo accesible

    errorSurface: '#fdf0ef',

    errorBorder: '#f6c9c6',

    info: '#153f82',

    infoSurface: '#edf3ff',

    infoBorder: '#c4dfee',

  },

  typography: {

    fontFamily: Platform.select({
      android: 'sans-serif',
      ios: 'System',
      default: 'Arial'
    }),

    headingFamily: Platform.select({
      android: 'sans-serif',
      ios: 'System',
      default: 'Arial'
    }),

  },

  spacing: {

    xs: 4,

    sm: 8,

    md: 12,

    lg: 16,

    xl: 20,

    xxl: 24,

  },

  radii: {

    sm: 4,

    md: 8,

    lg: 10,

    xl: 12,

    pill: 999,

  },

};
