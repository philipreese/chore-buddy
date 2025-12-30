using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Views;

public partial class ChoreDetailsPage : ContentPage
{
    private bool isPanelOpen = false;
    public ChoreDetailViewModel? ViewModel => BindingContext as ChoreDetailViewModel;

    public ChoreDetailsPage(ChoreDetailViewModel vm)
	{
		InitializeComponent();
		BindingContext = vm;
	}

    private async void OnToggleEditPanelClicked(object sender, EventArgs e)
    {
        if (isPanelOpen)
        {
            // Slide Up / Close
            await Task.WhenAll(
                EditPanel.TranslateTo(0, -EditPanel.Height, 250, Easing.CubicIn),
                EditPanel.FadeTo(0, 200)
            );
            EditPanel.IsVisible = false;
        }
        else
        {
            // Initialize Position
            EditPanel.TranslationY = -50; // Start slightly above
            EditPanel.Opacity = 0;
            EditPanel.IsVisible = true;

            // Slide Down / Open
            await Task.WhenAll(
                EditPanel.TranslateTo(0, 0, 300, Easing.CubicOut),
                EditPanel.FadeTo(1, 250)
            );
        }

        isPanelOpen = !isPanelOpen;
    }
}