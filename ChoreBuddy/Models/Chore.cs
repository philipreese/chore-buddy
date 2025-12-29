using SQLite;

namespace ChoreBuddy.Models;

public class Chore
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }

    [NotNull, Unique]
    public string Name { get; set; } = string.Empty;
    public DateTime? LastCompleted { get; set; }
    public bool IsActive { get; set; } = true;
    public string LastNote { get; set; } = string.Empty;
}
