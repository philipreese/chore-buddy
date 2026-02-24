using System.Collections.ObjectModel;
using ChoreBuddy.Messages;
using ChoreBuddy.Models;
using ChoreBuddy.Services;
using ChoreBuddy.Services.Logic;
using ChoreBuddy.Utilities;
using ChoreBuddy.Views;
using CommunityToolkit.Maui.Extensions;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.ViewModels;

[QueryProperty(nameof(ChoreId), nameof(ChoreId))]
public partial class ChoreDetailViewModel :
    ObservableObject,
    ITagManager,
    IRecipient<ReturningFromTagsMessage>,
    IRecipient<UndoCompleteChoreMessage>
{
    private readonly IChoreDataService databaseService;
    private readonly NotificationService notificationService;
    private List<CompletionRecord>? pendingHistory;
    private List<Tag>? pendingAllTags;
    private List<Tag>? pendingChoreTags;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsHistoryEmpty))]
    [NotifyPropertyChangedFor(nameof(HasHistory))]
    public partial ObservableCollection<CompletionRecord> History { get; set; } = [];

    [ObservableProperty]
    public partial ObservableCollection<Tag> AvailableTags { get; set; } = [];

    public ObservableCollection<Tag> SelectedTags { get; } = [];

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(ChoreDisplayName))]
    public partial Chore? Chore { get; set; }

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsNew))]
    public partial int ChoreId{ get; set; }

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsHistoryEmpty))]
    [NotifyPropertyChangedFor(nameof(HasHistory))]
    public partial bool IsBusy { get; set; } = true;

    public bool IsNew => ChoreId == 0;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsHistoryEmpty))]
    [NotifyPropertyChangedFor(nameof(HasHistory))]
    public partial bool IsHistoryLoading { get; set; }
    public bool IsHistoryEmpty => !IsBusy && !IsHistoryLoading && History.Count == 0;
    public bool HasHistory => !IsBusy && !IsHistoryLoading && History.Count > 0;

    public string ChoreDisplayName => Chore switch
    {
        null => string.Empty,
        { Id: 0 } => "New Chore",
        _ => Chore.Name ?? string.Empty
    };

    [ObservableProperty]
    public partial bool IsEditPanelOpen { get; set; }

    public bool IsReturningFromSubPage { get; set; }

    [ObservableProperty]
    public partial DateTime SelectedDate { get; set; } = DateTime.Today.AddDays(1);

    [ObservableProperty]
    public partial TimeSpan SelectedTime { get; set; } = DateTime.Now.TimeOfDay;

    [ObservableProperty]
    public partial bool HasDueDate { get; set; }

    [ObservableProperty]
    public partial string SelectedRecurranceType { get; set; } = "None";

    public List<string> RecurranceOptions { get; } = [.. Enum.GetValues<RecurranceType>().Select(e => e.GetEnumDisplayName())];

    public bool ChoreSaved = false;

    private CancellationTokenSource? loadingCts;

    public static Chore? PendingChore { get; set; }

    public ChoreDetailViewModel(IChoreDataService databaseService, NotificationService notificationService)
    {
        this.databaseService = databaseService;
        this.notificationService = notificationService;

        WeakReferenceMessenger.Default.Register<ReturningFromTagsMessage>(this);
        WeakReferenceMessenger.Default.Register<UndoCompleteChoreMessage>(this);
    }

    // Called from OnAppearing so queries run DURING the slide-in animation.
    // Deliberately does NOT touch any ObservableCollection or fire heavy UI work.
    // All three queries run in parallel.
    [RelayCommand]
    public async Task PrefetchAsync()
    {
        CancelLoading();
        loadingCts = new CancellationTokenSource();
        var token = loadingCts.Token;

        try
        {
            IsBusy = true;
            IsHistoryLoading = true;

            if (ChoreId == 0)
            {
                Chore ??= new Chore { IsActive = true };
            }

            if (token.IsCancellationRequested) return;

            // Kick off all three queries in parallel — no UI work yet.
            var tagsTask = databaseService.GetTagsAsync();
            var choreTagsTask = databaseService.GetTagsForChoreAsync(ChoreId);
            var historyTask = ChoreId == 0
                ? Task.FromResult(new List<CompletionRecord>())
                : databaseService.GetHistoryAsync(ChoreId);

            await Task.WhenAll(tagsTask, choreTagsTask, historyTask);

            if (token.IsCancellationRequested)
            {
                return;
            }

            var allTags = tagsTask.Result;
            var choreTags = choreTagsTask.Result;
            var tagIds = choreTags.Select(t => t.Id).ToHashSet();

            foreach (var tag in allTags)
            {
                tag.IsSelected = tagIds.Contains(tag.Id);
            }

            pendingAllTags = allTags;
            pendingChoreTags = choreTags;
            pendingHistory = historyTask.Result;
        }
        catch (OperationCanceledException) { }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Prefetch error: {ex.Message}");
        }
    }

    // Called from OnNavigatedTo (animation is done) on the main thread.
    // All ObservableCollection/property updates happen here in one pass.
    public void ApplyPrefetchedData()
    {
        try
        {
            if (Chore != null)
            {
                HasDueDate = Chore.NextDueDate.HasValue;
                if (Chore.NextDueDate.HasValue)
                {
                    SelectedDate = Chore.NextDueDate.Value.Date;
                    SelectedTime = Chore.NextDueDate.Value.TimeOfDay;
                    SelectedRecurranceType = Chore.RecurranceType.GetEnumDisplayName();
                }
            }

            if (pendingAllTags != null)
            {
                AvailableTags = new ObservableCollection<Tag>(pendingAllTags);
            }

            SelectedTags.Clear();
            if (pendingChoreTags != null)
            {
                foreach (var t in pendingChoreTags)
                {
                    SelectedTags.Add(t);
                }
            }

            if (pendingHistory != null)
            {
                History = new ObservableCollection<CompletionRecord>(pendingHistory);
            }
        }
        finally
        {
            IsBusy = false;
            IsHistoryLoading = false;
            OnPropertyChanged(nameof(IsHistoryEmpty));
            OnPropertyChanged(nameof(HasHistory));
            pendingAllTags   = null;
            pendingChoreTags = null;
            pendingHistory   = null;
        }
    }

    [RelayCommand]
    public async Task LoadTagsAsync()
    {
        var token = loadingCts?.Token ?? CancellationToken.None;
        var tagsTask = databaseService.GetTagsAsync();
        var choreTagsTask = databaseService.GetTagsForChoreAsync(ChoreId);
        await Task.WhenAll(tagsTask, choreTagsTask);

        if (token.IsCancellationRequested)
        {
            return;
        }

        var allTags = tagsTask.Result;
        var choreTags = choreTagsTask.Result;
        var tagIds = choreTags.Select(t => t.Id).ToHashSet();
        foreach (var tag in allTags)
        {
            tag.IsSelected = tagIds.Contains(tag.Id);
        }

        MainThread.BeginInvokeOnMainThread(() =>
        {
            AvailableTags = new ObservableCollection<Tag>(allTags);
            SelectedTags.Clear();
            foreach (var tag in choreTags)
            {
                SelectedTags.Add(tag);
            }
        });
    }

    [RelayCommand]
    public async Task LoadHistory(int id, CancellationToken token = default)
    {
        if (id <= 0)
        {
            return;
        }

        try
        {
            IsHistoryLoading = true;
            var records = await databaseService.GetHistoryAsync(id);

            if (token.IsCancellationRequested)
            {
                return;
            }

            MainThread.BeginInvokeOnMainThread(() =>
            {
                History = new ObservableCollection<CompletionRecord>(records);
            });
        }
        catch (Exception) { }
        finally
        {
            IsHistoryLoading = false;
            OnPropertyChanged(nameof(IsHistoryEmpty));
            OnPropertyChanged(nameof(HasHistory));
        }
    }

    async partial void OnChoreIdChanged(int value)
    {
        if (PendingChore?.Id == value)
        {
            Chore = PendingChore.ToBaseChore();
            PendingChore = null;
        }
    }

    public void CancelLoading()
    {
        loadingCts?.Cancel();
        loadingCts?.Dispose();
        loadingCts = null;
    }

    [RelayCommand]
    private async Task DeleteCompletionRecord(CompletionRecord completionRecord)
    {
        if (completionRecord == null)
        {
            return;
        }

        bool confirm = await Application.Current!.Windows[0].Page!.DisplayAlert(
            "Expunge Heroics",
            $"Shall we remove this entry from the official record of your heroics? This action cannot be undone.",
            "Expunge",
            "Keep Record"
        );

        if (confirm)
        {
            await databaseService.DeleteCompletionRecordAsync(completionRecord);
            History.Remove(completionRecord);
            WeakReferenceMessenger.Default.Send(new ChoresDataChangedMessage());
        }
    }


    [RelayCommand]
    async Task EditCompletionNote(CompletionRecord record)
    {
        var popup = new CompletionPopup("Archive Revision", "Update", record.CompletedAt, record.Note ?? string.Empty, true);
        var popupResult = await Shell.Current.ShowPopupAsync<CompletionRecord>(popup);
        if (popupResult == null || popupResult.Result == null)
        {
            return;
        }

        CompletionRecord result = popupResult.Result;
        record.Note = result.Note;
        record.CompletedAt = result.CompletedAt;

        await databaseService.UpdateCompletionRecordAsync(record);

        if (Chore != null && record.CompletedAt >= (Chore.LastCompleted ?? DateTime.MinValue))
        {
            Chore.LastCompleted = record.CompletedAt;
            Chore.LastNote = record.Note;
            await databaseService.SaveChoreAsync(Chore);
        }

        await LoadHistory(Chore!.Id, loadingCts?.Token ?? CancellationToken.None);
        WeakReferenceMessenger.Default.Send(new ChoresDataChangedMessage());
    }

    [RelayCommand]
    async Task ToggleTag(Tag tag)
    {
        if (SelectedTags.Any(t => t.Id == tag.Id))
        {
            SelectedTags.Remove(SelectedTags.First(t => t.Id == tag.Id));
        }
        else
        {
            SelectedTags.Add(tag);
        }

        tag.IsSelected = !tag.IsSelected;
    }

    [RelayCommand]
    async Task SaveChore()
    {
        if (string.IsNullOrWhiteSpace(Chore!.Name))
        {
            return;
        }

        if (HasDueDate)
        {
            Chore.NextDueDate = SelectedDate.Date + SelectedTime;
            Chore.RecurranceType = Utilities.Extensions.GetEnumFromDisplayName<RecurranceType>(SelectedRecurranceType);
        }
        else
        {
            Chore.NextDueDate = null;
            Chore.RecurranceType = RecurranceType.None;
        }

        bool isNew = Chore.Id == 0;
        int result = await databaseService.SaveChoreAsync(Chore);
        if (result == -1)
        {
            await Shell.Current.DisplayAlert(
                "Registry Conflict",
                "A mission with this callsign already exists. Please choose a unique identifier for this chore.",
                "Roger That");
            return;
        }

        await databaseService.UpdateChoreTagsAsync(Chore.Id, SelectedTags.Select(t => t.Id));
        notificationService.ScheduleChoreNotification(Chore);

        if (isNew)
        {
            WeakReferenceMessenger.Default.Send(new ChoreAddedMessage());
        }
        else
        {
            WeakReferenceMessenger.Default.Send(new ChoresDataChangedMessage());
        }

        ChoreSaved = true;
        await Shell.Current.GoToAsync("..");
    }

    [RelayCommand]
#pragma warning disable CA1822 // Mark members as static
    async Task AddTag() => await Shell.Current.GoToAsync("///TagsPage");
#pragma warning restore CA1822 // Mark members as static

    public async void Receive(ReturningFromTagsMessage message)
    {
        IsReturningFromSubPage = true;
        await LoadTagsAsync();
    }

    public async void Receive(UndoCompleteChoreMessage message)
    {
        if (ChoreId > 0)
        {
            await LoadHistory(ChoreId, loadingCts?.Token ?? CancellationToken.None);
        }
    }
}
