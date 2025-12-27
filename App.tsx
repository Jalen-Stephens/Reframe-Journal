import React, { useEffect, useState } from "react";
import { NavigationContainer } from "@react-navigation/native";
import { AppNavigator } from "./src/navigation/AppNavigator";
import { initDb } from "./src/storage/db";
import { WizardProvider } from "./src/context/WizardContext";
import { ActivityIndicator, View } from "react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";

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
      <WizardProvider>
        <NavigationContainer>
          <AppNavigator />
        </NavigationContainer>
      </WizardProvider>
    </SafeAreaProvider>
  );
}
