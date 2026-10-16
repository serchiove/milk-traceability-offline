import {SafeAreaProvider} from 'react-native-safe-area-context';
import {Application} from './src/navigation/Application';

export default function App() {
  return (
    <SafeAreaProvider>
      <Application />
    </SafeAreaProvider>
  );
}
