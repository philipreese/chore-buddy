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
    }
}
