using System.Globalization;

namespace ChoreBuddy.Converters;

public class IsGreaterThanZeroConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        bool isGreater = false;

        if (value is int count)
        {
            isGreater = count > 0;
        }
        else if (value is long longCount)
        {
            isGreater = longCount > 0;
        }

        if (parameter is string paramString && paramString.Equals("Inverse", StringComparison.OrdinalIgnoreCase))
        {
            return !isGreater;
        }

        return isGreater;
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotSupportedException("ConvertBack is not supported.");
    }
}