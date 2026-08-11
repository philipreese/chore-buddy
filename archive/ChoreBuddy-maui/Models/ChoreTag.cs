using CommunityToolkit.Mvvm.ComponentModel;
using SQLite;

namespace ChoreBuddy.Models;

public partial class Tag : ObservableObject
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }
    public string Name
    {
        get => field ?? string.Empty;
        set => SetProperty(ref field, value.ToLower().Trim());
    }

    public string ColorHex { get; set; } = "#007ACC";

    [ObservableProperty]
    [Ignore]
    public partial bool IsSelected { get; set; }

    public override bool Equals(object? obj)
    {
        return obj is Tag tag &&
               Id == tag.Id &&
               Name == tag.Name &&
               ColorHex == tag.ColorHex &&
               IsSelected == tag.IsSelected;
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(Id, Name, ColorHex, IsSelected);
    }
}

public class ChoreTag
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }
    [Indexed(Name ="IX_ChoreTag_Composite", Order = 1, Unique = true)]
    public int ChoreId { get; set; }
    [Indexed(Name = "IX_ChoreTag_Composite", Order = 2, Unique = true)]
    public int TagId { get; set; }
}
