using CommunityToolkit.Mvvm.Messaging.Messages;

namespace ChoreBuddy.Messages;

public class ChoreActivatedMessage : ValueChangedMessage<bool>
{
    public ChoreActivatedMessage() : base(true) { }
}