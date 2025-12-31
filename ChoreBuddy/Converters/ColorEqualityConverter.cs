using System.Globalization;

namespace ChoreBuddy.Converters;

public class ColorEqualityConverter : IMultiValueConverter
{
    public object Convert(object[] values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values == null || values.Length < 2 || values[0] == null || values[1] == null)
            return false;

        string color1 = GetHex(values[0]);
        string color2 = GetHex(values[1]);

        return color1.Equals(color2, StringComparison.OrdinalIgnoreCase);
    }

    private string GetHex(object obj)
    {
        if (obj is Color c) return c.ToHex();
        return obj.ToString() ?? string.Empty;
    }

    public object[] ConvertBack(object value, Type[] targetType, object? parameter, CultureInfo culture)
    {
        throw new NotSupportedException("ConvertBack is not supported.");
    }
}
