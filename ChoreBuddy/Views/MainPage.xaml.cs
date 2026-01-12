using ChoreBuddy.Converters;
using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Views;

public partial class MainPage : ContentPage
{
    public MainViewModel? ViewModel => BindingContext as MainViewModel;

    public MainPage(MainViewModel vm)
    {
        InitializeComponent();
        BindingContext = vm;

        vm.Chores.CollectionChanged += (s, e) =>
        {
            if (e.Action == System.Collections.Specialized.NotifyCollectionChangedAction.Reset ||
                e.Action == System.Collections.Specialized.NotifyCollectionChangedAction.Add)
            {
                MainThread.BeginInvokeOnMainThread(() =>
                {
                    if (vm.Chores.Count > 0)
                    {
                        ChoreList.ScrollTo(0, position: ScrollToPosition.Start, animate: false);
                    }
                });
            }
        };

        if (Application.Current != null)
        {
            Application.Current.RequestedThemeChanged += (s, e) =>
            {
                MainThread.BeginInvokeOnMainThread(() =>
                {
                    if (Application.Current.Resources.TryGetValue("SortOrderToColorConverter", out var res) &&
    res is SortOrderToColorConverter converter)
                    {
                        // 2. Proactively set the colors based on the new theme.
                        // This avoids hardcoding strings because we are using the 
                        // static resource keys defined in your Colors.xaml.
                        var theme = e.RequestedTheme;

                        converter.ActiveColor = theme == AppTheme.Dark
                            ? (Color)Application.Current.Resources["PrimaryDark"]
                            : (Color)Application.Current.Resources["PrimaryLight"];

                        converter.InactiveColor = (Color)Application.Current.Resources["OutlineLight"];
                    }
                    foreach (var item in ToolbarItems)
                    {
                        var context = item.BindingContext;
                        item.BindingContext = null;
                        item.BindingContext = context;
                    }
                });
            };
        }
    }
}
