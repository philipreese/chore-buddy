using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Views;

public partial class ArchivePage : ContentPage
{
    public ArchiveViewModel? ViewModel => BindingContext as ArchiveViewModel;
    public ArchivePage(ArchiveViewModel vm)
	{
		InitializeComponent();
        BindingContext = vm;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();

        if (ViewModel != null)
        {
            MainThread.BeginInvokeOnMainThread(async () => await ViewModel.LoadDataAsync());
        }
    }
}