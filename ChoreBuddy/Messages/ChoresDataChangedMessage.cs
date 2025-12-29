using CommunityToolkit.Mvvm.Messaging.Messages;

namespace ChoreBuddy.Messages;

public class ChoresDataChangedMessage : ValueChangedMessage<bool>
{
    public ChoresDataChangedMessage() : base(true) { }
}