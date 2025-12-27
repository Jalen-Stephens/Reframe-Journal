import React from "react";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { HomeScreen } from "../screens/HomeScreen";
import { EntryDetailScreen } from "../screens/EntryDetailScreen";
import { DateTimeScreen } from "../screens/DateTimeScreen";
import { SituationScreen } from "../screens/SituationScreen";
import { AutomaticThoughtsScreen } from "../screens/AutomaticThoughtsScreen";
import { EmotionsScreen } from "../screens/EmotionsScreen";
import { AdaptiveResponseScreen } from "../screens/AdaptiveResponseScreen";
import { OutcomeScreen } from "../screens/OutcomeScreen";
import { SettingsScreen } from "../screens/SettingsScreen";

export type RootStackParamList = {
  Home: undefined;
  EntryDetail: { id: string };
  WizardStep1: undefined;
  WizardStep2: undefined;
  WizardStep3: undefined;
  WizardStep4: undefined;
  WizardStep6: undefined;
  WizardStep7: undefined;
  Settings: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export const AppNavigator = () => {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Home" component={HomeScreen} />
      <Stack.Screen name="EntryDetail" component={EntryDetailScreen} />
      <Stack.Screen
        name="WizardStep1"
        component={DateTimeScreen}
        options={{ title: "Date & Time" }}
      />
      <Stack.Screen
        name="WizardStep2"
        component={SituationScreen}
        options={{ title: "Situation" }}
      />
      <Stack.Screen
        name="WizardStep3"
        component={AutomaticThoughtsScreen}
        options={{ title: "Automatic Thoughts" }}
      />
      <Stack.Screen
        name="WizardStep4"
        component={EmotionsScreen}
        options={{ title: "Emotions" }}
      />
      <Stack.Screen
        name="WizardStep6"
        component={AdaptiveResponseScreen}
        options={{ title: "Adaptive Response" }}
      />
      <Stack.Screen
        name="WizardStep7"
        component={OutcomeScreen}
        options={{ title: "Outcome" }}
      />
      <Stack.Screen
        name="Settings"
        component={SettingsScreen}
        options={{ title: "Settings" }}
      />
    </Stack.Navigator>
  );
};
