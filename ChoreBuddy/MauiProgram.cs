using CommunityToolkit.Maui;
using Microsoft.Extensions.Logging;
using Plugin.LocalNotification;

namespace ChoreBuddy;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder.UseMauiApp<App>();
        builder.UseLocalNotification();

#if ANDROID || WINDOWS || TIZEN
        builder.UseMauiCommunityToolkit(options => options.SetShouldEnableSnackbarOnWindows(true));
#elif IOS || MACCATALYST
        if (OperatingSystem.IsIOSVersionAtLeast(15) ||
            OperatingSystem.IsMacCatalystVersionAtLeast(15))
        {
            builder.UseMauiCommunityToolkit();
        }
#endif

        builder.ConfigureFonts(fonts =>
        {
            fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
            fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
            fonts.AddFont("fa-solid-900.ttf", "FontAwesome");
        });

        builder.Services.AddSingleton<Services.ChoreDatabaseService>();
        builder.Services.AddSingleton<Services.SettingsService>();
        builder.Services.AddSingleton<Services.MigrationService>();
        builder.Services.AddSingleton<Services.NotificationService>();
        builder.Services.AddSingleton<Services.ThemeService>();
        builder.Services.AddSingleton<App>();
        builder.Services.AddSingleton<ViewModels.MainViewModel>();
        builder.Services.AddSingleton<ViewModels.ChoreDetailViewModel>();
        builder.Services.AddSingleton<ViewModels.TagsViewModel>();
        builder.Services.AddTransient<ViewModels.AboutViewModel>();
        builder.Services.AddTransient<ViewModels.SettingsViewModel>();
        builder.Services.AddSingleton<ViewModels.ArchiveViewModel>();
        builder.Services.AddSingleton<Views.MainPage>();
        builder.Services.AddSingleton<Views.ChoreDetailsPage>();
        builder.Services.AddSingleton<Views.TagsPage>();
        builder.Services.AddTransient<Views.AboutPage>();
        builder.Services.AddTransient<Views.SettingsPage>();
        builder.Services.AddSingleton<Views.ArchivePage>();

#if DEBUG
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}
