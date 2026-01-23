using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Views;

public partial class ThemePickerView : ContentView
{
	public ThemePickerView()
	{
		InitializeComponent();
	}

    private void OnThemeCollectionLoaded(object sender, EventArgs e)
    {
        if (sender is CollectionView collectionView && BindingContext is SettingsViewModel vm && vm.SelectedTheme != null)
        {
            Dispatcher.Dispatch(() =>
            {
                try
                {
                    collectionView.ScrollTo(vm.SelectedTheme, position: ScrollToPosition.Center, animate: false);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Initial theme scroll failed: {ex.Message}");
                }
            });
        }
    }
}