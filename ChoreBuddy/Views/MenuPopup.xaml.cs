using ChoreBuddy.ViewModels;
using CommunityToolkit.Maui.Views;

namespace ChoreBuddy.Views;

public partial class MenuPopup : Popup
{
    public MainViewModel? ViewModel => BindingContext as MainViewModel;

    private readonly SettingsPage settingsPage;
    private readonly AboutPage aboutPage;

    public MenuPopup(MainViewModel viewModel, SettingsPage settingsPage, AboutPage aboutPage)
    {
        InitializeComponent();
        BindingContext = viewModel;
        this.settingsPage = settingsPage;
        this.aboutPage = aboutPage;
    }

    private async void OnNavigateSettingsClicked(object sender, EventArgs e)
    {
        await CloseAsync();
        await Shell.Current.GoToAsync("SettingsPage");
    }

    private async void OnNavigateAboutClicked(object sender, EventArgs e)
    {
        await CloseAsync();
        await Shell.Current.GoToAsync("AboutPage");
    }

    private async void OnDeleteAllChoresCommand(object sender, EventArgs e)
    {
        await CloseAsync();
        ViewModel?.DeleteAllChoresCommand.Execute(null);
    }
}