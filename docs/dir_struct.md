# KOSEN NAV Folder Structure

```text
kosen_nav/
├── app/                               # Flutter frontend
│   ├── lib/
│   │   ├── core/
│   │   │   ├── config/
│   │   │   │   └── env.dart
│   │   │   ├── constants/
│   │   │   │   ├── api_constants.dart
│   │   │   │   └── app_constants.dart
│   │   │   ├── database/
│   │   │   ├── network/
│   │   │   │   └── connectivity_listener.dart
│   │   │   ├── router/
│   │   │   │   ├── app_navigator_key.dart
│   │   │   │   └── app_router.dart
│   │   │   └── theme/
│   │   │       ├── app_theme.dart
│   │   │       └── theme.dart
│   │   ├── data/
│   │   │   ├── local/
│   │   │   │   ├── local_database.dart
│   │   │   │   ├── sync_status.dart
│   │   │   │   └── user_repository.dart
│   │   │   └── sync/
│   │   │       └── sync_service.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   │       └── user.dart
│   │   ├── features/
│   │   │   ├── dashboard/
│   │   │   │   └── presentation/
│   │   │   │       └── dashboard_screen.dart
│   │   │   ├── grades/
│   │   │   │   ├── application/
│   │   │   │   │   └── grade_controller.dart
│   │   │   │   ├── data/
│   │   │   │   │   ├── course_repository.dart
│   │   │   │   │   └── subject_api_client.dart
│   │   │   │   ├── domain/
│   │   │   │   │   ├── grade.dart
│   │   │   │   │   ├── grade_calculator.dart
│   │   │   │   │   └── subject_model.dart
│   │   │   │   └── presentation/
│   │   │   │       ├── grades_screen.dart
│   │   │   │       └── subject_detail_screen.dart
│   │   │   ├── simulation/
│   │   │   │   └── application/
│   │   │   │       └── simulation_controller.dart
│   │   │   └── tasks/
│   │   │       ├── application/
│   │   │       │   └── task_controller.dart
│   │   │       ├── data/
│   │   │       │   ├── api_client.dart
│   │   │       │   ├── task_repository.dart
│   │   │       │   └── teams_auth_service.dart
│   │   │       ├── domain/
│   │   │       │   ├── task.dart
│   │   │       │   └── teams_assignment.dart
│   │   │       └── presentation/
│   │   │           ├── gantt_chart_screen.dart
│   │   │           ├── tasks_screen.dart
│   │   │           └── widgets/
│   │   │               ├── backlog_gantt_chart.dart
│   │   │               ├── edit_task_sheet.dart
│   │   │               └── task_ai_mentor.dart
│   │   ├── presentation/
│   │   │   └── profile/
│   │   │       ├── departments_api_client.dart
│   │   │       ├── profile_controller.dart
│   │   │       └── profile_screen.dart
│   │   ├── shared/
│   │   │   ├── loading_indicator.dart
│   │   │   ├── menu_toggle_button.dart
│   │   │   ├── promotion_status_badge.dart
│   │   │   ├── widgets.dart
│   │   │   └── providers/
│   │   │       └── navigation_providers.dart
│   │   ├── utils/
│   │   │   └── string_extensions.dart
│   │   └── main.dart
│   └── pubspec.yaml
├── backend/
│   ├── docker-compose.yml
│   └── server/                        # Dart Frog backend
│       ├── db/
│       │   └── migrations/
│       ├── lib/
│       │   └── src/
│       │       └── database.dart
│       ├── routes/
│       │   ├── api/
│       │   │   ├── sync/
│       │   │   └── v1/
│       │   │       ├── departments/
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
├── build/
└── folder.md
```
