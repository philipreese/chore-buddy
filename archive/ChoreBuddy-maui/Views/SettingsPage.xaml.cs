using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Views;

public partial class SettingsPage : ContentPage
{
    public SettingsViewModel? ViewModel => BindingContext as SettingsViewModel;
    public SettingsPage(SettingsViewModel vm)
	{
		InitializeComponent();
		BindingContext = vm;
	}

    protected override void OnAppearing()
    {
        base.OnAppearing();
        ViewModel?.LoadSettings();
    }
}