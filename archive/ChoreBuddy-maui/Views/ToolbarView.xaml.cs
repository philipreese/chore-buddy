using ChoreBuddy.ViewModels;
using CommunityToolkit.Maui.Extensions;

namespace ChoreBuddy.Views;

public partial class ToolbarView : ContentView
{
    // Warm instances resolved on menu open; consumed once by MenuPopup navigation
    private Views.SettingsPage? warmedSettings;
    private Views.AboutPage? warmedAbout;

    public ToolbarView()
    {
        InitializeComponent();
    }

    private void OnMenuButtonClicked(object sender, EventArgs e)
    {
        if (BindingContext is not MainViewModel vm)
        {
            return;
        }

        // Resolve both pages from DI now, before the popup is shown.
        // InitializeComponent() runs here on the main thread while the popup
        // is animating open, so it's already complete by the time the user taps.
        warmedSettings = App.Services.GetRequiredService<Views.SettingsPage>();
        warmedAbout = App.Services.GetRequiredService<Views.AboutPage>();

        var popup = new MenuPopup(vm, warmedSettings, warmedAbout)
        {
            HorizontalOptions = LayoutOptions.End,
            VerticalOptions = LayoutOptions.Start
        };
        Shell.Current.ShowPopup(popup);
    }
}