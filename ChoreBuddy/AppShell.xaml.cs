namespace ChoreBuddy;

public partial class AppShell : Shell
{
    public AppShell()
    {
        InitializeComponent();

        Routing.RegisterRoute(nameof(Views.ChoreDetailsPage), typeof(Views.ChoreDetailsPage));
    }
}
