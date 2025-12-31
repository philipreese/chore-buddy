namespace ChoreBuddy;

public partial class AppShell : Shell
{
    public AppShell()
    {
        InitializeComponent();

        Routing.RegisterRoute(nameof(Views.ChoreDetailsPage), typeof(Views.ChoreDetailsPage));
        Routing.RegisterRoute(nameof(Views.TagsPage), typeof(Views.TagsPage));
        Routing.RegisterRoute(nameof(Views.AboutPage), typeof(Views.AboutPage));
    }
}
