using System.Globalization;

namespace ChoreBuddy.Converters;

/// <summary>
/// Returns a theme-aware color based on a chore's due date proximity.
/// Colors are read from <see cref="DueColorCache"/> (resolved once per theme change)
/// rather than doing a ResourceDictionary lookup on every Convert() call.
/// </summary>
public class DueToColorConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is not DateTime nextDue)
        {
            return Colors.Transparent;
        }

        var now = DateTime.Now;

        if (now > nextDue)
        {
            return DueColorCache.Overdue;
        }

        if (nextDue - now <= TimeSpan.FromHours(24))
        {
            return DueColorCache.DueSoon;
        }

        return DueColorCache.OnTime;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => throw new NotImplementedException();
}