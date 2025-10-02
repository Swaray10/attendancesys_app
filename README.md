# Smart Attendance System - Flutter App

NFC-based attendance management system for lecturers. This mobile app enables real-time student check-ins via NFC card scanning with offline-first architecture.

## 🚀 Features

- ✅ **NFC Card Reading** - Support for MIFARE Classic, DESFire, Ultralight
- ✅ **Offline-First** - Queue check-ins locally, auto-sync when online
- ✅ **Real-time Updates** - Live check-in counter and student list
- ✅ **Session Management** - Start/stop attendance sessions
- ✅ **Mock API** - Built-in mock backend for development
- ✅ **Material Design 3** - Modern, clean UI

## 📋 Prerequisites

- Flutter SDK 3.16+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Android Studio / VS Code with Flutter extensions
- Android device with NFC (API 26+) or emulator
- Git

## 🛠️ Setup Instructions

### 1. Clone and Install Dependencies

```bash
# Navigate to your project directory
cd attendancesys_app

# Install dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Configure Android Manifest

The `AndroidManifest.xml` has already been created. Ensure it's at:
```
android/app/src/main/AndroidManifest.xml
```

### 3. Run the App

```bash
# Check connected devices
flutter devices

# Run on connected device
flutter run

# Or specify device
flutter run -d <device_id>
```

## 🧪 Testing the App

### Login Credentials (Mock API)
```
Email: lecturer@university.edu
Password: password123
```

### Testing NFC Without Real Cards

Since the app uses a mock API, you can simulate NFC reads:

**Option 1: Use Real NFC Cards**
- Use any NFC-enabled student ID card
- The mock API will recognize any NFC UID

**Option 2: Modify Mock Data**
- Edit `lib/services/api_service.dart`
- Update `_generateMockNfcId()` to return known UIDs
- Map your test cards to mock students

### Mock Students Available

The mock API includes 8 pre-registered students:
- Alice Johnson (Student ID: 20251000)
- Bob Williams (Student ID: 20251001)
- Carol Davis (Student ID: 20251002)
- David Miller (Student ID: 20251003)
- Emma Wilson (Student ID: 20251004)
- Frank Moore (Student ID: 20251005)
- Grace Taylor (Student ID: 20251006)
- Henry Anderson (Student ID: 20251007)

Each has a randomly generated NFC card ID.

## 📱 App Flow

### 1. Login
- Enter credentials
- JWT tokens stored locally
- User data cached

### 2. Home Screen
- View assigned courses
- See active sessions
- Start new session

### 3. Session Screen
- Real-time NFC scanning
- Live check-in counter
- Recent check-ins list
- End session

### 4. Offline Mode
- Check-ins queued locally (Hive)
- Auto-sync when online
- Visual sync indicators

## 🏗️ Project Structure

```
lib/
├── main.dart              # App entry point
├── core/                  
│   ├── constants.dart     # App constants & enums
│   └── theme.dart         # Material Design 3 theme
├── models/                
│   └── models.dart        # Data models (User, Course, Session, etc.)
├── services/              
│   ├── api_service.dart   # Mock API client
│   ├── nfc_service.dart   # NFC reading logic
│   ├── storage_service.dart    # Hive & SharedPreferences
│   └── connectivity_service.dart    # Network monitoring
├── blocs/                 
│   ├── auth/              # Authentication BLoC
│   ├── course/            # Course management BLoC
│   ├── session/           # Session management BLoC
│   └── nfc/               # NFC & check-in BLoC
├── screens/               
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   └── session_screen.dart
└── widgets/               
    ├── course_card.dart
    ├── check_in_list_item.dart
    └── network_status_banner.dart
```

## 🔧 Configuration

### Change API Endpoint

Edit `lib/core/constants.dart`:
```dart
static const String baseUrl = 'https://your-api.com';
```

### Adjust NFC Settings

In `lib/core/constants.dart`:
```dart
static const Duration nfcReadTimeout = Duration(seconds: 5);
static const int nfcRetryAttempts = 3;
```

### Session Defaults

```dart
static const Duration defaultSessionDuration = Duration(hours: 2);
```

## 🐛 Troubleshooting

### NFC Not Working

1. **Check NFC is enabled**
   ```bash
   # In device settings
   Settings > Connected devices > Connection preferences > NFC
   ```

2. **Verify NFC permission**
   - Permission should be in `AndroidManifest.xml`
   - May need to restart app after enabling NFC

3. **Test NFC availability**
   - App will show error if NFC unavailable
   - Check device supports NFC

### Build Errors

**Missing Hive Adapters**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Dependency Conflicts**
```bash
flutter pub upgrade
flutter clean
flutter pub get
```

### Network Issues

**Offline mode not working**
- Check `connectivity_plus` package installed
- Verify Hive initialization in `main.dart`

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `nfc_manager` | NFC card reading |
| `hive` | Offline storage |
| `dio` | HTTP client (ready for real API) |
| `connectivity_plus` | Network monitoring |
| `equatable` | Value equality |

## 🚧 Next Steps

### Connect to Real Backend

1. Replace mock API in `lib/services/api_service.dart`
2. Update `baseUrl` in constants
3. Implement JWT refresh logic
4. Add error handling for API responses

### Add Features

- [ ] Photo verification during check-in
- [ ] Manual student add/remove
- [ ] Export session reports
- [ ] Bluetooth beacon support
- [ ] Multi-language support

## 🔐 Security Notes

- Mock API is for **development only**
- Never commit real credentials
- JWT tokens stored in encrypted SharedPreferences
- NFC card IDs are NOT encrypted (needed for matching)


