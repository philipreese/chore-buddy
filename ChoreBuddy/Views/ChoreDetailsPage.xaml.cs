using ChoreBuddy.Messages;
using ChoreBuddy.ViewModels;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.Views;

public partial class ChoreDetailsPage : ContentPage
{
    private bool isPanelOpen = false;
    private bool shouldKeepPanelOpenOnReturn = false;
    public ChoreDetailViewModel? ViewModel => BindingContext as ChoreDetailViewModel;

    public ChoreDetailsPage(ChoreDetailViewModel vm)
	{
		InitializeComponent();
		BindingContext = vm;
        WeakReferenceMessenger.Default.Register<ReturningFromTagsMessage>(this, (r, m) =>
        {
            shouldKeepPanelOpenOnReturn = true;
        });
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();

        if (ViewModel != null)
        {
            bool open = shouldKeepPanelOpenOnReturn || ViewModel.ChoreId == 0;
            shouldKeepPanelOpenOnReturn = false;

            SetPanelState(open);
            MainThread.BeginInvokeOnMainThread(async () => await LoadDataDeferred());

            if (ViewModel.ChoreId == 0)
            {
                Dispatcher.DispatchDelayed(TimeSpan.FromMilliseconds(450), () =>
                {
                    ChoreNameEntry.Focus();
                });
            }
        }
    }

    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        ViewModel?.CancelLoading();
    }

    private async Task LoadDataDeferred()
    {
        // Add a tiny delay to allow the OS to finish the push animation
        await Task.Delay(350);

        if (ViewModel != null)
        {
            await ViewModel.LoadDataAsync();
        }
    }

    private void SetPanelState(bool open)
    {
        isPanelOpen = open;

        if (open)
        {
            EditPanel.IsVisible = true;
            EditPanel.Opacity = 1;
            EditPanel.TranslationY = 0;
        }
        else
        {
            EditPanel.IsVisible = false;
            EditPanel.Opacity = 0;
            EditPanel.TranslationY = -600;
        }
    }

    private async void OnToggleEditPanelClicked(object sender, EventArgs e)
    {
        if (EditPanel.AnimationIsRunning("PanelAnimation")) return;

        if (isPanelOpen)
        {
            await Task.WhenAll(
                EditPanel.TranslateTo(0, -EditPanel.Height, 250, Easing.CubicIn),
                EditPanel.FadeTo(0, 200)
            );
            EditPanel.IsVisible = false;
        }
        else
        {
            EditPanel.TranslationY = -50;
            EditPanel.Opacity = 0;
            EditPanel.IsVisible = true;

            await Task.WhenAll(
                EditPanel.TranslateTo(0, 0, 300, Easing.CubicOut),
                EditPanel.FadeTo(1, 250)
            );
        }

        isPanelOpen = !isPanelOpen;
    }
}