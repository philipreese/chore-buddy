using CommunityToolkit.Maui;
using Microsoft.Extensions.Logging;

namespace ChoreBuddy;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder.UseMauiApp<App>();

#if ANDROID || WINDOWS || TIZEN
        builder.UseMauiCommunityToolkit();
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
        builder.Services.AddSingleton<App>();
        builder.Services.AddSingleton<ViewModels.MainViewModel>();
        builder.Services.AddTransient<ViewModels.ChoreDetailViewModel>();
        builder.Services.AddTransient<ViewModels.TagsViewModel>();
        builder.Services.AddTransient<ViewModels.SettingsViewModel>();
        builder.Services.AddTransient<ViewModels.ArchiveViewModel>();
        builder.Services.AddSingleton<Views.MainPage>();
        builder.Services.AddTransient<Views.ChoreDetailsPage>();
        builder.Services.AddTransient<Views.TagsPage>();
        builder.Services.AddTransient<Views.AboutPage>();
        builder.Services.AddTransient<Views.SettingsPage>();
        builder.Services.AddTransient<Views.ArchivePage>();

#if DEBUG
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}
