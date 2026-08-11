using System.Globalization;

namespace ChoreBuddy.Converters;

public class SearchModeToIconConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        bool isSearchMode = value is bool b && b;
        return isSearchMode ? "\uf00d" : "\uf002";
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture) => throw new NotImplementedException();
}
