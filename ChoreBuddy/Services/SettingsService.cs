namespace ChoreBuddy.Services;

public class SettingsService
{
    private const string HapticFeedbackEnabledKey = "haptic_feedback_enabled";

    public bool IsHapticFeedbackEnabled
    {
        get => Preferences.Default.Get(HapticFeedbackEnabledKey, true);
        set => SetValue(HapticFeedbackEnabledKey, value);
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