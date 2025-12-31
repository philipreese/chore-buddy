using System.Collections.ObjectModel;
using ChoreBuddy.Messages;
using ChoreBuddy.Models;
using ChoreBuddy.Services;
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.ViewModels;

public enum ChoreSortOrder
{
    Name,
    LastCompleted
}

public enum SortDirection
{
    Ascending,
    Descending
}

public partial class MainViewModel :
    ObservableObject,
    IRecipient<ChoreAddedMessage>,
    IRecipient<ChoresDataChangedMessage>,
    IRecipient<TagsChangedMessage>
{
    private readonly ChoreDatabaseService databaseService = null!;
    public ObservableCollection<ChoreDisplayItem> Chores { get; } = [];
    private List<Chore> AllChores { get; set; } = [];

    public ObservableCollection<Tag> FilterTags { get; } = [];

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsFilterActive))]
    public partial bool HasActiveFilter { get; set; }

    public bool IsFilterActive => FilterTags.Any(t => t.IsSelected);

    public string EmptyListMessage => AllChores.Count > 0 ? "All chores filtered out!" : "No chores added yet!";

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(NameSortIconGlyph), nameof(DateSortIconGlyph))]
    public partial ChoreSortOrder CurrentSortOrder { get; set; } = ChoreSortOrder.LastCompleted;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(NameSortIconGlyph), nameof(DateSortIconGlyph))]
    public partial SortDirection CurrentDirection { get; set; } = SortDirection.Descending;

    public string NameSortIconGlyph
    {
        get
        {
            if (CurrentSortOrder == ChoreSortOrder.Name)
            {
                return CurrentDirection == SortDirection.Ascending ? "\uf15d" : "\uf15e";
            }

            return "\uf15d";
        }
    }

    public string DateSortIconGlyph => "\uf073";

    public MainViewModel() { }

    public MainViewModel(ChoreDatabaseService databaseService)
    {
        this.databaseService = databaseService;

        _ = LoadData();
        WeakReferenceMessenger.Default.Register<ChoreAddedMessage>(this);
        WeakReferenceMessenger.Default.Register<ChoresDataChangedMessage>(this);
        WeakReferenceMessenger.Default.Register<TagsChangedMessage>(this);
    }

    private async Task LoadData()
    {
        await LoadFilterTags();
        await LoadChores();
    }

    async Task LoadFilterTags()
    {
        var tags = await databaseService.GetTagsAsync();
        FilterTags.Clear();
        foreach (var tag in tags)
        {
            FilterTags.Add(tag);
        }
    }

    [RelayCommand]
    private async Task LoadChores()
    {
        var chores = await databaseService.GetActiveChoresAsync();
        var selectedTagIds = FilterTags.Where(t => t.IsSelected).Select(t => t.Id).ToList();

        IEnumerable<Chore> sortedChores = CurrentSortOrder switch
        {
            ChoreSortOrder.Name => (CurrentDirection == SortDirection.Ascending)
                                    ? chores.OrderBy(c => c.Name)
                                    : chores.OrderByDescending(c => c.Name),
            ChoreSortOrder.LastCompleted => (CurrentDirection == SortDirection.Ascending)
                                             ? chores.OrderBy(c => c.LastCompleted.HasValue)
                                                     .ThenBy(c => c.LastCompleted)
                                             : chores.OrderByDescending(c => c.LastCompleted.HasValue)
                                                     .ThenByDescending(c => c.LastCompleted),
            _ => chores
        };

        AllChores = [.. sortedChores];
        Chores.Clear();
        foreach (var chore in sortedChores)
        {
            var tags = await databaseService.GetTagsForChoreAsync(chore.Id);
            if (selectedTagIds.Count != 0)
            {
                if (!selectedTagIds.Any(id => tags.Any(t => t.Id == id)))
                {
                    continue;
                }
            }
            
            Chores.Add(ChoreDisplayItem.FromChore(chore, tags));
        }

        DeleteAllChoresCommand.NotifyCanExecuteChanged();
        HasActiveFilter = selectedTagIds.Count != 0;
        OnPropertyChanged(nameof(EmptyListMessage));
    }

    [RelayCommand]
    private async Task AddChore()
    {
        await GoToDetails(null);
        WeakReferenceMessenger.Default.Send(new ChoreAddedMessage());
    }

    [RelayCommand]
    private async Task CompleteChore(ChoreDisplayItem chore)
    {
        if (chore == null)
        {
            return;
        }

        string note = await Shell.Current.DisplayPromptAsync(
            "Add Note (Optional)",
            $"Enter a note for completing '{chore.Name}'.",
            "Save",
            initialValue: string.Empty);

        if (note is null)
        {
            return;
        }

        int recordId = await databaseService.CompleteChoreAsync(chore.Id, note);

        await LoadData();

        await Snackbar.Make(
            "Chore completed",
            action: async () =>
            {
                await databaseService.DeleteCompletionRecordAsync(recordId);
                await LoadData();
            },
            actionButtonText: "UNDO",
            duration: TimeSpan.FromSeconds(5))
        .Show();

        OnPropertyChanged(nameof(Chores));
    }

    [RelayCommand]
    private async Task DeleteChore(ChoreDisplayItem chore)
    {
        if (chore == null)
        {
            return;
        }

        bool confirm = await Application.Current!.Windows[0].Page!.DisplayAlert(
            "Delete Chore",
            $"Are you sure you want to delete '{chore.Name}'? This action cannot be undone",
            "Yes, Delete",
            "Cancel"
        );

        if (confirm)
        {
            await databaseService.DeleteChoreAsync(chore);
            await LoadData();
        }
    }

    [RelayCommand(CanExecute = nameof(CanDeleteAllChores))]
    private async Task DeleteAllChores()
    {
        bool confirm = await Application.Current!.Windows[0].Page!.DisplayAlert(
            "DANGER: Delete All Chores",
            $"Are you absolutely sure you want to delete ALL chores and ALL history? This action cannot be undone",
            "Yes, Delete Everything",
            "Cancel"
        );

        if (confirm)
        {
            await databaseService.DeleteAllChoresAsync();
            await LoadData();
        }
    }

    private bool CanDeleteAllChores()
    {
        return Chores.Count > 0;
    }

    [RelayCommand]
    async Task ToggleFilterTag(Tag tag)
    {
        if (tag == null) return;
        tag.IsSelected = !tag.IsSelected;
        await LoadChores();
        OnPropertyChanged(nameof(IsFilterActive));
    }

    [RelayCommand]
    async Task ClearFilters()
    {
        foreach (var tag in FilterTags) tag.IsSelected = false;
        await LoadChores();
        OnPropertyChanged(nameof(IsFilterActive));
    }

    [RelayCommand]
    private static async Task GoToDetails(ChoreDisplayItem? item)
    {
        int id = item?.Id ?? 0;
        await Shell.Current.GoToAsync($"ChoreDetailsPage?ChoreId={id}");
    }

    [RelayCommand]
    static async Task NavigateToTags() => await Shell.Current.GoToAsync("TagsPage");

    [RelayCommand]
    private async Task SortChores(ChoreSortOrder newOrder)
    {
        if (CurrentSortOrder == newOrder)
        {
            CurrentDirection = (CurrentDirection == SortDirection.Ascending)
                             ? SortDirection.Descending
                             : SortDirection.Ascending;
        }
        else
        {
            CurrentSortOrder = newOrder;
            CurrentDirection = SortDirection.Descending;
        }

        await LoadData();
    }

    public async void Receive(ChoreAddedMessage message) => await LoadData();
    public async void Receive(ChoresDataChangedMessage message) => await LoadData();
    public async void Receive(TagsChangedMessage message) => await LoadData();
}