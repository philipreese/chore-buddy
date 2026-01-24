# Chore Buddy 🦸‍

Chore Buddy is a modern, cross-platform mobile application built with .NET MAUI designed to gamify and simplify household management. It helps users track recurring tasks with a "superhero" aesthetic, providing visual clarity on what needs to be done and when it was done before.

## 🚀 Features

- **Chore Tracking**: Create chores!
- **History & Notes**: Track every completion with timestamps and optional notes to remember specific details.
- **High-Precision Urgency**: A real-time refresh engine (1-second resolution) that instantly transitions mission status from "Due Soon" (Orange) to "Overdue" (Red).
- **Mission Intelligence**:
  - **Custom Frequencies**: Set recurring intervals (Daily, Weekly, Monthly, or custom days).
  - **Field Notes**: Log specific details for every completion.
  - **Tagging Gear**: Categorize missions with high-contrast, color-coded tags.
- **Theme System**: Customze the app to your own tastes with 10 built-in themes to choose from.
- **Advanced Dashboard**:
  - **Smart Sorting**: Sort by Urgency, Alphabetical, or Mission Status.
  - **Tag Filtering**: Toggle specific tag chips to focus on certain "Sectors" of chores.
  - **Search**: Chores racking up and you can't find what you're looking for? Tap the search icon to narrow down the list.
  - **Swipe Actions**: Quick-complete missions or archive retired ones.
- **Data Integrity**:
  - **Undo Support**: Accidentally marked a chore done? Use the 5-second "Undo" snackbar to revert.
  - **Archive & Restore**: Move retired missions to the "Hall of Rest" or purge them entirely.
  - **Intel Migration**: Securely export and import your database via the native File Picker.

## 🛠 Tech Stack

- **Framework**: .NET 9 (MAUI)
- **Database**: SQLite (using `sqlite-net-pcl`)
- **Architecture**: MVVM (Model-View-ViewModel) utilizing the **CommunityToolkit.Mvvm** toolkit.
- **Toolkit**: CommunityToolkit.Maui & MVVM Toolkit
- **UI Components**:
  - `CommunityToolkit.Maui` (Popups, Behaviors, Converters).
  - `FlexLayout` for responsive tag and theme selection.
  - Custom SVG-based "Hero" icons.
- **Notifications**: Utilizes `Plugin.LocalNotification` in order to provide notifications for chores that are due.

## 💻 Developer Setup

### Prerequisites

- **Visual Studio 2022** (17.12+) or **VS Code** with the .NET MAUI extension.
- **.NET 9 SDK** installed.
- Workloads for **Android** and/or **iOS** development.
- **Vibration/Notification Permissions**: Required for haptic feedback and mission alerts.

### Getting Started
1. **Clone the Repository:**

    `git clone [https://github.com/philipreese/chore-buddy.git](https://github.com/philipreese/chore-buddy.git)`


2. **Restore Dependencies:** Visual Studio will handle this automatically, or run:

    `dotnet restore`


3. **Database Initialization:** The app uses an automatic migration strategy. On the first run, `ChoreDatabaseService` will create `ChoreTracker.db3` in the local app data directory.
4. **Theme Registry**: To add new themes, generate a XAML `ResourceDictionary` from Material Theme JSON and register the type in `ThemeService.cs`.

## 📋 Mission Instructions

### Adding a Chore

1. Tap the + button on the main dashboard.
2. The "Add New Chore" panel will expand automatically.
3. Enter the name and assign tags.
4. Tap Save.

### Completing Tasks

- **Complete**: Click the checkmark button on a chore in the list to mark it as done instantly, with an optional note.
- **Edit Notes**: Tap the chore to open details, and tap a specific `CompletionRecord` to edit its note.
- **Edit Chore**: Tap the chore to open details and use the edit feature to edit the chore name and its associated tags.
- **Assign due dates**: Tap the chore to open details, and use the edit feature to add a one-time or recurring due date, with the option to allow push notifications to nudge you to do the chore.
- **Sorting and filtering**: Filter by the tags you've created; sort by urgency, last completed, or name.

### Managing Tags

- Navigate to the Manage Tags page from the main menu.
- Create new tags with names and select from the 12 high-contrast accessible colors.

### Data Backup
- Manage your database backups via the Settings page.
- Use Export DB to save an encrypted backup of your mission logs to your device's storage.
- Use Import DB to restore your archive. Note: This requires a full app restart to clear SQLite file locks and reload the WAL logs.

## ⚖️ License

What's mine is yours? For this only of course, please be reasonable.

## 🤝 Contact

Developer: Philip Reese

Project Link: https://github.com/philipreese/chore-buddy