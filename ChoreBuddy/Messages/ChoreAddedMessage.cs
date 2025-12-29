using CommunityToolkit.Mvvm.Messaging.Messages;

namespace ChoreBuddy.Messages;

public class ChoreAddedMessage : ValueChangedMessage<bool>
{
    public ChoreAddedMessage() : base(true) { }
}