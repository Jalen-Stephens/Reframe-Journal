import { DarkTheme, DefaultTheme, Theme } from "@react-navigation/native";

export type ThemePreference = "system" | "light" | "dark";
export type ResolvedTheme = "light" | "dark";

export type ThemeTokens = {
  background: string;
  card: string;
  textPrimary: string;
  textSecondary: string;
  placeholder: string;
  border: string;
  muted: string;
  accent: string;
  onAccent: string;
};

export const themes: Record<ResolvedTheme, ThemeTokens> = {
  light: {
    background: "#FAFAFA",
    card: "#FFFFFF",
    textPrimary: "#1F1F1F",
    textSecondary: "#5E5E5E",
    placeholder: "#8A8A8A",
    border: "#E3E3E3",
    muted: "#EFEFEF",
    accent: "#2F2F2F",
    onAccent: "#FFFFFF"
  },
  dark: {
    background: "#0E0E0E",
    card: "#1A1A1A",
    textPrimary: "#F5F5F5",
    textSecondary: "#BDBDBD",
    placeholder: "rgba(245,245,245,0.6)",
    border: "#2A2A2A",
    muted: "#2F2F2F",
    accent: "#4AC07A",
    onAccent: "#0E0E0E"
  }
};

export const getNavigationTheme = (
  resolvedTheme: ResolvedTheme,
  tokens: ThemeTokens
): Theme => {
  const baseTheme = resolvedTheme === "dark" ? DarkTheme : DefaultTheme;

  return {
    ...baseTheme,
    dark: resolvedTheme === "dark",
    colors: {
      ...baseTheme.colors,
      background: tokens.background,
      card: tokens.card,
      text: tokens.textPrimary,
      border: tokens.border,
      primary: tokens.accent,
      notification: tokens.accent
    }
  };
};
