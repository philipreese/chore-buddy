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

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(HasTags))]
    [NotifyPropertyChangedFor(nameof(IsEmpty))]
    public partial ObservableCollection<Tag> Tags { get; set; } = [];

    public bool HasTags => !IsBusy && Tags.Count > 0;
    public bool IsEmpty => !IsBusy && Tags.Count == 0;

    [ObservableProperty]
    public partial string NewTagName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string SelectedColor { get; set; } = "#EF4444";

    [ObservableProperty]
    public partial bool IsBusy { get; set; } = true;

    public List<string> AvailableColors { get; } =
    [
        "#EF4444", "#F59E0B", "#FB923C", // Warm Tones
        "#7C3AED", "#F472B6", "#D375C8",  // Purples & Pinks
        "#10B981", "#047857", "#064E3B", // Greens
        "#007ACC", "#0891B2", "#003D66" // Blues & Cyans
    ];

    public TagsViewModel(ChoreDatabaseService databaseService)
    {
        this.databaseService = databaseService;
        SelectedColor = AvailableColors[0];
    }

    [RelayCommand]
    public async Task LoadTags()
    {
        try
        {
            IsBusy = true;
            var tags = await Task.Run(databaseService.GetTagsAsync);
            MainThread.BeginInvokeOnMainThread(() =>
            {
                var newCollection = new ObservableCollection<Tag>(tags);
                newCollection.CollectionChanged += (s, e) =>
                {
                    OnPropertyChanged(nameof(HasTags));
                    OnPropertyChanged(nameof(IsEmpty));
                };

                Tags = newCollection;
                DeleteAllTagsCommand.NotifyCanExecuteChanged();
            });
        }
        finally
        {
            IsBusy = false;
            OnPropertyChanged(nameof(IsEmpty));
            OnPropertyChanged(nameof(HasTags));
        }
    }

    [RelayCommand(CanExecute = nameof(CanAddTag))]
    async Task AddTag()
    {
        if (string.IsNullOrWhiteSpace(NewTagName))
        {
            return;
        }

        if (NewTagName.Length > 22)
        {
            await Shell.Current.DisplayAlert(
                "Signal Overload",
                "This designation is too extensive for the mission registry. Please provide a shorter tag name for optimal field identification.",
                "Acknowledged");
            return;
        }

        var tag = new Tag { Name = NewTagName, ColorHex = SelectedColor };
        int result = await databaseService.SaveTagAsync(tag);

        if (result == -1)
        {
            await Shell.Current.DisplayAlert("Tag Conflict", "A tag with this designation already exists in the armory.", "Acknowledged");
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
            "Scrub Designation",
            $"Removing '{tag.Name}' will detach it from all associated missions.Proceed with the scrub ? ",
            "Scrub",
            "Keep"
        );

        if (confirm)
        {
            await databaseService.DeleteTagAsync(tag);
            Tags.Remove(tag);
            WeakReferenceMessenger.Default.Send(new TagsChangedMessage());
            DeleteAllTagsCommand.NotifyCanExecuteChanged();
        }
    }

    [RelayCommand(CanExecute = nameof(CanDeleteAllTags))]
    async Task DeleteAllTags()
    {
        bool confirm = await Application.Current!.Windows[0].Page!.DisplayAlert(
            "DANGER: Delete All Tags",
            $"Are you absolutely sure you want to delete ALL tags? This action cannot be undone",
            "Yes, Delete Everything",
            "Cancel"
        );

        if (confirm)
        {
            await databaseService.DeleteTagsAsync();
            Tags.Clear();
            WeakReferenceMessenger.Default.Send(new TagsChangedMessage());
        }
    }

    private bool CanDeleteAllTags() => Tags.Count > 0;

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
