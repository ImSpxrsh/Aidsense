🆘 Aidsense
AI-powered crisis support app for low-income communities in NJ-09

Aidsense is a cross-platform mobile app built with Flutter that helps individuals in crisis find real, local services like food banks, shelters, and free clinics — using plain language input and AI understanding.

🌟 The Big Idea
People in crisis don’t have time for complicated forms. They just want to say:

“I’m hungry and have no money”

“My landlord kicked me out”

“I need a free doctor for my kid”

Aidsense understands these natural-language inputs using AI (ChatGPT API) and shows them nearby resources — instantly.

🧠 What Makes Aidsense Special
✅ AI-powered — Understands messy text input via ChatGPT (OpenAI API)
✅ Real help — Pulls real services from a local database
✅ Offline mode — Works with limited functionality even without Wi-Fi
✅ Cross-platform — Built in Flutter, runs on both Android and iOS

📱 How the App Works
🔹 1. Open the App
User taps Get Help from the home screen.

🔹 2. User Types a Message
Free-form text like:

css
Copy
Edit
“I need food for my baby”
“I lost my job and can’t pay rent”
🔹 3. AI Understands the Message
Online:

Flutter app sends message to Flask backend

Flask uses OpenAI API (ChatGPT) to interpret intent → e.g., "food" or "shelter"

App queries database for matching services

Offline:

Uses keyword matching fallback (on-device)

Example: “I’m hungry” → matches category "food"

🔹 4. Show Nearby Help
Resources are shown from your local DB (JSON or SQLite):

🥫 Food Pantries

🏠 Emergency Shelters

🏥 Free Clinics

Online: Map View with geolocation sorting

Offline: List View sorted by stored zip codes

🔹 5. Bonus Features (Optional)
❤️ Bookmark/save useful services

📍 Use location to sort services by proximity

🔄 Allow community edits when back online

