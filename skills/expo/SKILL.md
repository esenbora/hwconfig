---
name: expo
description: Use when building mobile apps with React Native/Expo. Navigation, native modules, EAS builds, OTA updates. Triggers on: expo, react native, mobile app, eas, expo router, mobile, ios, android, app store, native.
version: 1.0.0
---

# Expo Deep Knowledge

> EAS, config plugins, native modules, and advanced development patterns.

---

## Quick Reference

```bash
# Create new project
npx create-expo-app my-app

# Start development
npx expo start

# Build for production
eas build --platform ios
eas build --platform android
```

---

## Project Configuration

### app.json / app.config.js

```javascript
// app.config.js (dynamic config)
export default ({ config }) => {
  return {
    ...config,
    name: process.env.APP_NAME || 'My App',
    slug: 'my-app',
    version: '1.0.0',
    orientation: 'portrait',
    icon: './assets/icon.png',
    userInterfaceStyle: 'automatic',
    
    splash: {
      image: './assets/splash.png',
      resizeMode: 'contain',
      backgroundColor: '#ffffff',
    },
    
    ios: {
      supportsTablet: true,
      bundleIdentifier: 'com.company.myapp',
      buildNumber: '1',
      infoPlist: {
        NSCameraUsageDescription: 'Used for scanning QR codes',
        NSPhotoLibraryUsageDescription: 'Used for uploading photos',
      },
      config: {
        usesNonExemptEncryption: false,
      },
      entitlements: {
        'aps-environment': 'production',
      },
    },
    
    android: {
      adaptiveIcon: {
        foregroundImage: './assets/adaptive-icon.png',
        backgroundColor: '#ffffff',
      },
      package: 'com.company.myapp',
      versionCode: 1,
      permissions: [
        'CAMERA',
        'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE',
      ],
      googleServicesFile: './google-services.json',
    },
    
    web: {
      favicon: './assets/favicon.png',
      bundler: 'metro',
    },
    
    plugins: [
      'expo-router',
      [
        'expo-camera',
        {
          cameraPermission: 'Allow $(PRODUCT_NAME) to access camera.',
        },
      ],
      [
        'expo-image-picker',
        {
          photosPermission: 'Allow $(PRODUCT_NAME) to access photos.',
        },
      ],
    ],
    
    extra: {
      eas: {
        projectId: 'your-project-id',
      },
      apiUrl: process.env.API_URL,
    },
    
    owner: 'your-expo-username',
  };
};
```

---

## EAS Build

### eas.json Configuration

```json
{
  "cli": {
    "version": ">= 5.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "resourceClass": "m1-medium"
      },
      "android": {
        "buildType": "apk"
      },
      "env": {
        "APP_ENV": "development",
        "API_URL": "https://dev-api.example.com"
      }
    },
    "preview": {
      "distribution": "internal",
      "ios": {
        "resourceClass": "m1-medium",
        "simulator": false
      },
      "android": {
        "buildType": "apk"
      },
      "env": {
        "APP_ENV": "staging",
        "API_URL": "https://staging-api.example.com"
      },
      "channel": "preview"
    },
    "production": {
      "ios": {
        "resourceClass": "m1-large"
      },
      "android": {
        "buildType": "app-bundle"
      },
      "env": {
        "APP_ENV": "production",
        "API_URL": "https://api.example.com"
      },
      "channel": "production",
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {
      "ios": {
        "appleId": "your@email.com",
        "ascAppId": "123456789",
        "appleTeamId": "XXXXXXXXXX"
      },
      "android": {
        "serviceAccountKeyPath": "./google-play-key.json",
        "track": "internal"
      }
    }
  }
}
```

### Build Commands

```bash
# Development build (with dev client)
eas build --profile development --platform ios
eas build --profile development --platform android

# Preview build (internal testing)
eas build --profile preview --platform all

# Production build
eas build --profile production --platform all

# Local build (no EAS servers)
eas build --local --platform ios

# Check build status
eas build:list

# Download build
eas build:view
```

---

## EAS Update (OTA Updates)

### Setup

```bash
# Initialize EAS Update
eas update:configure

# Publish update
eas update --branch production --message "Bug fixes"

# Publish to preview
eas update --branch preview --message "New feature"
```

### Update Configuration

```javascript
// app.config.js
export default {
  // ...
  updates: {
    url: 'https://u.expo.dev/your-project-id',
    enabled: true,
    checkAutomatically: 'ON_LOAD',
    fallbackToCacheTimeout: 30000,
  },
  runtimeVersion: {
    policy: 'sdkVersion', // or 'nativeVersion' or 'fingerprint'
  },
};
```

### Programmatic Updates

```typescript
import * as Updates from 'expo-updates';
import { useEffect, useState } from 'react';

function useOTAUpdates() {
  const [isChecking, setIsChecking] = useState(false);
  const [isDownloading, setIsDownloading] = useState(false);
  
  const checkForUpdates = async () => {
    if (!Updates.isEnabled) return;
    
    setIsChecking(true);
    
    try {
      const update = await Updates.checkForUpdateAsync();
      
      if (update.isAvailable) {
        setIsDownloading(true);
        await Updates.fetchUpdateAsync();
        
        // Prompt user to restart
        Alert.alert(
          'Update Available',
          'A new version is ready. Restart now?',
          [
            { text: 'Later', style: 'cancel' },
            { text: 'Restart', onPress: () => Updates.reloadAsync() },
          ]
        );
      }
    } catch (error) {
      console.error('Update check failed:', error);
    } finally {
      setIsChecking(false);
      setIsDownloading(false);
    }
  };
  
  useEffect(() => {
    // Check on app start
    checkForUpdates();
    
    // Check periodically
    const interval = setInterval(checkForUpdates, 1000 * 60 * 30); // 30 min
    
    return () => clearInterval(interval);
  }, []);
  
  return { isChecking, isDownloading, checkForUpdates };
}
```

---

## Config Plugins

### Using Plugins

```javascript
// app.config.js
export default {
  plugins: [
    // Simple plugin
    'expo-camera',
    
    // Plugin with options
    [
      'expo-notifications',
      {
        icon: './assets/notification-icon.png',
        color: '#ffffff',
        sounds: ['./assets/notification-sound.wav'],
      },
    ],
    
    // Custom local plugin
    './plugins/with-custom-config.js',
  ],
};
```

### Creating Custom Plugin

```javascript
// plugins/with-android-manifest.js
const { withAndroidManifest } = require('@expo/config-plugins');

module.exports = function withCustomAndroidManifest(config) {
  return withAndroidManifest(config, async (config) => {
    const manifest = config.modResults.manifest;
    
    // Add permission
    if (!manifest['uses-permission']) {
      manifest['uses-permission'] = [];
    }
    manifest['uses-permission'].push({
      $: {
        'android:name': 'android.permission.VIBRATE',
      },
    });
    
    // Add meta-data
    const application = manifest.application[0];
    if (!application['meta-data']) {
      application['meta-data'] = [];
    }
    application['meta-data'].push({
      $: {
        'android:name': 'com.google.android.geo.API_KEY',
        'android:value': 'YOUR_API_KEY',
      },
    });
    
    return config;
  });
};
```

### iOS Config Plugin

```javascript
// plugins/with-ios-config.js
const { withInfoPlist, withXcodeProject } = require('@expo/config-plugins');

const withIOSConfig = (config) => {
  // Modify Info.plist
  config = withInfoPlist(config, (config) => {
    config.modResults.LSApplicationQueriesSchemes = [
      ...(config.modResults.LSApplicationQueriesSchemes || []),
      'whatsapp',
      'telegram',
    ];
    
    config.modResults.ITSAppUsesNonExemptEncryption = false;
    
    return config;
  });
  
  // Modify Xcode project
  config = withXcodeProject(config, (config) => {
    const xcodeProject = config.modResults;
    
    // Add build settings
    xcodeProject.addBuildProperty('ENABLE_BITCODE', 'NO');
    
    return config;
  });
  
  return config;
};

module.exports = withIOSConfig;
```

---

## Development Client

### Setup

```bash
# Install dev client
npx expo install expo-dev-client

# Build development client
eas build --profile development --platform ios
eas build --profile development --platform android

# Start dev server
npx expo start --dev-client
```

### Custom Native Modules

```javascript
// With development client, you can add any native module
npx expo install react-native-vision-camera

// Then rebuild dev client
eas build --profile development --platform all
```

---

## Expo Router

### File-Based Routing

```
app/
├── _layout.tsx        # Root layout
├── index.tsx          # / route
├── about.tsx          # /about route
├── (auth)/            # Auth group (not in URL)
│   ├── _layout.tsx    # Auth layout
│   ├── login.tsx      # /login
│   └── register.tsx   # /register
├── (tabs)/            # Tab group
│   ├── _layout.tsx    # Tab layout
│   ├── home.tsx       # /home
│   └── profile.tsx    # /profile
├── users/
│   ├── index.tsx      # /users
│   └── [id].tsx       # /users/123
└── [...missing].tsx   # Catch-all 404
```

### Layouts

```typescript
// app/_layout.tsx
import { Stack } from 'expo-router';

export default function RootLayout() {
  return (
    <Stack>
      <Stack.Screen name="index" options={{ headerShown: false }} />
      <Stack.Screen name="(auth)" options={{ headerShown: false }} />
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
    </Stack>
  );
}

// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function TabLayout() {
  return (
    <Tabs>
      <Tabs.Screen
        name="home"
        options={{
          title: 'Home',
          tabBarIcon: ({ color }) => (
            <Ionicons name="home" size={24} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profile',
          tabBarIcon: ({ color }) => (
            <Ionicons name="person" size={24} color={color} />
          ),
        }}
      />
    </Tabs>
  );
}
```

### Navigation

```typescript
import { Link, router, useLocalSearchParams } from 'expo-router';

// Declarative navigation
<Link href="/about">About</Link>
<Link href={{ pathname: '/users/[id]', params: { id: '123' } }}>
  User 123
</Link>

// Programmatic navigation
router.push('/about');
router.replace('/login');
router.back();
router.navigate('/home');

// With params
router.push({
  pathname: '/users/[id]',
  params: { id: '123' },
});

// Read params
function UserPage() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <Text>User: {id}</Text>;
}
```

---

## Environment Variables

```bash
# .env
EXPO_PUBLIC_API_URL=https://api.example.com
EXPO_PUBLIC_STRIPE_KEY=pk_test_xxx

# .env.production
EXPO_PUBLIC_API_URL=https://api.production.com
```

```typescript
// Access in code
const apiUrl = process.env.EXPO_PUBLIC_API_URL;

// In EAS build, use eas.json env
// env: { "API_URL": "..." }
```

---

## Debugging

```bash
# Open debugger
# Shake device or Cmd+D (iOS) / Cmd+M (Android)

# React DevTools
npx react-devtools

# Network inspection (Flipper or React Native Debugger)

# Expo DevTools
# Press 'j' in terminal to open debugger
```
