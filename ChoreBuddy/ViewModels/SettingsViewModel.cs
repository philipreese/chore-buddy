using ChoreBuddy.Services;
using CommunityToolkit.Mvvm.ComponentModel;

namespace ChoreBuddy.ViewModels;

public partial class SettingsViewModel : ObservableObject
{
    private readonly SettingsService settingsService;
    private bool isInitializing;

    [ObservableProperty]
    public partial bool IsHapticFeedbackEnabled { get; set; }

    public SettingsViewModel(SettingsService settingsService)
    {
        this.settingsService = settingsService;
        LoadSettings();
    }

    private void LoadSettings()
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

    partial void OnIsHapticFeedbackEnabledChanged(bool value)
    {
        if (!isInitializing && settingsService.IsHapticFeedbackEnabled != value)
        {
            settingsService.IsHapticFeedbackEnabled = value;
        }
    }
}
