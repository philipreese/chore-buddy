using ChoreBuddy.Messages;
using ChoreBuddy.ViewModels;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.Views;

public partial class ChoreDetailsPage : ContentPage
{
    private bool isPanelOpen = false;
    private double measuredPanelHeight = -1;
    private int previousChoreId = -1;
    private Task? prefetchTask;

    public ChoreDetailViewModel? ViewModel => BindingContext as ChoreDetailViewModel;

    public ChoreDetailsPage(ChoreDetailViewModel vm)
	{
		InitializeComponent();
		BindingContext = vm;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();

        if (ViewModel == null) return;

        bool isNewChore = previousChoreId != ViewModel.ChoreId || ViewModel.ChoreId == 0;

        if (isNewChore)
        {
            // Pre-set loading state on main thread before animation starts so that
            // background thread property changes are no-ops during the slide.
            ViewModel.IsBusy = true;
            ViewModel.IsHistoryLoading = true;
            prefetchTask = Task.Run(ViewModel.PrefetchAsync);
        }
    }

    protected override void OnNavigatedTo(NavigatedToEventArgs args)
    {
        base.OnNavigatedTo(args);

        if (ViewModel == null) return;

        bool isNewChore = previousChoreId != ViewModel.ChoreId || ViewModel.ChoreId == 0;

        if (isNewChore)
        {
            bool open = ViewModel.ChoreId == 0 || (isPanelOpen && previousChoreId == ViewModel.ChoreId);
            previousChoreId = ViewModel.ChoreId;
            SetPanelState(open);
        }

        if (prefetchTask != null)
        {
            var taskToApply = prefetchTask;
            prefetchTask = null;

            Dispatcher.DispatchAsync(async () =>
            {
                await taskToApply;
                ViewModel.ApplyPrefetchedData();
            });
        }
    }

    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        if (ViewModel != null)
        {
            if (ViewModel.ChoreSaved)
            {
                SetPanelState(false);
                ViewModel.ChoreSaved = false;
            }

            ViewModel.CancelLoading();
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
                EditPanel.FadeToAsync(0, 300),
                Task.Run(() => {
                    collapseAnimation.Commit(this, "PanelAnimation", 16, 350, Easing.CubicIn);
                })
            );

            EditPanel.IsVisible = false;
        }
        else
        {
            if (measuredPanelHeight <= 0)
            {
                var tcs = new TaskCompletionSource();
                void OnSizeChanged(object? s, EventArgs e)
                {
                    EditPanel.SizeChanged -= OnSizeChanged;
                    measuredPanelHeight = EditPanel.Height;
                    EditPanel.HeightRequest = 0;
                    tcs.SetResult();
                }

                EditPanel.SizeChanged += OnSizeChanged;
                EditPanel.IsVisible = true;
                EditPanel.Opacity = 0.01;
                EditPanel.HeightRequest = -1;
                await tcs.Task;
            }

            isPanelOpen = true;
            EditPanel.InputTransparent = false;

            EditPanel.HeightRequest = 0;
            EditPanel.Opacity = 0;
            EditPanel.IsVisible = true;

            var expandAnimation = new Animation(v => EditPanel.HeightRequest = v, 0, measuredPanelHeight);

            await Task.WhenAll(
                EditPanel.FadeToAsync(1, 250),
                Task.Run(() => {
                    expandAnimation.Commit(this, "PanelAnimation", 16, 300, Easing.CubicOut, (v, c) => {
                        EditPanel.HeightRequest = -1;
                    });
                })
            );
        }
    }
}