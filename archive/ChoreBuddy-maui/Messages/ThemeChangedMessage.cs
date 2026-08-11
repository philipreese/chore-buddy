using CommunityToolkit.Mvvm.Messaging.Messages;

namespace ChoreBuddy.Messages;

public class ThemeChangedMessage : ValueChangedMessage<bool>
{
    public ThemeChangedMessage() : base(true)
    { }
}
