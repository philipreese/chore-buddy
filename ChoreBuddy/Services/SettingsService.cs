namespace ChoreBuddy.Services;

public class SettingsService
{
    private const string HapticFeedbackEnabledKey = "haptic_feedback_enabled";
    private const string LastBackupDateKey = "last_backup_date";
    private const string GlobalNotificationsEnabledKey = "global_notifications_enabled";
    private const string ShowHistoryOnCardsKey = "show_history_on_cards";
    private const string SelectedThemeKey = "selected_theme_name";

    public bool IsHapticFeedbackEnabled
    {
        get => Preferences.Default.Get(HapticFeedbackEnabledKey, true);
        set => SetValue(HapticFeedbackEnabledKey, value);
    }

    public DateTime? LastBackupDate
    {
        get
        {
            long ticks = Preferences.Default.Get(LastBackupDateKey, 0L);
            return ticks == 0 ? null : new DateTime(ticks);
        }
        set
        {
            if (value.HasValue)
                SetValue(LastBackupDateKey, value.Value.Ticks);
        }
    }

    public bool IsGlobalNotificationsEnabled
    {
        get => Preferences.Default.Get(GlobalNotificationsEnabledKey, true);
        set => SetValue(GlobalNotificationsEnabledKey, value);
    }

    public bool IsHistoryOnCardsVisible
    {
        get => Preferences.Default.Get(ShowHistoryOnCardsKey, false);
        set => SetValue(ShowHistoryOnCardsKey, value);
    }

    public string SelectedThemeName
    {
        get => Preferences.Default.Get(SelectedThemeKey, "Chambray");
        set => SetValue(SelectedThemeKey, value);
    }

    private void SetValue<T>(string key, T value)
    {
        SetValueSilent(key, value);
        ProvideHapticFeedback();
    }

    public void SetValueSilent<T>(string key, T value)
    {
        Preferences.Default.Set(key, value);
    }

    public void ProvideHapticFeedback(int ms = 100)
    {
        try
        {
            if (IsHapticFeedbackEnabled)
            {
                Vibration.Default.Vibrate(TimeSpan.FromMilliseconds(ms));
            }
        }
        catch (FeatureNotSupportedException) { } // Device doesn't support vibration
        catch (Exception) { } // General safety catch for haptics
    }
}