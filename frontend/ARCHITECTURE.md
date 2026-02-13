# Flutter Project Architecture

This document provides a simple explanation of the folder and file structure for the Rewards & Recognition System frontend.

## Root Directory (`lib/`)

- **`main.dart`**: The starting point of the application. It initializes dependencies and runs the app.
- **`app.dart`**: The root widget that sets up the global theme, routing, and overall application state.

---

## Core Folder (`lib/core/`)
Contains shared logic and components used across all features.

- **`constants/`**: Holds global constants like API endpoints (`api_constants.dart`) and string keys.
- **`errors/`**: Defines custom error and failure classes (`failures.dart`) for consistent error handling.
- **`network/`**: Logic for network monitoring and HTTP interceptors.
- **`theme/`**: Manages the application's look and feel, supporting Light and Dark modes (`app_theme.dart`).
- **`usecases/`**: Provides a base template (`usecase.dart`) that all feature-specific logic must follow.
- **`utils/`**: Small, reusable helper functions (e.g., date formatters, validators).
- **`widgets/`**: Common UI components like custom buttons, input fields, and loaders.

---

## Features Folder (`lib/features/`)
The application is divided into 13 modules that strictly mirror the backend services.

### Feature List:
1.  **`auth`**: Login, registration, and logout logic.
2.  **`profile`**: User profile management and account settings.
3.  **`budgets`**: Allocation and tracking of reward budgets.
4.  **`points`**: Calculation, history, and ledger of points.
5.  **`recognitions`**: Peer-to-peer and system-generated appreciations.
6.  **`nominations`**: Workflows for nominating and approving awards.
7.  **`departments`**: Organizational structure management.
8.  **`celebrations`**: Handling birthdays, anniversaries, and holidays.
9.  **`catalog`**: The "Store" where users can view and redeem rewards.
10. **`inbox`**: System notifications and personal alerts.
11. **`analytics`**: Data visualization and activity dashboards.
12. **`reports`**: Logic for generating and viewing activity reports.
13. **`config`**: System-wide feature toggles and settings.

---

## Clean Architecture Structure
Each feature folder follows a three-layer pattern to keep code organized and testable:

### 1. Data Layer (`data/`)
Handles the "outside world."
- **`datasources/`**: Sends requests to the backend API.
- **`models/`**: Converts backend JSON into Dart objects.
- **`repositories/`**: Links the API data to the business logic.

### 2. Domain Layer (`domain/`)
The "heart" of the feature; contains business rules.
- **`entities/`**: Pure data objects (no API or JSON logic).
- **`repositories/`**: Interfaces defining what actions are possible.
- **`usecases/`**: Individual business tasks (e.g., `LoginUser`, `SendRecognition`).

### 3. Presentation Layer (`presentation/`)
What the user sees and interacts with.
- **`bloc/`**: Manages the "mood" or state of the screen (loading, success, error).
- **`pages/`**: The full-screen widgets (e.g., `LoginPage`).
- **`widgets/`**: Smaller components unique to this specific feature.
