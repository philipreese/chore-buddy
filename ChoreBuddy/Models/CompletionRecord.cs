using SQLite;

namespace ChoreBuddy.Models;

public class CompletionRecord
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }

    [Indexed]
    public int ChoreId { get; set; }

    [NotNull]
    public DateTime CompletedAt { get; set; } = DateTime.Now;
    public string Note { get; set; } = string.Empty;
}
