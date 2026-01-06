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
            MainThread.BeginInvokeOnMainThread(async () => await LoadDataDeferred());
        }
    }

    private async Task LoadDataDeferred()
    {
        await Task.Delay(350);

        if (ViewModel != null)
        {
            await ViewModel.LoadData();
        }
    }
}