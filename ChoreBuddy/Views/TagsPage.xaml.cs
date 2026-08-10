using ChoreBuddy.Messages;
using ChoreBuddy.ViewModels;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.Views;

public partial class TagsPage : ContentPage
{
    public TagsViewModel? ViewModel => BindingContext as TagsViewModel;
    private bool isLoaded = false;

    public TagsPage(TagsViewModel vm)
	{
		InitializeComponent();
        BindingContext = vm;
    }

    protected override void OnNavigatedTo(NavigatedToEventArgs args)
    {
        base.OnNavigatedTo(args);
        if (isLoaded)
        {
            return;
        }

        if (ViewModel != null)
        {
            // Yield one frame so any IsBusy spinner paints, then load on background thread.
            Dispatcher.DispatchAsync(() =>
            {
                Task.Run(async () =>
                {
                    await ViewModel.LoadTags();
                    isLoaded = true;
                });
            });
        }
    }

    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        WeakReferenceMessenger.Default.Send(new ReturningFromTagsMessage());
    }
}