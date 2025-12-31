using ChoreBuddy.ViewModels;

namespace ChoreBuddy.Views;

public partial class TagsPage : ContentPage
{
    public TagsViewModel? ViewModel => BindingContext as TagsViewModel;

    public TagsPage(TagsViewModel vm)
	{
		InitializeComponent();
        BindingContext = vm;
    }
}