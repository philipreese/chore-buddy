using System.ComponentModel.DataAnnotations;
using System.Reflection;

namespace ChoreBuddy.Utilities;

public static class Extensions
{
    public static string Truncate(this string value, int maxChars = 30)
    {
        return (value.Length <= maxChars ? value : value[..maxChars] + "...").TrimEnd();
    }

    public static string GetEnumDisplayName(this Enum enumValue)
    {
        return enumValue.GetType()
            .GetMember(enumValue.ToString())
            .First()
            .GetCustomAttribute<DisplayAttribute>()?
            .Name ?? enumValue.ToString();
    }

    public static T GetEnumFromDisplayName<T>(string displayName) where T: Enum
    {
        foreach (var value in Enum.GetValues(typeof(T)))
        {
            if (((T)value).GetEnumDisplayName() == displayName)
            {
                return (T)value;
            }
        }

        return default!;
    }
}
