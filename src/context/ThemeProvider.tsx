import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState
} from "react";
import { ActivityIndicator, StyleSheet, View, useColorScheme } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { ResolvedTheme, ThemePreference, ThemeTokens, themes } from "../theme/theme";

type ThemeContextValue = {
  themePreference: ThemePreference;
  resolvedTheme: ResolvedTheme;
  theme: ThemeTokens;
  setThemePreference: (next: ThemePreference) => Promise<void>;
  isReady: boolean;
};

const THEME_PREFERENCE_KEY = "themePreference";

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

const isThemePreference = (value: string | null): value is ThemePreference =>
  value === "system" || value === "light" || value === "dark";

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const systemScheme = useColorScheme();
  const [themePreference, setThemePreferenceState] = useState<ThemePreference>("system");
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    let isMounted = true;

    const loadPreference = async () => {
      try {
        const saved = await AsyncStorage.getItem(THEME_PREFERENCE_KEY);
        if (isMounted && isThemePreference(saved)) {
          setThemePreferenceState(saved);
        }
      } catch (error) {
        console.warn("Failed to load theme preference", error);
      } finally {
        if (isMounted) {
          setIsReady(true);
        }
      }
    };

    loadPreference();

    return () => {
      isMounted = false;
    };
  }, []);

  const resolvedTheme: ResolvedTheme =
    themePreference === "system"
      ? systemScheme === "dark"
        ? "dark"
        : "light"
      : themePreference;

  const theme = themes[resolvedTheme];

  const setThemePreference = useCallback(async (next: ThemePreference) => {
    setThemePreferenceState(next);
    try {
      await AsyncStorage.setItem(THEME_PREFERENCE_KEY, next);
    } catch (error) {
      console.warn("Failed to persist theme preference", error);
    }
  }, []);

  const value = useMemo(
    () => ({
      themePreference,
      resolvedTheme,
      theme,
      setThemePreference,
      isReady
    }),
    [themePreference, resolvedTheme, theme, setThemePreference, isReady]
  );

  if (!isReady) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator />
      </View>
    );
  }

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
};

export const useTheme = (): ThemeContextValue => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error("useTheme must be used within ThemeProvider");
  }
  return context;
};

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center"
  }
});
