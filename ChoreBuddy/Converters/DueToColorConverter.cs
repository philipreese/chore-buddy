using System.Globalization;

namespace ChoreBuddy.Converters;

public class DueToColorConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is DateTime nextDue)
        {
            var now = DateTime.Now;

            if (now > nextDue)
            {
                if (Application.Current?.PlatformAppTheme == AppTheme.Light)
                {
                    if (Application.Current?.Resources.TryGetValue("ErrorLight", out var error) == true)
                    {
                        return (Color)error;
                    }
                }
                else
                {
                    if (Application.Current?.Resources.TryGetValue("ErrorDark", out var error) == true)
                    {
                        return (Color)error;
                    }
                }

                return Colors.Red;
            }

            if (nextDue - now <= TimeSpan.FromHours(24))
            {
                if (Application.Current?.PlatformAppTheme == AppTheme.Light)
                {
                    if (Application.Current?.Resources.TryGetValue("WarningLight", out var error) == true)
                    {
                        return (Color)error;
                    }
                }
                else
                {
                    if (Application.Current?.Resources.TryGetValue("WarningDark", out var error) == true)
                    {
                        return (Color)error;
                    }
                }

                return Colors.Orange;
            }

            if (Application.Current?.PlatformAppTheme == AppTheme.Light)
            {
                if (Application.Current?.Resources.TryGetValue("PrimaryLight", out var primary) == true)
                {
                    return (Color)primary;
                }
            }
            else 
            {
                if (Application.Current?.Resources.TryGetValue("PrimaryDark", out var primary) == true)
                {
                    return (Color)primary;
                }
            }

            return Colors.Gray;
        }

        return Colors.Transparent;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => throw new NotImplementedException();
}