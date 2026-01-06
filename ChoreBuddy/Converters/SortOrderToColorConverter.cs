using System.Globalization;
using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Converters;

public class SortOrderToColorConverter : IValueConverter
{
    public Color ActiveColor { get; set; } = Colors.Blue;
    public Color InactiveColor { get; set; } = Colors.Gray;

    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is ChoreSortOrder currentOrder && parameter is ChoreSortOrder targetOrder)
        {
            return currentOrder == targetOrder ? ActiveColor : InactiveColor;
        }
        return InactiveColor;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture) => throw new NotImplementedException();
}