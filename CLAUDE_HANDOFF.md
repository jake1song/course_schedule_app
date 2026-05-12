# Claude Handoff: course_schedule_app

## Build

```powershell
flutter build apk --release
```

- APK: `build\app\outputs\flutter-apk\app-release.apk` (20.4MB)
- `flutter analyze`: No issues
- `flutter test`: 22/22 passed

## Architecture (2026-05-09 refactored)

Pure Flutter native app — WebView removed entirely.

```
lib/
├── main.dart                      # Provider setup
├── config/app_config.dart         # dart-define: API_BASE_URL, HW_ACCEL, PERF_MODE, TEACHING_WEEK_STARTS
├── auth/
│   ├── auth_models.dart           # AuthUser, AuthSession, StoredSession
│   ├── auth_api.dart              # HTTP: requestSms, login, register, refresh, authenticatedGet/Post
│   ├── auth_controller.dart       # State: boot, login, register, logout
│   ├── token_store.dart           # Abstract interface
│   └── secure_token_store.dart    # flutter_secure_storage impl
├── models/
│   └── native_course.dart         # NativeCourse, ScheduleRow, NativeCourseSchedule
├── screens/
│   ├── auth_gate.dart             # Boot gate (8s timeout + retry)
│   ├── login_page.dart            # Phone + password (validation, visibility toggle)
│   ├── register_page.dart         # SMS + password (validation, visibility toggle)
│   ├── home_page.dart             # Course list (FutureBuilder + RefreshIndicator + week selector)
│   ├── import_course_page.dart    # Native import (paste → parse → preview → submit)
│   └── ai_chat_page.dart          # Native AI chat (bubbles + history)
├── widgets/
│   ├── action_strip.dart          # Week selector + Import/AI buttons
│   ├── schedule_row_tile.dart     # Course card (RepaintBoundary per item)
│   ├── nav_tab.dart               # Bottom nav tab
│   └── empty_state.dart           # Empty course placeholder
└── util/
    └── app_logger.dart            # debugPrint wrapper
```

## User Flow

```
AuthGate → [token valid?] → HomePage
                ↓ no
           LoginPage ←→ RegisterPage
                ↓ success
           HomePage
           ├── Week selector (ChoiceChip + auto scroll top)
           ├── Course list (pull to refresh, cacheExtent 500px)
           ├── Import → ImportCoursePage (parse text → preview → POST /api/courses/batch)
           └── AI → AiChatPage (chat bubbles → POST /api/ai/chat)
```

## Key Guards

- flutter_secure_storage ops have `.timeout(3s)` with recovery
- Session null-check before every use, logout fallback
- `dispose()` never calls `setState()`
- Every `await` has `mounted` check before UI ops
- AuthApi handles all HTTP (one client, one timeout, unified error → Chinese messages)
- Cleartext HTTP restricted to debug builds only
- Phone validation: `^1\d{10}$`, password: >= 8 chars, real-time errorText
- RepaintBoundary on each schedule card per AppConfig.enableHardwareAcceleration
- dart-define: API_BASE_URL, HW_ACCEL, PERF_MODE, TEACHING_WEEK_STARTS

## Dependencies

- flutter_secure_storage: token persistence
- http: network calls
- provider: state management
