using ChoreBuddy.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Plugin.LocalNotification;

namespace ChoreBuddy.ViewModels;

public partial class SettingsViewModel : ObservableObject
{
    private readonly SettingsService settingsService;
    private readonly MigrationService migrationService;
    private readonly NotificationService notificationService;
    private bool isInitializing;

    [ObservableProperty]
    public partial bool IsHapticFeedbackEnabled { get; set; }

    [ObservableProperty]
    public partial bool IsGlobalNotificationsEnabled { get; set; }

    [ObservableProperty]
    public partial bool IsBusy { get; set; }

    public SettingsViewModel(
        SettingsService settingsService,
        MigrationService migrationService,
        NotificationService notificationService)
    {
        this.settingsService = settingsService;
        this.migrationService = migrationService;
        this.notificationService = notificationService;
        LoadSettings();
    }

    public void LoadSettings()
    {
        isInitializing = true;
        try
        {
            IsGlobalNotificationsEnabled = settingsService.IsGlobalNotificationsEnabled;
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

        if (success)
        {
            await Shell.Current.DisplayAlert("Intel Secured", "Mission data has been successfully encrypted and moved to the secure vault.", "Excellent");
        }
        else
        {
            await Shell.Current.DisplayAlert("Backup Aborted", "The system was unable to encrypt mission data. Intel remains local.", "Acknowledged");
        }
    }

    [RelayCommand]
    private async Task ImportDatabase()
    {
        if (IsBusy)
        {
            return;
        }

        bool confirm = await Shell.Current.DisplayAlert(
            "Restore Archives",
            "Warning: Importing external intel will overwrite your current mission history. Proceed with data sync?",
            "Sync Data",
            "Abort");

        if (!confirm)
        {
            return;
        }

        IsBusy = true;
        var success = await migrationService.ImportViaPicker();
        IsBusy = false;

        if (success)
        {
            await Shell.Current.DisplayAlert(
                "System Restored",
                "The archive has been successfully restored. Initiate a system reboot (restart the app) to finalize the mission logs.",
                "Acknowledged");
        }
        else
        {
            await Shell.Current.DisplayAlert("Sync Failed", "The archive file is corrupted or incompatible. Mission logs are unchanged.", "Roger That");
        }
    }

    partial void OnIsHapticFeedbackEnabledChanged(bool value)
    {
        if (!isInitializing && settingsService.IsHapticFeedbackEnabled != value)
        {
            settingsService.IsHapticFeedbackEnabled = value;
        }
    }

    async partial void OnIsGlobalNotificationsEnabledChanged(bool value)
    {
        if (!isInitializing && settingsService.IsGlobalNotificationsEnabled != value)
        {
            settingsService.IsGlobalNotificationsEnabled = value;

            if (value)
            {
                await notificationService.RequestPermissions();
            }
            else
            {
                notificationService.CancelAllNotifications();
            }
        }
    }
}
