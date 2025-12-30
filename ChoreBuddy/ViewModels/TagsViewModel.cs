using System.Collections.ObjectModel;
using ChoreBuddy.Messages;
using ChoreBuddy.Models;
using ChoreBuddy.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.ViewModels;

public partial class TagsViewModel : ObservableObject
{
    private readonly ChoreDatabaseService databaseService;
    public ObservableCollection<Tag> Tags { get; } = [];

    [ObservableProperty]
    public partial string NewTagName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string SelectedColor { get; set; } = "#EF4444";

    public List<string> AvailableColors { get; } =
    [
        "#EF4444", "#F59E0B", "#FB923C", // Warm Tones
        "#A78BFA", "#7C3AED", "#F472B6",  // Purples & Pinks
        "#10B981", "#A3E635", "#99F6E4", // Greens
        "#7CC5F2", "#007ACC", "#4CC6D1" // Blues & Cyans
    ];

    public TagsViewModel(ChoreDatabaseService databaseService)
    {
        this.databaseService = databaseService;
        LoadTagsCommand.Execute(null);
    }

    [RelayCommand]
    async Task LoadTags()
    {
        var tags = await databaseService.GetTagsAsync();
        Tags.Clear();
        foreach (var tag in tags) Tags.Add(tag);
    }

    [RelayCommand(CanExecute = nameof(CanAddTag))]
    async Task AddTag()
    {
        if (string.IsNullOrWhiteSpace(NewTagName)) return;

        var tag = new Tag { Name = NewTagName, ColorHex = SelectedColor };
        int result = await databaseService.SaveTagAsync(tag);

        if (result == -1)
        {
            await Shell.Current.DisplayAlert("Error", "Tag already exists", "OK");
            return;
        }

        NewTagName = string.Empty;
        await LoadTags();
        WeakReferenceMessenger.Default.Send(new TagsChangedMessage());
    }

    private bool CanAddTag() => !string.IsNullOrEmpty(NewTagName);

    [RelayCommand]
    async Task DeleteTag(Tag tag)
    {
        bool confirm = await Application.Current!.Windows[0].Page!.DisplayAlert(
            "Delete Tag",
            $"Are you sure you want to delete '{tag.Name}'? This action cannot be undone",
            "Yes, Delete",
            "Cancel"
        );

        if (confirm)
        {
            await databaseService.DeleteTagAsync(tag);
            Tags.Remove(tag);
            WeakReferenceMessenger.Default.Send(new TagsChangedMessage());
        }
    }

    [RelayCommand]
    async Task SetColor(string hexColor)
    {
        SelectedColor = hexColor;
    }

    partial void OnNewTagNameChanged(string value)
    {
        AddTagCommand.NotifyCanExecuteChanged();
    }
}
