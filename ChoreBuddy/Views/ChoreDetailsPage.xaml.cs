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

    protected override async void OnAppearing()
    {
        base.OnAppearing();

        if (BindingContext is ChoreDetailViewModel vm)
        {
            bool open;
            if (shouldKeepPanelOpenOnReturn)
            {
                open = true;
                shouldKeepPanelOpenOnReturn = false;
            }
            else
            {
                open = vm.ChoreId == 0;
            }

            SetPanelState(open);

            if (vm.ChoreId == 0)
            {
                await Task.Delay(300);
                MainThread.BeginInvokeOnMainThread(() =>
                {
                    ChoreNameEntry.Focus();
                });
            }
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