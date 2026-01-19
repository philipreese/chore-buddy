using System.Collections.ObjectModel;
using ChoreBuddy.Messages;
using ChoreBuddy.Models;
using ChoreBuddy.Services;
using ChoreBuddy.Utilities;
using ChoreBuddy.Views;
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Maui.Extensions;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.ViewModels;

public enum ChoreSortOrder
{
    Name,
    LastCompleted,
    DueDate
}

public enum SortDirection
{
    Ascending,
    Descending
}

public partial class MainViewModel :
    ObservableObject,
    ITagManager,
    IRecipient<ChoreAddedMessage>,
    IRecipient<ChoresDataChangedMessage>,
    IRecipient<TagsChangedMessage>,
    IRecipient<ChoreActivatedMessage>,
    IRecipient<NotificationTappedMessage>
{
    private readonly ChoreDatabaseService databaseService = null!;
    private readonly SettingsService? settingsService;
    private readonly NotificationService? notificationService;
    private readonly IDispatcherTimer? refreshTimer;
    private int lastProcessedMinute = -1;
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
    public partial bool IsHistoryVisible { get; set; } = false;

    public event EventHandler<ChoreDisplayItem>? RequestScrollToItem;
    private int pendingScrollChoreId = -1;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(NameSortIconGlyph), nameof(NameSortIconGlyph))]
    [NotifyPropertyChangedFor(nameof(DateSortIconGlyph), nameof(DateSortIconGlyph))]
    public partial ChoreSortOrder CurrentSortOrder { get; set; } = ChoreSortOrder.LastCompleted;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(NameSortIconGlyph), nameof(NameSortIconGlyph))]
    [NotifyPropertyChangedFor(nameof(DateSortIconGlyph), nameof(DateSortIconGlyph))]
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

        IsHistoryVisible = settingsService.IsHistoryOnCardsVisible;

        WeakReferenceMessenger.Default.Register<ChoreAddedMessage>(this);
        WeakReferenceMessenger.Default.Register<ChoresDataChangedMessage>(this);
        WeakReferenceMessenger.Default.Register<TagsChangedMessage>(this);
        WeakReferenceMessenger.Default.Register<ChoreActivatedMessage>(this);
        WeakReferenceMessenger.Default.Register<NotificationTappedMessage>(this);

        Task.Run(LoadData);

        refreshTimer = Application.Current?.Dispatcher.CreateTimer();
        if (refreshTimer != null)
        {
            refreshTimer.Interval = TimeSpan.FromSeconds(1);
            refreshTimer.Tick += (s, e) => HandlePrecisionTick();
        }
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
                ChoreSortOrder.DueDate => CurrentDirection == SortDirection.Ascending
                    ? filteredItems.OrderBy(i => i.NextDueDate.HasValue)
                                   .ThenBy(i => i.NextDueDate)
                                   .ThenBy(i => i.Name)
                    : filteredItems.OrderByDescending(i => i.NextDueDate.HasValue)
                                   .ThenByDescending(i => i.NextDueDate)
                                   .ThenBy(i => i.Name),
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
                CheckAndTriggerScroll();
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

        var popup = new CompletionPopup("Mission Report", "Log");
        var popupResult = await Shell.Current.ShowPopupAsync<CompletionRecord>(popup);
        if (popupResult == null || popupResult.Result == null)
        {
            return;
        }

        CompletionRecord result = popupResult.Result;

        switch (chore.RecurranceType)
        {
            case RecurranceType.Daily:
                chore.NextDueDate = result.CompletedAt.Date.AddDays(1) + (chore.NextDueDate?.TimeOfDay ?? result.CompletedAt.TimeOfDay);
                break;
            case RecurranceType.EveryOtherDay:
                chore.NextDueDate = result.CompletedAt.Date.AddDays(2) + (chore.NextDueDate?.TimeOfDay ?? result.CompletedAt.TimeOfDay);
                break;
            case RecurranceType.Weekly:
                chore.NextDueDate = result.CompletedAt.Date.AddDays(7) + (chore.NextDueDate?.TimeOfDay ?? result.CompletedAt.TimeOfDay);
                break;
            case RecurranceType.Monthly:
                chore.NextDueDate = result.CompletedAt.Date.AddMonths(1) + (chore.NextDueDate?.TimeOfDay ?? result.CompletedAt.TimeOfDay);
                break;
            case RecurranceType.None:
                chore.NextDueDate = null;
                break;
        }

        int recordId = await databaseService.CompleteChoreAsync(chore.ToBaseChore(), result);

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
    public async void Receive(ChoresDataChangedMessage message)
    {
        IsHistoryVisible = settingsService!.IsHistoryOnCardsVisible;
        await LoadData();
    }
    public async void Receive(TagsChangedMessage message) => await LoadData();
    public async void Receive(ChoreActivatedMessage message) => await LoadData();

    public async void Receive(NotificationTappedMessage message)
    {
        pendingScrollChoreId = message.Value;
        CheckAndTriggerScroll();
    }

    public void StartRefreshTimer() => refreshTimer?.Start();
    public void StopRefreshTimer() => refreshTimer?.Stop();

    private void HandlePrecisionTick()
    {
        var now = DateTime.Now;
        if (now.Minute != lastProcessedMinute)
        {
            lastProcessedMinute = now.Minute;
            RefreshUIRecurrence();
            return;
        }

        foreach (var item in Chores)
        {
            if (item.NextDueDate.HasValue)
            {
                var diff = now - item.NextDueDate.Value;
                if (diff.TotalSeconds >= 0 && diff.TotalSeconds < 1.5)
                {
                    item.TriggerRefresh();
                }
            }
        }
    }

    private void RefreshUIRecurrence()
    {
        foreach (var item in Chores)
        {
            item.TriggerRefresh();
        }
    }

    private void CheckAndTriggerScroll()
    {
        if (pendingScrollChoreId > 0)
        {
            var item = Chores.FirstOrDefault(c => c.Id == pendingScrollChoreId);
            if (item != null)
            {
                RequestScrollToItem?.Invoke(this, item);
                pendingScrollChoreId = -1;
            }
        }
    }
}