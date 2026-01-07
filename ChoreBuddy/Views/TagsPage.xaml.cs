using ChoreBuddy.Messages;
using ChoreBuddy.ViewModels;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.Views;

public partial class TagsPage : ContentPage
{
    public TagsViewModel? ViewModel => BindingContext as TagsViewModel;

    public TagsPage(TagsViewModel vm)
	{
		InitializeComponent();
        BindingContext = vm;
    }

    protected override void OnNavigatedTo(NavigatedToEventArgs args)
    {
        base.OnAppearing();
        Dispatcher.DispatchDelayed(TimeSpan.FromMilliseconds(350), async () =>
        {
            if (ViewModel != null)
            {
                await ViewModel.LoadTags();
            }
        });
    }

    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        WeakReferenceMessenger.Default.Send(new ReturningFromTagsMessage());
    }
}