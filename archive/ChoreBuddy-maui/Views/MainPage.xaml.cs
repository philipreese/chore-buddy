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
            // Only scroll to top when the entire list is replaced (Reset) or when the
            // very first item arrives (going from empty → populated). Firing on every
            // individual Add causes N redundant ScrollTo calls during the initial
            // per-item insert loop, which interrupts the layout pipeline and causes jank.
            bool isReset = e.Action == System.Collections.Specialized.NotifyCollectionChangedAction.Reset;
            bool isFirstItem = e.Action == System.Collections.Specialized.NotifyCollectionChangedAction.Add
                               && vm.Chores.Count == 1;

            if (isReset || isFirstItem)
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
