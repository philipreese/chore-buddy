using ChoreBuddy.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace ChoreBuddy.ViewModels;

public partial class SettingsViewModel : ObservableObject
{
    private readonly SettingsService settingsService;
    private readonly MigrationService migrationService;
    private bool isInitializing;

    [ObservableProperty]
    public partial bool IsHapticFeedbackEnabled { get; set; }

    [ObservableProperty]
    public partial bool IsBusy { get; set; }

    public SettingsViewModel(SettingsService settingsService, MigrationService migrationService)
    {
        this.settingsService = settingsService;
        this.migrationService = migrationService;
        LoadSettings();
    }

    public void LoadSettings()
    {
        isInitializing = true;
        try
        {
            IsHapticFeedbackEnabled = settingsService.IsHapticFeedbackEnabled;
        }
        finally
        {
            isInitializing = false;
        }
    }

    [RelayCommand]
    private async Task ExportDatabase()
    {
        if (IsBusy)
        {
            return; 
        }

        IsBusy = true;
        var success = await migrationService.ExportDatabase();
        IsBusy = false;

        await Shell.Current.DisplayAlert(success ? "Success" : "Error",
            success ? "Database copied!" : "Could not find or copy database.", "OK");
    }

    [RelayCommand]
    private async Task ImportDatabase()
    {
        if (IsBusy)
        {
            return;
        }

        bool confirm = await Shell.Current.DisplayAlert(
            "Import Database",
            "This will overwrite your current data with the backup. Continue?",
            "Import",
            "Cancel");

        if (!confirm)
        {
            return;
        }

        IsBusy = true;
        var success = await migrationService.ImportViaPicker();
        IsBusy = false;

        if (success)
        {
            await Shell.Current.DisplayAlert("Success", "Data imported! Please restart the app to see changes.", "OK");
        }
        else
        {
            await Shell.Current.DisplayAlert("Error", "No backup found or import cancelled.", "OK");
        }
    }

    partial void OnIsHapticFeedbackEnabledChanged(bool value)
    {
        if (!isInitializing && settingsService.IsHapticFeedbackEnabled != value)
        {
            settingsService.IsHapticFeedbackEnabled = value;
        }
    }
}
