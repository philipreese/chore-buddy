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
    private readonly SettingsService? settingsService;
    public ObservableCollection<ChoreDisplayItem> Chores { get; } = [];
    private List<Chore> AllChores { get; set; } = [];
    public ObservableCollection<Tag> FilterTags { get; } = [];

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsFilterActive))]
    public partial bool HasActiveFilter { get; set; }
    public bool IsFilterActive => FilterTags.Any(t => t.IsSelected);

    [ObservableProperty]
    public partial bool IsBusy { get; set; }

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

#pragma warning disable CA1822 // Mark members as static
    public string DateSortIconGlyph => "\uf073";
#pragma warning restore CA1822 // Mark members as static

    public MainViewModel() { }

    public MainViewModel(ChoreDatabaseService databaseService, SettingsService settingsService)
    {
        this.databaseService = databaseService;
        this.settingsService = settingsService;

        WeakReferenceMessenger.Default.Register<ChoreAddedMessage>(this);
        WeakReferenceMessenger.Default.Register<ChoresDataChangedMessage>(this);
        WeakReferenceMessenger.Default.Register<TagsChangedMessage>(this);
        Task.Run(LoadData);
    }

    private async Task LoadData()
    {
        await LoadFilterTags();
        await LoadChores();
    }

    async Task LoadFilterTags()
    {
        var tags = await databaseService.GetTagsAsync();
        var selectedIds = FilterTags.Where(t => t.IsSelected).Select(t => t.Id).ToHashSet();

        FilterTags.Clear();
        foreach (var tag in tags)
        {
            tag.IsSelected = selectedIds.Contains(tag.Id);
            FilterTags.Add(tag);
        }
    }

    [RelayCommand]
    private async Task LoadChores()
    {
        if (IsBusy)
        {
            return;
        }

        IsBusy = true;

        try
        {
            var chores = await databaseService.GetActiveChoresAsync();
            var mappings = await databaseService.GetAllChoreTagMappingsAsync();

            var activeFilterIds = FilterTags.Where(t => t.IsSelected).Select(t => t.Id).ToList();

            var tagLookup = mappings
                .GroupBy(m => m.ChoreId)
                .ToDictionary(g => g.Key, g => g.Select(m => new Tag { Id = m.TagId, Name = m.Name, ColorHex = m.ColorHex }).ToList());

            var filteredItems = chores
                .Select(c => ChoreDisplayItem.FromChore(c, tagLookup.TryGetValue(c.Id, out var tags) ? tags : []))
                .Where(item => activeFilterIds.Count == 0 || activeFilterIds.Any(fid => item.Tags.Any(t => t.Id == fid)));

            var sortedItems = CurrentSortOrder switch
            {
                ChoreSortOrder.Name => CurrentDirection == SortDirection.Ascending
                    ? filteredItems.OrderBy(i => i.Name)
                    : filteredItems.OrderByDescending(i => i.Name),
                ChoreSortOrder.LastCompleted => (CurrentDirection == SortDirection.Ascending)
                             ? filteredItems.OrderBy(c => c.LastCompleted.HasValue)
                                     .ThenByDescending(c => c.Name)
                             : filteredItems.OrderByDescending(c => c.LastCompleted.HasValue)
                                     .ThenBy(c => c.Name),
                _ => filteredItems
            };

            var newList = sortedItems.ToList();

            MainThread.BeginInvokeOnMainThread(() =>
            {
                AllChores = chores;

                // Remove items no longer in the list
                for (int i = Chores.Count - 1; i >= 0; i--)
                {
                    if (newList.All(n => n.Id != Chores[i].Id))
                    {
                        Chores.RemoveAt(i);
                    }
                }

                // Add or move items
                for (int i = 0; i < newList.Count; i++)
                {
                    var newItem = newList[i];
                    var existingItemIndex = -1;

                    // Find if it exists
                    for (int j = 0; j < Chores.Count; j++)
                    {
                        if (Chores[j].Id == newItem.Id)
                        {
                            existingItemIndex = j;
                            break;
                        }
                    }

                    if (existingItemIndex == -1)
                    {
                        // Insert new item at correct position
                        Chores.Insert(i, newItem);
                    }
                    else if (existingItemIndex != i)
                    {
                        // Move existing item to correct sort position
                        Chores.Move(existingItemIndex, i);
                    }

                    // Check to see if the item needs updating
                    if (!Chores[i].Equals(newItem))
                    {
                        Chores[i] = newItem;
                    }
                }

                OnPropertyChanged(nameof(Chores));
                OnPropertyChanged(nameof(IsFilterActive));
                DeleteAllChoresCommand.NotifyCanExecuteChanged();
            });
        }
        finally
        {
            IsBusy = false;
            OnPropertyChanged(nameof(EmptyListMessage));
        }
    }

    [RelayCommand]
    private static async Task AddChore()
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

        await Snackbar.Make(
            "Chore completed",
            action: async () =>
            {
                await databaseService.DeleteCompletionRecordAsync(recordId);

                settingsService?.ProvideHapticFeedback();

                await LoadData();
                WeakReferenceMessenger.Default.Send(new UndoCompleteChoreMessage());
            },
            actionButtonText: "UNDO",
            duration: TimeSpan.FromSeconds(5))
        .Show();

        settingsService?.ProvideHapticFeedback();

        await LoadData();
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
    static async Task NavigateToAbout() => await Shell.Current.GoToAsync("AboutPage");

    [RelayCommand]
    static async Task NavigateToSettings() => await Shell.Current.GoToAsync("SettingsPage");

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