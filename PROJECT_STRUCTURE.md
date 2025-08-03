# AidSense - Project Structure

## Project Overview
AidSense is a local resource discovery app built with Flutter for New Jersey Congressional District 9. The app helps users find local services and amenities using natural language AI chat interface.

## Architecture
- **State Management**: BLoC/Cubit pattern
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Database**: Firestore for cloud data, SQLite for offline
- **Maps**: Flutter Map (OpenStreetMap) for free map services
- **AI Chat**: Hugging Face API with offline keyword fallback
- **Authentication**: Firebase Auth with guest mode support

## Folder Structure

```
lib/
├── core/                              # Shared utilities and services
│   ├── constants/
│   │   └── app_strings.dart          # App-wide string constants
│   ├── database/
│   │   └── database_service.dart     # SQLite for offline data
│   ├── di/
│   │   └── dependency_injection.dart # Get_it configuration
│   ├── models/                        # Data models
│   │   ├── place_model.dart          # Place/location model
│   │   ├── chat_message_model.dart   # Chat interface models
│   │   ├── user_model.dart           # User authentication model
│   │   ├── search_request_model.dart # Search functionality
│   │   └── bookmark_model.dart       # Saved places
│   ├── services/                      # Core services
│   │   ├── ai_service.dart           # Chat AI (Hugging Face + offline)
│   │   ├── location_service.dart     # GPS/location services
│   │   ├── data_loader_service.dart  # Sample data management
│   │   └── firebase/                 # Firebase services
│   │       ├── auth_service.dart     # Authentication
│   │       └── firestore_service.dart # Database operations
│   └── routing/
│       └── app_router.dart           # Navigation routing
│
├── modules/                           # Feature modules
│   ├── auth/                         # Authentication & user management
│   │   ├── logic/
│   │   │   ├── auth_cubit.dart
│   │   │   └── auth_state.dart
│   │   └── ui/                       # Login, signup, guest screens
│   ├── chat/                         # AI chat interface
│   │   ├── logic/
│   │   │   ├── chat_cubit.dart
│   │   │   └── chat_state.dart
│   │   └── ui/                       # Chat interface
│   ├── home/                         # Main dashboard
│   ├── search/                       # Traditional search interface
│   ├── map/                          # Map view for places
│   ├── bookmarks/                    # Saved places
│   └── onboarding/                   # App introduction
│
├── main.dart                         # App entry point
└── my_app.dart                       # App configuration
```

## 🗄️ Database Schema

### Services Table
- id (TEXT PRIMARY KEY)
- name, description, category
- contact info (phone, email, hotline)
- address (street, city, state, zipCode, lat/lng)
- operating hours
- eligibility requirements
- emergency flag
- rating

### Bookmarks Table
- id (TEXT PRIMARY KEY)
- serviceId (FOREIGN KEY)
- createdAt, notes, tags

## 🧠 AI Processing Flow

### Online Mode
1. User input → Flutter app
2. App → Flask backend → OpenAI API
3. AI extracts intent & categories
4. Search local database
5. Return sorted results

### Offline Mode
1. User input → keyword matching
2. Simple category detection
3. Search local database
4. Return results (limited functionality)

## 📍 Key Features Implementation

### 1. Natural Language Search
- **File**: `help_search_cubit.dart`
- **AI Service**: `ai_service.dart`
- Processes "I'm hungry" → food category

### 2. Location-Based Results
- **Service**: `location_service.dart`
- GPS permissions & distance calculation
- Sorts results by proximity

### 3. Offline Support
- **Database**: `database_service.dart`
- Local SQLite with sample data
- Keyword matching fallback

### 4. Service Categories
- Food banks, shelters, clinics
- Emergency services prioritized
- Healthcare, mental health, employment

## 🎨 UI Components (To Be Built)

### Main Screens
1. **Onboarding** - App introduction
2. **Home** - "Get Help" button + emergency access
3. **Search** - Text input + AI processing
4. **Results** - Service list/map view
5. **Service Detail** - Full info + actions
6. **Bookmarks** - Saved services

### Key UI Elements
- Large, accessible buttons
- Simple text input
- Clear service cards
- Emergency service highlighting
- Offline mode indicator

## 🔧 Setup & Configuration

### Dependencies Added
```yaml
# Location & Maps
geolocator: ^10.1.0
geocoding: ^3.0.0
google_maps_flutter: ^2.5.0

# Database
sqflite: ^2.3.0
path: ^1.8.3

# Permissions & Utils
permission_handler: ^11.1.0
url_launcher: ^6.2.1
http: ^1.1.0
```

### Sample Data
- **File**: `assets/data/sample_services.json`
- Real NJ-09 area services
- Food banks, shelters, clinics, etc.

## 🚀 Next Steps for Development

### 1. Complete Core UI
- Build search screen with text input
- Create service list/card components
- Implement service detail screen

### 2. Enhanced Features
- Google Maps integration
- Bookmark functionality
- Emergency service quick access

### 3. Backend Integration
- Set up Flask backend
- Integrate OpenAI API
- Real-time service updates

### 4. Testing & Deployment
- Unit tests for core logic
- UI testing
- Play Store deployment

## 🎯 Target Users
- Low-income individuals in crisis
- People seeking emergency assistance
- Community members needing local resources

The app prioritizes simplicity, accessibility, and reliability to serve users in vulnerable situations effectively.
