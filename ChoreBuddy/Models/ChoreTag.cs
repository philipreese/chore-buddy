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
}

public class ChoreTag
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }
    [Indexed]
    public int ChoreId { get; set; }
    [Indexed]
    public int TagId { get; set; }
}
