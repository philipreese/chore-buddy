using System.Collections.ObjectModel;
using ChoreBuddy.Messages;
using ChoreBuddy.Models;
using ChoreBuddy.Services;
using ChoreBuddy.Utilities;
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;
using Plugin.LocalNotification;

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
    IRecipient<TagsChangedMessage>,
    IRecipient<ChoreActivatedMessage>
{
    private readonly ChoreDatabaseService databaseService = null!;
    private readonly SettingsService? settingsService;
    private readonly NotificationService? notificationService;
    public ObservableCollection<ChoreDisplayItem> Chores { get; } = [];
    private List<Chore> AllChores { get; set; } = [];
    public ObservableCollection<Tag> FilterTags { get; } = [];

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsFilterActive))]
    public partial bool HasActiveFilter { get; set; }
    public bool IsFilterActive => FilterTags.Any(t => t.IsSelected);

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsTotalEmpty))]
    [NotifyPropertyChangedFor(nameof(IsFilterEmpty))]
    public partial bool IsBusy { get; set; }
    public bool IsTotalEmpty => !IsBusy && (AllChores == null || !(AllChores.Count > 0));
    public bool IsFilterEmpty => !IsBusy && !IsTotalEmpty && (Chores == null || !Chores.Any());

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(NameSortIconGlyph), nameof(DateSortIconGlyph))]
    public partial ChoreSortOrder CurrentSortOrder { get; set; } = ChoreSortOrder.LastCompleted;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(NameSortIconGlyph), nameof(DateSortIconGlyph))]
    public partial SortDirection CurrentDirection { get; set; } = SortDirection.Descending;

    private string nameSortIconGlyph = "\uf15d";
    public string NameSortIconGlyph
    {
        get
        {
            if (CurrentSortOrder == ChoreSortOrder.Name)
            {
                nameSortIconGlyph = CurrentDirection == SortDirection.Ascending ? "\uf15d" : "\uf15e";
                return nameSortIconGlyph;
            }

            return nameSortIconGlyph;
        }
    }

    private string dateSortIconGlyph = "\uf162";
    public string DateSortIconGlyph
    {
        get
        {
            if (CurrentSortOrder == ChoreSortOrder.LastCompleted)
            {
                dateSortIconGlyph = CurrentDirection == SortDirection.Ascending ? "\uf162" : "\uf163";
                return dateSortIconGlyph;
            }

            return dateSortIconGlyph;
        }
    }

    public MainViewModel() { }

    public MainViewModel(
        ChoreDatabaseService databaseService,
        SettingsService settingsService,
        NotificationService notificationService)
    {
        this.databaseService = databaseService;
        this.settingsService = settingsService;
        this.notificationService = notificationService;

        WeakReferenceMessenger.Default.Register<ChoreAddedMessage>(this);
        WeakReferenceMessenger.Default.Register<ChoresDataChangedMessage>(this);
        WeakReferenceMessenger.Default.Register<TagsChangedMessage>(this);
        WeakReferenceMessenger.Default.Register<ChoreActivatedMessage>(this);
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
                                     .ThenBy(c => c.LastCompleted)
                                     .ThenBy(c => c.Name)
                             : filteredItems.OrderByDescending(c => c.LastCompleted.HasValue)
                                     .ThenByDescending(c => c.LastCompleted)
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
            OnPropertyChanged(nameof(IsTotalEmpty));
            OnPropertyChanged(nameof(IsFilterEmpty));
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
            $"Enter a note for completing '{chore.Name.TrimEnd().Truncate()}'.",
            "Save",
            initialValue: string.Empty);

        if (note is null)
        {
            return;
        }

        switch (chore.RecurranceType)
        {
            case RecurranceType.Daily:
                chore.NextDueDate = (chore.NextDueDate ?? DateTime.Now).AddDays(1);
                break;
            case RecurranceType.Weekly:
                chore.NextDueDate = (chore.NextDueDate ?? DateTime.Now).AddDays(7);
                break;
            case RecurranceType.Monthly:
                chore.NextDueDate = (chore.NextDueDate ?? DateTime.Now).AddMonths(1);
                break;
            case RecurranceType.None:
                chore.NextDueDate = null;
                break;
        }

        int recordId = await databaseService.CompleteChoreAsync(chore.ToBaseChore(), note);

        await Snackbar.Make(
            "Chore completed",
            action: async () =>
            {
                await databaseService.DeleteCompletionRecordAsync(recordId);

                settingsService?.ProvideHapticFeedback(175);

                await LoadData();
                WeakReferenceMessenger.Default.Send(new UndoCompleteChoreMessage());
            },
            actionButtonText: "UNDO",
            duration: TimeSpan.FromSeconds(5))
        .Show();

        settingsService?.ProvideHapticFeedback(175);
        notificationService?.ScheduleChoreNotification(chore);

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
            "Scrap Mission",
            $"Are you sure you want to permanently decommission '{chore.Name.TrimEnd().Truncate()}' " +
            $"and scrub all historical intel from the registry? This action cannot be undone",
            "Scrap",
            "Keep Active"
        );

        if (confirm)
        {
            await databaseService.DeleteChoreAsync(chore);
            await Snackbar.Make("Chore deleted", duration: TimeSpan.FromMilliseconds(350)).Show();
            await LoadData();
        }
    }

    [RelayCommand(CanExecute = nameof(CanDeleteAllChores))]
    private async Task DeleteAllChores()
    {
        bool confirm = await Application.Current!.Windows[0].Page!.DisplayAlert(
            "DANGER: Delete All Chores",
            $"This will permanently purge all decommissioned missions. Erase these records from the archives?",
            "Purge All",
            "Cancel"
        );

        if (confirm)
        {
            await databaseService.DeleteAllChoresAsync();
            await Snackbar.Make("All chores deleted", duration: TimeSpan.FromMilliseconds(350)).Show();
            await LoadData();
        }
    }

    private bool CanDeleteAllChores()
    {
        return Chores.Count > 0;
    }

    [RelayCommand]
    async Task ToggleTag(Tag tag)
    {
        if (tag == null) return;
        tag.IsSelected = !tag.IsSelected;
        await LoadChores();
    }

    [RelayCommand]
    private static async Task GoToDetails(ChoreDisplayItem? item)
    {
        int id = item?.Id ?? 0;
        await Shell.Current.GoToAsync($"ChoreDetailsPage?ChoreId={id}");
    }

    [RelayCommand]
    private async Task ArchiveChore(ChoreDisplayItem item)
    {
        if (item == null)
        {
            return;
        }

        bool confirm = await Application.Current!.Windows[0].Page!.DisplayAlert(
            "Decommission Mission",
            $"Transfer '{item.Name.TrimEnd().Truncate()}' to the Hall of Rest? it will be removed from active signals.",
            "Decommission",
            "Abort"
        );

        if (confirm)
        {
            item.IsActive = false;
            Chore chore = item.ToBaseChore();
            await databaseService.SaveChoreAsync(chore);
            await Snackbar.Make("Chore archived", duration: TimeSpan.FromMilliseconds(350)).Show();
            await LoadData();
        }
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
    public async void Receive(ChoreActivatedMessage message) => await LoadData();
}