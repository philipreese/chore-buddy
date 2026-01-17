using ChoreBuddy.ViewModels;
using CommunityToolkit.Maui.Views;

namespace ChoreBuddy.Views;

public partial class MenuPopup : Popup
{
    public MainViewModel? ViewModel => BindingContext as MainViewModel;

    public MenuPopup(MainViewModel viewModel)
	{
		InitializeComponent();
        BindingContext = viewModel;
    }

    private async void OnNavigateSettingsClicked(object sender, EventArgs e)
    {
        await CloseAsync();
        ViewModel?.NavigateToSettingsCommand.Execute(null);
    }

    private async void OnNavigateAboutClicked(object sender, EventArgs e)
    {
        await CloseAsync();
        ViewModel?.NavigateToAboutCommand.Execute(null);
    }

    private async void OnDeleteAllChoresCommand(object sender, EventArgs e)
    {
        await CloseAsync();
        ViewModel?.DeleteAllChoresCommand.Execute(null);
    }
}