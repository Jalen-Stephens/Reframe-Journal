import React from "react";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { HomeScreen } from "../screens/HomeScreen";
import { EntryDetailScreen } from "../screens/EntryDetailScreen";
import { WizardStep1Screen } from "../screens/WizardStep1Screen";
import { WizardStep2Screen } from "../screens/WizardStep2Screen";
import { WizardStep3Screen } from "../screens/WizardStep3Screen";
import { WizardStep4Screen } from "../screens/WizardStep4Screen";
import { WizardStep5Screen } from "../screens/WizardStep5Screen";
import { WizardStep6Screen } from "../screens/WizardStep6Screen";
import { WizardStep7Screen } from "../screens/WizardStep7Screen";

export type RootStackParamList = {
  Home: undefined;
  EntryDetail: { id: string };
  WizardStep1: undefined;
  WizardStep2: undefined;
  WizardStep3: undefined;
  WizardStep4: undefined;
  WizardStep5: undefined;
  WizardStep6: undefined;
  WizardStep7: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export const AppNavigator = () => {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Home" component={HomeScreen} />
      <Stack.Screen name="EntryDetail" component={EntryDetailScreen} />
      <Stack.Screen
        name="WizardStep1"
        component={WizardStep1Screen}
        options={{ title: "Step 1" }}
      />
      <Stack.Screen
        name="WizardStep2"
        component={WizardStep2Screen}
        options={{ title: "Step 2" }}
      />
      <Stack.Screen
        name="WizardStep3"
        component={WizardStep3Screen}
        options={{ title: "Step 3" }}
      />
      <Stack.Screen
        name="WizardStep4"
        component={WizardStep4Screen}
        options={{ title: "Step 4" }}
      />
      <Stack.Screen
        name="WizardStep5"
        component={WizardStep5Screen}
        options={{ title: "Step 5" }}
      />
      <Stack.Screen
        name="WizardStep6"
        component={WizardStep6Screen}
        options={{ title: "Step 6" }}
      />
      <Stack.Screen
        name="WizardStep7"
        component={WizardStep7Screen}
        options={{ title: "Step 7" }}
      />
    </Stack.Navigator>
  );
};
