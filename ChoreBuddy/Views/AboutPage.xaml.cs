namespace ChoreBuddy.Views;

public partial class AboutPage : ContentPage
{
	public AboutPage()
	{
		InitializeComponent();

        BindingContext = new
        {
            AppName = AppInfo.Current.Name,
            Version = AppInfo.Current.VersionString,
            Build = AppInfo.Current.BuildString,
            AppInfo.Current.PackageName
        };
    }

    private async void WebsiteButton_Clicked(object sender, EventArgs e)
    {
        await Application.Current!.Windows[0].Page!.DisplayAlert("My Website", $"Coming... soon?", " OH - OK");
    }
}