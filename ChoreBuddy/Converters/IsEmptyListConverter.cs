using System.Globalization;

namespace ChoreBuddy.Converters;

public class IsEmptyListConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value == null)
        {
            return true;
        }

        if (value is System.Collections.IEnumerable enumerable)
            return !enumerable.GetEnumerator().MoveNext();

        return false;
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotSupportedException("ConvertBack is not supported.");
    }
}