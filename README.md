🔥 Aidsense: The Big Idea
Aidsense is a mobile app (built with Flutter) that uses AI to help low-income people in NJ‑09 (like Paterson) find local help — food, housing, clinics, etc.

People in crisis type stuff like:

“I’m hungry and have no money”
“My landlord kicked me out”
“I need a free doctor for my kid”

And your app understands what they mean → then shows them nearby resources that can help.

🧠 What Makes Aidsense Special
✅ AI-powered: It understands messy input using ChatGPT (online)

✅ Real help: It finds real, local services from a database

✅ Offline mode: Still works (simpler version) when there’s no Wi-Fi

✅ Built in Flutter: Runs on both iPhone and Android

📱 HOW THE APP WORKS (Step-by-Step)
🔹 1. User Opens App
They tap "Get Help"

🔹 2. They Type a Message
“I need food for my baby”
“I lost my job and can’t pay rent”

🔹 3. AI Understands the Message
If they’re online:
The app sends that message to your Flask backend

Flask sends it to ChatGPT (OpenAI API)

GPT replies with something like: "food" or "rent"

App uses that label to pull matching services from your database

If they’re offline:
Flutter uses a keyword matching function to guess the category
(no ChatGPT, but still works!)

Example: “I’m hungry” → matches "food"

🔹 4. App Shows Help Nearby
From your database (stored as JSON or SQLite), it shows:

🥫 Food pantries

🏠 Emergency shelters

🏥 Free clinics

→ either in a map view (if online) or a list view (if offline)

🔹 5. Bonus Features (Optional)
❤️ Save/bookmark services

📍 Use location to sort services by distance

🔄 Let users update the resource list when they’re back online

💻 TECH STACK (Full Setup)
🔷 FRONTEND → Flutter (Dart)
Screen    What it does
Home    Welcome + Get Help button
Input    User types message
Results    Shows list/map of help (food, shelter)
Offline Mode    Handles local results without internet
