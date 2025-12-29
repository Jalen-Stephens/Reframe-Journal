export const clampPercent = (value: number): number => {
  if (Number.isNaN(value)) {
    return 0;
  }
  return Math.max(0, Math.min(100, value));
};

export const isPercentValid = (value: number): boolean => {
  return value >= 0 && value <= 100;
};

export const isRequiredTextValid = (value: string): boolean => {
  return value.trim().length > 0;
};
