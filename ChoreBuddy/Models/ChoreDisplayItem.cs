
namespace ChoreBuddy.Models;

public partial class ChoreDisplayItem : Chore
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
            Tags = tags ?? [],
            NextDueDate = chore.NextDueDate,
            RecurranceType = chore.RecurranceType,
            IsNotificationEnabled = chore.IsNotificationEnabled
        };
    }

    public override bool Equals(object? obj)
    {
        if (obj == null)
        {
            return false;
        }

        if (obj is not ChoreDisplayItem item)
        {
            return false;
        }

        if (Id != item.Id ||
            Name != item.Name ||
            LastCompleted != item.LastCompleted ||
            IsActive != item.IsActive ||
            LastNote != item.LastNote ||
            NextDueDate != item.NextDueDate ||
            RecurranceType != item.RecurranceType ||
            IsNotificationEnabled != item.IsNotificationEnabled)
        {
            return false;
        }

        if (Tags.Count != item.Tags.Count)
        {
            return false;
        }

        foreach (var tag in Tags)
        {
            if (!item.Tags.Contains(tag))
            {
                return false;
            }
        }

        return true;
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(Id, Name, LastCompleted, IsActive, LastNote, Tags, NextDueDate, RecurranceType);
    }
}