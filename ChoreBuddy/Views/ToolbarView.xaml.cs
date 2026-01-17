using ChoreBuddy.ViewModels;
using CommunityToolkit.Maui.Extensions;

namespace ChoreBuddy.Views;

public partial class ToolbarView : ContentView
{
	public ToolbarView()
	{
		InitializeComponent();
	}

    private async void OnMenuButtonClicked(object sender, EventArgs e)
    {
        if (BindingContext is MainViewModel vm)
        {
            var popup = new MenuPopup(vm)
            {
                HorizontalOptions = LayoutOptions.End,
                VerticalOptions = LayoutOptions.Start
            };
            Shell.Current.ShowPopup(popup);
        }
    }
}