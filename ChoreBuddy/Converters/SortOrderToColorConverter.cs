using System.Globalization;
using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Converters;

public partial class SortOrderToColorConverter : BindableObject, IValueConverter
{
    public string ActiveBaseKey { get; set; } = "Primary";
    public string InactiveKey { get; set; } = "OutlineLight";

    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is ChoreSortOrder currentOrder && parameter is ChoreSortOrder targetOrder)
        {
            string baseKey = currentOrder == targetOrder ? ActiveBaseKey : InactiveKey;
            string fullKey = baseKey;
            if (currentOrder == targetOrder)
            {
                var themeSuffix = Application.Current?.RequestedTheme == AppTheme.Dark ? "Dark" : "Light";
                fullKey = $"{baseKey}{themeSuffix}";
            }

            if (Application.Current?.Resources.TryGetValue(fullKey, out var color) == true)
            {
                return (Color)color;
            }
        }

        return Colors.Transparent;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => throw new NotImplementedException();
}