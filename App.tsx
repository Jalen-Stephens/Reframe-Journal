import React, { useEffect, useMemo, useState } from "react";
import { NavigationContainer } from "@react-navigation/native";
import { AppNavigator } from "./src/navigation/AppNavigator";
import { initDb } from "./src/storage/db";
import { WizardProvider } from "./src/context/WizardContext";
import { ActivityIndicator, View } from "react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { ThemeProvider, useTheme } from "./src/context/ThemeProvider";
import { getNavigationTheme } from "./src/theme/theme";

const AppRoot = () => {
  const { theme, resolvedTheme } = useTheme();
  const navigationTheme = useMemo(
    () => getNavigationTheme(resolvedTheme, theme),
    [resolvedTheme, theme]
  );

  return (
    <NavigationContainer theme={navigationTheme}>
      <AppNavigator />
    </NavigationContainer>
  );
};

export default function App() {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    initDb()
      .then(() => setReady(true))
      .catch((error) => {
        console.error("DB init failed", error);
        setReady(true);
      });
  }, []);

  if (!ready) {
    return (
      <View
        style={{
          flex: 1,
          alignItems: "center",
          justifyContent: "center"
        }}
      >
        <ActivityIndicator />
      </View>
    );
  }

  return (
    <SafeAreaProvider>
      <ThemeProvider>
        <WizardProvider>
          <AppRoot />
        </WizardProvider>
      </ThemeProvider>
    </SafeAreaProvider>
  );
}
