using System.Globalization;

namespace ChoreBuddy.Converters;

public class ColorToBrushConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is string colorHex)
        {
            return new SolidColorBrush(Color.FromArgb(colorHex));
        }

        return new SolidColorBrush(Colors.Transparent);
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
