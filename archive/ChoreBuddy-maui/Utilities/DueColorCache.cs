namespace ChoreBuddy.Converters;

/// <summary>
/// Resolves theme-aware due-date colors once per theme change and caches them,
/// rather than performing a ResourceDictionary lookup on every converter call.
/// Call <see cref="RefreshFromTheme"/> whenever the app theme changes.
/// </summary>
public static class DueColorCache
{
    public static Color Overdue { get; private set; } = Colors.Red;
    public static Color DueSoon { get; private set; } = Colors.Orange;
    public static Color OnTime { get; private set; } = Colors.Gray;

    public static void RefreshFromTheme()
    {
        var res = Application.Current?.Resources;
        if (res == null)
        {
            return;
        }

        bool isDark = Application.Current?.PlatformAppTheme == AppTheme.Dark;

        Overdue = GetColor(res, isDark ? "ErrorDark" : "ErrorLight", Colors.Red);
        DueSoon = GetColor(res, isDark ? "WarningDark" : "WarningLight", Colors.Orange);
        OnTime = GetColor(res, isDark ? "PrimaryDark" : "PrimaryLight", Colors.Gray);
    }

    private static Color GetColor(ResourceDictionary resources, string key, Color fallback)
    {
        if (resources.TryGetValue(key, out var value) && value is Color c)
        {
            return c;
        }

        return fallback;
    }
}
