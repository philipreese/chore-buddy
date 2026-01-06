namespace ChoreBuddy.Views;

public partial class AboutPage : ContentPage
{
	public AboutPage()
	{
		InitializeComponent();

        BindingContext = new AboutBindingContext(
            AppInfo.Current.Name,
            AppInfo.Current.VersionString,
            AppInfo.Current.BuildString,
            AppInfo.Current.PackageName
        );
    }

    private async void WebsiteButton_Clicked(object sender, EventArgs e)
    {
        await Application.Current!.Windows[0].Page!.DisplayAlert("My Website", $"Coming... soon?", " OH - OK");
    }
}

public partial class AboutBindingContext(
    string AppName,
    string Version,
    string Build,
    string PackageName) : BindableObject
{
    public string AppName { get; } = AppName;
    public string Version { get; } = Version;
    public string Build { get; } = Build;
    public string PackageName { get; } = PackageName;
}