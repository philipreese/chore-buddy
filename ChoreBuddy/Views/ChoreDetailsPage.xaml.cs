using ChoreBuddy.Messages;
using ChoreBuddy.ViewModels;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.Views;

public partial class ChoreDetailsPage : ContentPage
{
    private bool isPanelOpen = false;
    private double measuredPanelHeight = -1;
    private int previousChoreId = -1;

    public ChoreDetailViewModel? ViewModel => BindingContext as ChoreDetailViewModel;

    public ChoreDetailsPage(ChoreDetailViewModel vm)
	{
		InitializeComponent();
		BindingContext = vm;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();

        if (ViewModel != null)
        {
            bool open = ViewModel.ChoreId == 0 || isPanelOpen;

            if (!open)
            {
                EditPanel.IsVisible = true;
                EditPanel.Opacity = 0.01;
                EditPanel.TranslationY = 0;

                // Allow the UI thread to finish one layout pass
                await Task.Yield();
                await Task.Delay(50);
            }

            var size = EditPanel.Measure(this.Width, double.PositiveInfinity);
            measuredPanelHeight = size.Height;
            SetPanelState(open);

            if (previousChoreId != ViewModel.ChoreId)
            {
                previousChoreId = ViewModel.ChoreId;
                MainThread.BeginInvokeOnMainThread(async () => await LoadDataDeferred());

                if (open)
                {
                    Dispatcher.DispatchDelayed(TimeSpan.FromMilliseconds(450), () =>
                    {
                        ChoreNameEntry.Focus();
                    });
                }
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
        await Task.Delay(350);

        if (ViewModel != null)
        {
            await ViewModel.LoadDataAsync();
        }
    }

    private void SetPanelState(bool open)
    {
        isPanelOpen = open;

        EditPanel.HeightRequest = open ? -1 : 0;
        EditPanel.Opacity = open ? 1 : 0;
        EditPanel.IsVisible = open;
        EditPanel.InputTransparent = !open;
    }

    private async void OnToggleEditPanelClicked(object sender, EventArgs e)
    {
        if (EditPanel.AnimationIsRunning("PanelAnimation")) return;

        if (isPanelOpen)
        {
            measuredPanelHeight = EditPanel.Height;
            isPanelOpen = false;
            EditPanel.InputTransparent = true;

            var collapseAnimation = new Animation(v => EditPanel.HeightRequest = v, measuredPanelHeight, 0);

            await Task.WhenAll(
                EditPanel.FadeTo(0, 300),
                Task.Run(() => {
                    collapseAnimation.Commit(this, "PanelAnimation", 16, 350, Easing.CubicIn);
                })
            );

            EditPanel.IsVisible = false;
        }
        else
        {
            isPanelOpen = true;
            EditPanel.InputTransparent = false;

            EditPanel.HeightRequest = 0;
            EditPanel.Opacity = 0;
            EditPanel.IsVisible = true;

            var expandAnimation = new Animation(v => EditPanel.HeightRequest = v, 0, measuredPanelHeight);

            await Task.WhenAll(
                EditPanel.FadeTo(1, 250),
                Task.Run(() => {
                    expandAnimation.Commit(this, "PanelAnimation", 16, 300, Easing.CubicOut, (v, c) => {
                        EditPanel.HeightRequest = -1;
                    });
                })
            );
        }
    }
}