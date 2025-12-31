namespace ChoreBuddy.Models;

public class ChoreDisplayItem : Chore
{
    public List<Tag> Tags { get; set; } = [];

    public static ChoreDisplayItem FromChore(Chore chore, List<Tag> tags)
    {
        return new ChoreDisplayItem
        {
            Id = chore.Id,
            Name = chore.Name,
            LastCompleted = chore.LastCompleted,
            LastNote = chore.LastNote,
            Tags = tags ?? []
        };
    }
}