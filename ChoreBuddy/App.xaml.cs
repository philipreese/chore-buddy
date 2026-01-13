using ChoreBuddy.Services;
using CommunityToolkit.Maui.Core;
using Plugin.LocalNotification;

namespace ChoreBuddy;

public partial class App : Application
{
    private readonly NotificationService notificationService;

    public App(ChoreDatabaseService databaseService, NotificationService notificationService)
    {
        InitializeComponent();
        this.notificationService = notificationService;

        Task.Run(databaseService.InitializeAsync);

        RequestedThemeChanged += (s, e) =>
        {
            UpdateStatusBar(e.RequestedTheme);
        };
    }

    protected override Window CreateWindow(IActivationState? activationState)
    {
        return new Window(new AppShell());
    }

    protected override async void OnStart()
    {
        base.OnStart();
        UpdateStatusBar(RequestedTheme);

        if (notificationService != null)
        {
            bool granted = await notificationService.RequestPermissions();

            if (!granted)
            {
                System.Diagnostics.Debug.WriteLine("Notification permissions were denied by the user.");
            }
        }
    }

    private void UpdateStatusBar(AppTheme theme)
    {
        MainThread.BeginInvokeOnMainThread(() =>
        {
            try
            {
                var color = theme == AppTheme.Dark
                    ? (Color)Resources["SurfaceDark"]
                    : (Color)Resources["SurfaceLight"];

                var style = theme == AppTheme.Dark
                    ? StatusBarStyle.LightContent
                    : StatusBarStyle.DarkContent;

                CommunityToolkit.Maui.Core.Platform.StatusBar.SetColor(color);
                CommunityToolkit.Maui.Core.Platform.StatusBar.SetStyle(style);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Status bar update failed: {ex.Message}");
            }
        });
    }
}
