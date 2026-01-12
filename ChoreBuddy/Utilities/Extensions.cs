namespace ChoreBuddy.Utilities;

public static class Extensions
{
    public static string Truncate(this string value, int maxChars = 30)
    {
        return (value.Length <= maxChars ? value : value[..maxChars] + "...").TrimEnd();
    }
}
