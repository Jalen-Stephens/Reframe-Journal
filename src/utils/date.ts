export const nowIso = (): string => new Date().toISOString();

export const formatDateShort = (iso: string): string => {
  const date = new Date(iso);
  return date.toLocaleDateString();
};
