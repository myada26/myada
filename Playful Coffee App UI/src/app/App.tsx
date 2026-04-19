import React from "react";
import { Routes, Route } from "react-router";
import { MobileLayout } from "./components/MobileLayout";
import SplashScreen from "./screens/SplashScreen";
import OnboardingScreen from "./screens/OnboardingScreen";
import PermissionsScreen from "./screens/PermissionsScreen";
import EntryPointScreen from "./screens/EntryPointScreen";
import RegisterScreen from "./screens/RegisterScreen";
import LoginScreen from "./screens/LoginScreen";
import DashboardScreen from "./screens/DashboardScreen";

export default function App() {
  return (
    <Routes>
      <Route element={<MobileLayout />}>
        {/* The index maps to Splash Screen as the entry point */}
        <Route index element={<SplashScreen />} />
        <Route path="onboarding" element={<OnboardingScreen />} />
        <Route path="permissions" element={<PermissionsScreen />} />
        <Route path="entry-point" element={<EntryPointScreen />} />
        <Route path="register" element={<RegisterScreen />} />
        <Route path="login" element={<LoginScreen />} />
        <Route path="dashboard" element={<DashboardScreen />} />
      </Route>
    </Routes>
  );
}
