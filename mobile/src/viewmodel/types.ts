import type { useEntornoViewModel } from './useEntornoViewModel';
import type { useLotesViewModel } from './useLotesViewModel';
export type LotesViewModel = ReturnType<typeof useLotesViewModel>;
export type EntornoViewModel = ReturnType<typeof useEntornoViewModel>;
