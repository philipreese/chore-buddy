using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Views;

public partial class AboutPage : ContentPage
{
    public AboutViewModel? ViewModel => BindingContext as AboutViewModel;

    public AboutPage(AboutViewModel vm)
	{
		InitializeComponent();
        BindingContext = vm;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        ViewModel?.UpdateBackupDisplay();
    }

    private async void WebsiteButton_Clicked(object sender, EventArgs e)
    {
        await Application.Current!.Windows[0].Page!.DisplayAlert("My Website", $"Coming... soon?", " OH - OK");
    }
}