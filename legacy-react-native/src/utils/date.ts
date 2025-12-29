export const nowIso = (): string => new Date().toISOString();

export const formatDateShort = (iso: string): string => {
  const date = new Date(iso);
  return date.toLocaleDateString();
};

export const formatRelativeDate = (iso: string): string => {
  const date = new Date(iso);
  const now = new Date();
  const startOfToday = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate()
  );
  const startOfYesterday = new Date(startOfToday);
  startOfYesterday.setDate(startOfToday.getDate() - 1);

  if (date >= startOfToday) {
    return "Today";
  }
  if (date >= startOfYesterday) {
    return "Yesterday";
  }
  return date.toLocaleDateString();
};

export const formatRelativeDateTime = (iso: string): string => {
  const date = new Date(iso);
  const time = date.toLocaleTimeString([], {
    hour: "numeric",
    minute: "2-digit"
  });
  return `${formatRelativeDate(iso)} · ${time}`;
};
