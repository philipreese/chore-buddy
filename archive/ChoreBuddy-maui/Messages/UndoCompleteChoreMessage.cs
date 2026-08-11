using CommunityToolkit.Mvvm.Messaging.Messages;

namespace ChoreBuddy.Messages;

public class UndoCompleteChoreMessage : ValueChangedMessage<bool>
{
    public UndoCompleteChoreMessage() : base(true) { }
}