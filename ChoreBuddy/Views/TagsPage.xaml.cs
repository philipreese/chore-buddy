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

    protected override void OnAppearing()
    {
        base.OnAppearing();
        if (isLoaded)
        {
            return;
        }

        Dispatcher.DispatchDelayed(TimeSpan.FromMilliseconds(350), async () =>
        {
            if (ViewModel != null)
            {
                await ViewModel.LoadTags();
                isLoaded = true;
            }
        });
    }

    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        WeakReferenceMessenger.Default.Send(new ReturningFromTagsMessage());
    }
}