using CommunityToolkit.Mvvm.ComponentModel;
using SQLite;

namespace ChoreBuddy.Models;

public enum RecurranceType
{
    None,
    Daily,
    Weekly,
    Monthly
}

public partial class Chore : ObservableObject
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }

    [NotNull, Unique]
    [ObservableProperty]
    public partial string Name { get; set; } = string.Empty;

    [ObservableProperty]
    public partial DateTime? LastCompleted { get; set; }

    [ObservableProperty]
    public partial bool IsActive { get; set; } = true;

    [ObservableProperty]
    public partial string LastNote { get; set; } = string.Empty;

    [ObservableProperty]
    public partial DateTime? NextDueDate { get; set; }

    [ObservableProperty]
    public partial RecurranceType RecurranceType { get; set; } = RecurranceType.None;

    [ObservableProperty]
    public partial bool IsNotificationEnabled { get; set; } = true;

    public Chore ToBaseChore() => new()
    {
        Id = Id,
        Name = Name,
        LastCompleted = LastCompleted,
        IsActive = IsActive,
        LastNote = LastNote,
        NextDueDate = NextDueDate,
        RecurranceType = RecurranceType,
        IsNotificationEnabled = IsNotificationEnabled
    };
}
