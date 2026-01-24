using System.ComponentModel;

namespace ChoreBuddy.Behaviors;

public partial class FocusBehavior : Behavior<View>
{
    protected override void OnAttachedTo(View bindable)
    {
        base.OnAttachedTo(bindable);
        bindable.Loaded += OnControlLoaded;
        bindable.PropertyChanged += OnPropertyChanged;
    }

    protected override void OnDetachingFrom(View bindable)
    {
        base.OnDetachingFrom(bindable);
        bindable.Loaded -= OnControlLoaded;
        bindable.PropertyChanged -= OnPropertyChanged;
    }

    private void OnControlLoaded(object? sender, EventArgs e)
    {
        if (sender is View view && view.IsVisible)
        {
            RequestFocus(view);
        }
    }

    private void OnPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == VisualElement.IsVisibleProperty.PropertyName &&
            sender is View view && view.IsVisible)
        {
            RequestFocus(view);
        }
    }

    private void RequestFocus(View view)
    {
        view.Dispatcher.DispatchDelayed(TimeSpan.FromMilliseconds(150), () =>
        {
            try
            {
                if (view.IsVisible)
                {
                    view.Focus();
                }
            }
            catch
            {
            }
        });
    }
}
