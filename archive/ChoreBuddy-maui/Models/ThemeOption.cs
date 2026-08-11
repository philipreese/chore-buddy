namespace ChoreBuddy.Models;

public record ThemeOption(
    string Name,
    Type ThemeType,
    Color PrimaryColorLight,
    Color SecondaryColorLight,
    Color TertiaryColorLight,
    Color PrimaryColorDark,
    Color SecondaryColorDark,
    Color TertiaryColorDark);
