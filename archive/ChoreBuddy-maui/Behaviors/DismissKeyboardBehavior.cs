using CommunityToolkit.Mvvm.Messaging;
using ChoreBuddy.Messages;

namespace ChoreBuddy.Behaviors;

public partial class DismissKeyboardBehavior : Behavior<Entry>, IRecipient<ChoreAddedMessage>
{
    private Entry? attachedEntry;

    protected override void OnAttachedTo(Entry bindable)
    {
        base.OnAttachedTo(bindable);
        attachedEntry = bindable;

        WeakReferenceMessenger.Default.Register(this);
    }

    protected override void OnDetachingFrom(Entry bindable)
    {
        WeakReferenceMessenger.Default.Unregister<ChoreAddedMessage>(this);
        attachedEntry = null;
        base.OnDetachingFrom(bindable);
    }

    public void Receive(ChoreAddedMessage message)
    {
        MainThread.BeginInvokeOnMainThread(async () =>
        {
            if (attachedEntry?.IsFocused ?? false)
            {
                await Task.Delay(10);

                attachedEntry.Unfocus();

                // Forceful Android Dismissal (Necessary for reliable keyboard hiding)
#if ANDROID
                if (attachedEntry.Handler?.PlatformView is Android.Views.View platformView)
                {
                    var context = platformView.Context;
                    var inputMethodManager = context?.GetSystemService(Android.Content.Context.InputMethodService)
                        as Android.Views.InputMethods.InputMethodManager;

                    inputMethodManager?.HideSoftInputFromWindow(
                        platformView.WindowToken,
                        Android.Views.InputMethods.HideSoftInputFlags.None);
                }
#endif
            }
        });
    }
}