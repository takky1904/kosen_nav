# KOSEN NAV Folder Structure

```text
kosen_nav/
├── app/                      # Flutter Frontend
│   ├── lib/
│   │   ├── core/             # Core configurations (Theme, etc.)
│   │   ├── features/         # Feature-based modules
│   │   │   ├── dashboard/
│   │   │   ├── grades/
│   │   │   ├── simulation/
│   │   │   └── tasks/        # Task management feature
│   │   │       ├── application/
│   │   │       ├── data/
│   │   │       ├── domain/   # Task model definition
│   │   │       └── presentation/
│   │   ├── shared/           # Shared widgets and providers
│   │   ├── utils/            # Utility functions
│   │   └── main.dart         # App entry point
│   ├── pubspec.yaml
│   └── ...
├── backend/                  # Backend Root
│   ├── docker-compose.yml    # Infrastructure (PostgreSQL)
│   └── server/               # Dart Frog Server
│       ├── db/
│       │   └── migrations/   # SQL migration files
│       ├── lib/
│       │   └── src/          # Server-side logic (Database, etc.)
│       ├── routes/           # API Endpoints
│       │   └── tasks/        # /tasks routes
│       ├── pubspec.yaml
│       └── ...
└── folder.md                 # This file
```
