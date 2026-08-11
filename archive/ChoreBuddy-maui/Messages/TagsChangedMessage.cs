using CommunityToolkit.Mvvm.Messaging.Messages;

namespace ChoreBuddy.Messages;

public class TagsChangedMessage : ValueChangedMessage<bool>
{
    public TagsChangedMessage() : base(true) { }
}