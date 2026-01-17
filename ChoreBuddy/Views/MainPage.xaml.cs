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

        vm.RequestScrollToItem += (sender, item) =>
        {
            MainThread.BeginInvokeOnMainThread(() =>
            {
                ChoreList.ScrollTo(item, position: ScrollToPosition.MakeVisible, animate: true);
            });
        };
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        ViewModel?.StartRefreshTimer();
    }

    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        ViewModel?.StopRefreshTimer();
    }
}
