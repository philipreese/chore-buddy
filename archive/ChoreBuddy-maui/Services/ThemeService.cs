using ChoreBuddy.Messages;
using ChoreBuddy.Models;
using ChoreBuddy.Resources.Styles;
using ChoreBuddy.Resources.Styles.Themes;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.Services;

public class ThemeService
{
    private readonly SettingsService settingsService;

    public List<ThemeOption> AvailableThemes { get; }

    public ThemeService(SettingsService settingsService)
    {
        this.settingsService = settingsService;
        AvailableThemes = BuildThemesDynamically();
    }

    private static List<ThemeOption> BuildThemesDynamically()
    {
        var themes = new List<ThemeOption>();

        var registry = new (string DisplayName, Type ThemeType)[]
        {
            ("Chambray", typeof(ChambrayTheme)),
            ("Blue Stone", typeof(BlueStoneTheme)),
            ("St Tropaz", typeof(StTropazTheme)),
            ("Russet", typeof(RussetTheme)),
            ("Affair", typeof(AffairTheme)),
            ("Cannon Pink", typeof(CannonPinkTheme)),
            ("Waikawa Gray", typeof(WaikawaGrayTheme)),
            ("Spicy Mustard", typeof(SpicyMustardTheme)),
            ("Woodland", typeof(WoodlandTheme)),
            ("Potters Clay", typeof(PottersClayTheme))
        };

        foreach (var (name, type) in registry)
        {
            try
            {
                if (Activator.CreateInstance(type) is ResourceDictionary dict)
                {
                    themes.Add(new ThemeOption(
                        name,
                        type,
                        GetColor(dict, "PrimaryLight"),
                        GetColor(dict, "SecondaryLight"),
                        GetColor(dict, "TertiaryLight"),
                        GetColor(dict, "PrimaryDark"),
                        GetColor(dict, "SecondaryDark"),
                        GetColor(dict, "TertiaryDark")
                    ));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to load theme {name}: {ex.Message}");
            }
        }

        return themes;
    }

    private static Color GetColor(ResourceDictionary dict, string key)
    {
        return dict.TryGetValue(key, out var val) && val is Color color
            ? color
            : Colors.Transparent;
    }

    public void ApplyTheme(ResourceDictionary targetResources, string? themeName = null, bool isInitialLoad = false)
    {
        themeName ??= settingsService.SelectedThemeName;
        ThemeOption theme = AvailableThemes.FirstOrDefault(t => t.Name == themeName) ?? AvailableThemes[0];
        targetResources.MergedDictionaries.Clear();

        if (Activator.CreateInstance(theme.ThemeType) is ResourceDictionary newThemeDictionary)
        {
            targetResources.MergedDictionaries.Add(newThemeDictionary);
        }

        targetResources.MergedDictionaries.Add(new Styles());

        if (isInitialLoad)
        {
            settingsService.SetValueSilent("selected_theme_name", theme.Name);
        }
        else
        {
            settingsService.SelectedThemeName = theme.Name;
        }

        WeakReferenceMessenger.Default.Send(new ThemeChangedMessage());
    }
}
