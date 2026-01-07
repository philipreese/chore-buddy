using System.ComponentModel;
using System.Runtime.CompilerServices;
using SQLite;

namespace ChoreBuddy.Models;

public partial class Chore
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }

    [NotNull, Unique]
    public string Name { get; set; } = string.Empty;
    public DateTime? LastCompleted { get; set; }
    public bool IsActive { get; set; } = true;
    public string LastNote { get; set; } = string.Empty;


    public Chore ToBaseChore() => new()
    {
        Id = Id,
        Name = Name,
        LastCompleted = LastCompleted,
        IsActive = IsActive,
        LastNote = LastNote
    };
}
