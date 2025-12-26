export const generateId = (): string => {
  return `id_${Date.now()}_${Math.random().toString(16).slice(2)}`;
};
