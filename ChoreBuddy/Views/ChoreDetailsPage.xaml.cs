using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Views;

public partial class ChoreDetailsPage : ContentPage
{
	public ChoreDetailViewModel? ViewModel => BindingContext as ChoreDetailViewModel;

    public ChoreDetailsPage(ChoreDetailViewModel vm)
	{
		InitializeComponent();
		BindingContext = vm;
	}
}