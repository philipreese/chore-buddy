using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Views;

public partial class MainPage : ContentPage
{
    public MainViewModel? ViewModel => BindingContext as MainViewModel;

    public MainPage(MainViewModel vm)
    {
        InitializeComponent();
        BindingContext = vm;
    }
}
