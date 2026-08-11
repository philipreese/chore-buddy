using CommunityToolkit.Mvvm.Messaging.Messages;

namespace ChoreBuddy.Messages;

public class NotificationTappedMessage : ValueChangedMessage<int>
{
    public NotificationTappedMessage(int choreId) : base(choreId) { }
}
