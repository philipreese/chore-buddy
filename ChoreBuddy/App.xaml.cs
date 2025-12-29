using ChoreBuddy.Services;

namespace ChoreBuddy;

public partial class App : Application
{
    public App(ChoreDatabaseService databaseService)
    {
        InitializeComponent();

        Task.Run(async () => await databaseService.InitializeAsync());
    }

    protected override Window CreateWindow(IActivationState? activationState)
    {
        return new Window(new AppShell());
    }
}
