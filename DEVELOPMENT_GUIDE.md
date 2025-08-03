# 🚀 Aidsense Development Guide

## Quick Start

### 1. Initial Setup
```bash
# Run the setup script (Windows)
setup.bat

# Or manually:
flutter\bin\flutter.bat packages get
flutter\bin\flutter.bat packages pub run build_runner build
```

### 2. Running the App
```bash
flutter\bin\flutter.bat run
```

## 🏗️ Current State

### ✅ What's Complete
- **Project Structure**: Clean architecture with BLoC pattern
- **Core Models**: Service, Search, Bookmark data models
- **Database Layer**: SQLite setup with services and bookmarks tables
- **AI Service**: Framework for ChatGPT integration + offline fallback
- **Location Service**: GPS and distance calculation utilities
- **Sample Data**: Real NJ-09 area services loaded from JSON
- **Dependency Injection**: Get_it configuration ready
- **Internationalization**: English/Arabic support structure

### 🚧 What Needs Building

#### UI Screens (Priority Order)
1. **Search Screen** (`lib/modules/help_search/ui/`)
   - Large text input: "Tell us what you need..."
   - Example prompts: "I'm hungry", "Need a place to stay"
   - Emergency button for quick crisis access

2. **Results Screen** 
   - Service cards with distance, category, contact
   - Map/List toggle view
   - Bookmark/call/directions actions

3. **Service Detail Screen**
   - Full service information
   - Operating hours, requirements, directions
   - Call/bookmark/share actions

4. **Home Screen Updates**
   - "Get Help" primary button
   - Quick emergency access
   - Recent searches/bookmarks

#### Core Features
1. **Search Implementation**
   - Wire up HelpSearchCubit to UI
   - Implement text input processing
   - Results display and filtering

2. **Maps Integration**
   - Google Maps setup
   - Service markers
   - Directions integration

3. **Offline Mode**
   - Network connectivity detection
   - Offline indicator UI
   - Keyword matching fallback

## 💻 Development Workflow

### Adding New Features
1. **Models**: Define data structures in `core/models/`
2. **Services**: Add business logic in `core/services/`
3. **State Management**: Create Cubit in `modules/[feature]/logic/`
4. **UI**: Build screens in `modules/[feature]/ui/`
5. **Dependency Injection**: Register in `core/di/`

### Key Development Areas

#### 1. Search Functionality
```dart
// Already created: HelpSearchCubit
// TODO: Create search UI that calls:
await helpSearchCubit.searchForHelp("I need food for my family");
```

#### 2. Location Features
```dart
// Already created: LocationService
// TODO: Wire up to UI for service sorting
final position = await locationService.getCurrentLocation();
```

#### 3. Database Operations
```dart
// Already created: DatabaseService
// TODO: Load sample data on first app launch
await dataLoaderService.loadSampleData();
```

## 🎨 UI Design Guidelines

### Accessibility First
- Large, easy-to-tap buttons (min 44px)
- High contrast colors
- Simple, clear language
- Support for screen readers

### Crisis-Focused UX
- Emergency services prominently displayed
- Minimal steps to get help
- Clear, actionable information
- Works on low-end devices

### Example Screens Layout

#### Search Screen
```
┌─────────────────────────────┐
│  🆘 Aidsense               │
├─────────────────────────────┤
│                             │
│  "Tell us what you need     │
│   help with..."             │
│  ┌─────────────────────────┐ │
│  │ I'm hungry and need... │ │
│  └─────────────────────────┘ │
│                             │
│  💡 Try saying:             │
│  • "I need food for my kid" │
│  • "Lost my job, need help" │
│  • "Looking for a clinic"   │
│                             │
│  🚨 [EMERGENCY SERVICES]    │
└─────────────────────────────┘
```

#### Results Screen
```
┌─────────────────────────────┐
│  ← Back    🗺️ Map View      │
├─────────────────────────────┤
│  Found 5 food services      │
│                             │
│  📍 Food Bank (0.3 mi)      │
│  │  📞 Call  🔖 Save        │
│  │  Mon-Fri 9AM-4PM         │
│  └─────────────────────────  │
│                             │
│  🏥 Free Clinic (0.8 mi)    │
│  │  📞 Call  🔖 Save        │
│  │  Walk-ins welcome        │
│  └─────────────────────────  │
└─────────────────────────────┘
```

## 🔧 Configuration

### Backend Setup (Future)
```bash
# Flask backend configuration
export OPENAI_API_KEY="your-key-here"
export FLASK_ENV="development"
python backend/app.py
```

### API Integration Points
1. **AI Processing**: `POST /api/process-query`
2. **Service Updates**: `GET /api/services`
3. **Analytics**: `POST /api/search-analytics`

### Environment Variables
```dart
// lib/core/config/env_config.dart
class EnvConfig {
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL', 
    defaultValue: 'http://localhost:5000'
  );
  static const String openAIKey = String.fromEnvironment('OPENAI_KEY');
}
```

## 🧪 Testing Strategy

### Unit Tests
- AI service keyword matching
- Database operations
- Location calculations
- Search result sorting

### Integration Tests
- Search flow end-to-end
- Offline mode functionality
- Database migration

### UI Tests
- Accessibility compliance
- Emergency service access
- Cross-platform consistency

## 📱 Deployment

### Android Setup
```yaml
# android/app/build.gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### iOS Setup (Future)
- Location permissions in Info.plist
- Maps API key configuration

## 🎯 Success Metrics

### User Experience
- Time from app open to finding help < 30 seconds
- 90%+ success rate for common queries
- Works offline for basic functionality

### Technical Performance
- App startup < 3 seconds
- Search results < 2 seconds (online)
- Database queries < 100ms

## 📞 Support

### Community Impact
This app serves vulnerable populations in NJ-09, providing:
- Quick access to food banks and shelters
- Free medical care locations
- Emergency mental health support
- Employment and financial assistance

Every feature should prioritize accessibility, simplicity, and reliability for users in crisis situations.
