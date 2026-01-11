namespace ChoreBuddy.Services;

public class SettingsService
{
    private const string HapticFeedbackEnabledKey = "haptic_feedback_enabled";
    private const string LastBackupDateKey = "last_backup_date";

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

    private void SetValue<T>(string key, T value)
    {
        Preferences.Default.Set(key, value);
        ProvideHapticFeedback();
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