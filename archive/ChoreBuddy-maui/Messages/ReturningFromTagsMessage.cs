using CommunityToolkit.Mvvm.Messaging.Messages;

namespace ChoreBuddy.Messages;

public class ReturningFromTagsMessage : ValueChangedMessage<bool>
{
    public ReturningFromTagsMessage() : base(true) { }
}