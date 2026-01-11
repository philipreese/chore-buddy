using ChoreBuddy.Models;
using ChoreBuddy.Services;
using CommunityToolkit.Mvvm.ComponentModel;

namespace ChoreBuddy.ViewModels;

public partial class AboutViewModel : ObservableObject
{
    private readonly SettingsService settingsService;

    public AppDetails AppDetails { get; }

    [ObservableProperty]
    public partial string LastBackupDisplay { get; set; } = "Never";

    public AboutViewModel(SettingsService settingsService)
    {
        this.settingsService = settingsService;

        AppDetails = new(
            AppInfo.Current.Name,
            AppInfo.Current.VersionString,
            AppInfo.Current.BuildString,
            AppInfo.Current.PackageName,
            ChoreDatabaseService.DatabasePath
        );

        UpdateBackupDisplay();
    }

    public void UpdateBackupDisplay()
    {
        var lastBackup = settingsService.LastBackupDate;
        LastBackupDisplay = lastBackup.HasValue
            ? lastBackup.Value.ToString("MMM dd, yyyy @ hh:mm tt")
            : "Never";
    }
}
