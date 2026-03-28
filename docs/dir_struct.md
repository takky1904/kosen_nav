# KOSEN NAV Folder Structure

```text
kosen_nav/
├── app/                                  # Flutter frontend
│   ├── lib/
│   │   ├── core/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── features/
│   │   ├── presentation/
│   │   │   └── profile/
│   │   │       ├── departments_api_client.dart
│   │   │       ├── profile_controller.dart
│   │   │       ├── profile_screen.dart
│   │   │       └── schools_api_client.dart
│   │   ├── shared/
│   │   ├── utils/
│   │   └── main.dart
│   └── pubspec.yaml
├── backend/
│   ├── docker-compose.yml
│   └── server/                           # Dart Frog backend
│       ├── db/
│       │   └── migrations/
│       ├── lib/
│       │   └── src/
│       │       ├── config/
│       │       │   └── course_data/
│       │       │       └── nagano.json
│       │       ├── models/
│       │       ├── services/
│       │       │   └── course_data_service.dart
│       │       └── database.dart
│       ├── routes/
│       │   ├── api/
│       │   │   ├── sync/
│       │   │   │   └── assignments/
│       │   │   └── v1/
│       │   │       ├── departments/
│       │   │       │   └── index.dart
│       │   │       ├── schools/
│       │   │       │   └── index.dart
│       │   │       └── syllabus/
│       │   │           └── index.dart
│       │   ├── subjects/
│       │   │   ├── index.dart
│       │   │   └── [id].dart
│       │   └── tasks/
│       │       ├── index.dart
│       │       └── [id].dart
│       ├── test/
│       │   └── routes/
│       ├── pubspec.yaml
│       └── README.md
├── docs/
└── build/
```
