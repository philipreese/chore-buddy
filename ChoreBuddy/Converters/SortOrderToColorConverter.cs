using System.Globalization;
using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Converters;

public class SortOrderToColorConverter : BindableObject, IValueConverter
{
    public static readonly BindableProperty ActiveColorProperty =
            BindableProperty.Create(nameof(ActiveColor), typeof(Color), typeof(SortOrderToColorConverter), Colors.Blue);

    public Color ActiveColor
    {
        get => (Color)GetValue(ActiveColorProperty);
        set => SetValue(ActiveColorProperty, value);
    }

    public static readonly BindableProperty InactiveColorProperty =
            BindableProperty.Create(nameof(InactiveColor), typeof(Color), typeof(SortOrderToColorConverter), Colors.Gray);

    public Color InactiveColor
    {
        get => (Color)GetValue(InactiveColorProperty);
        set => SetValue(InactiveColorProperty, value);
    }

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