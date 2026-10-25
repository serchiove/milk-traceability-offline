function localDate(date) {
  return [date.getFullYear(), String(date.getMonth() + 1).padStart(2, '0'), String(date.getDate()).padStart(2, '0')].join('-');
}

export function periodRange(period, now = new Date()) {
  if (period === 'all') return { from: '', to: '' };
  const days = { today: 1, week: 7, month: 30 }[period];
  if (!days) throw new Error('Período no válido');
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  start.setDate(start.getDate() - days + 1);
  return { from: localDate(start), to: localDate(now) };
}

export function selectedPeriod(from, to, now = new Date()) {
  for (const period of ['all', 'today', 'week', 'month']) {
    const range = periodRange(period, now);
    if (range.from === from && range.to === to) return period;
  }
  return 'custom';
}
