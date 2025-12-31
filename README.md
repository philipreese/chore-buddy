# Chore Buddy

Chore Buddy is a modern, cross-platform mobile application built with .NET MAUI designed to gamify and simplify household management. It helps users track recurring tasks with a "superhero" aesthetic, providing visual clarity on what needs to be done and when it was done before.

## 🚀 Features

- Chore Tracking: Create chores!
- History & Notes: Track every completion with timestamps and optional notes to remember specific details.
- Tagging System: Organize chores using a vibrant, color-coded tagging system with high-contrast accessibility.
- Smart Sorting: Sort chores by name or completion history directly from the dashboard.
- Undo Support: Accidentally marked a chore as done? Use the built-in "Undo" snackbar to revert the last completion.
- Responsive UI: A "hero" styled About page and a sliding edit panel for a seamless user experience.

## 🛠 Tech Stack

- Framework: .NET 9 (MAUI)
- Database: SQLite (using `sqlite-net-pcl`)
- Architecture: MVVM (Model-View-ViewModel)
- Toolkit: CommunityToolkit.Maui & MVVM Toolkit
- Icons: SVG-based custom assets and FontAwesome integration

## 💻 Developer Setup

### Prerequisites

- **Visual Studio 2022** (17.12+) or **VS Code** with the .NET MAUI extension.
- **.NET 9 SDK** installed.
- Workloads for **Android** and/or **iOS** development.

### Getting Started
1. **Clone the Repository:**

    `git clone [https://github.com/philipreese/chore-buddy.git](https://github.com/philipreese/chore-buddy.git)`


2. **Restore Dependencies:** Visual Studio will handle this automatically, or run:

    `dotnet restore`


3. **Database Initialization:** The app uses an automatic migration strategy. On the first run, `ChoreDatabaseService` will create `ChoreTracker.db3` in the local app data directory.

### Project Structure
- **/Models:** POCO classes for SQLite and UI wrappers (e.g., `ChoreDisplayItem`).
- **/ViewModels:** Logic for data binding, utilizing `ObservableObject` and `RelayCommand`.
- **/Views:** XAML-based UI pages.
- **/Services:** Singleton services for database access and business logic.
- **/Resources:**
    - `AppIcon`: Contains `appicon.svg`.
    - `Styles`: Contains `Colors.xaml` (updated for .NET 9 contrast standards).

## 📋 Instructions for Users

### Adding a Chore

1. Tap the + button on the main dashboard.
2. The "Add New Chore" panel will expand automatically.
3. Enter the name and assign tags.
4. Tap Save.

### Completing Tasks

- Complete: Click the `Complete` button on a chore in the list to mark it as done instantly, with an optional note.
- Edit Notes: Tap the chore to open details, and tap a specific `CompletionRecord` to edit its note.
- Edit Chore: Tap the chore to open details and use the edit feature to edit the chore name and its associated tags.

### Managing Tags

- Navigate to the Manage Tags page from the main menu.
- Create new tags with names and select from the 12 high-contrast accessible colors.

## ⚖️ License

What's mine is yours? For this only of course, please be reasonable.

## 🤝 Contact

Developer: Philip Reese

Project Link: https://github.com/philipreese/chore-buddy