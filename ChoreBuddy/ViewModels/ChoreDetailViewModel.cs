using System.Collections.ObjectModel;
using ChoreBuddy.Messages;
using ChoreBuddy.Models;
using ChoreBuddy.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.ViewModels;

[QueryProperty(nameof(ChoreId), nameof(ChoreId))]
public partial class ChoreDetailViewModel :
    ObservableObject,
    IRecipient<ReturningFromTagsMessage>,
    IRecipient<UndoCompleteChoreMessage>
{
    private readonly ChoreDatabaseService databaseService;
    public ObservableCollection<CompletionRecord> History { get; } = [];
    public ObservableCollection<Tag> AvailableTags { get; } = [];
    public ObservableCollection<Tag> SelectedTags { get; } = [];

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(ChoreDisplayName))]
    public partial Chore? Chore { get; set; }

    [ObservableProperty]
    public partial int ChoreId{ get; set; }

    [ObservableProperty]
    public partial bool IsBusy { get; set; }

    [ObservableProperty]
    public partial bool IsHistoryLoading { get; set; }

    public string ChoreDisplayName
    {
        get => Chore is null || Chore.Id == 0 || string.IsNullOrEmpty(Chore.Name)
                            ? "New Chore"
                            : Chore.Name;
    }

    [ObservableProperty]
    public partial bool IsEditPanelOpen { get; set; }

    public bool IsReturningFromSubPage { get; set; }

    private CancellationTokenSource? loadingCts;

    public ChoreDetailViewModel(ChoreDatabaseService databaseService)
    {
        this.databaseService = databaseService;
        WeakReferenceMessenger.Default.Register<ReturningFromTagsMessage>(this);
        WeakReferenceMessenger.Default.Register<UndoCompleteChoreMessage>(this);
    }

    [RelayCommand]
    public async Task LoadDataAsync()
    {
        CancelLoading();
        loadingCts = new CancellationTokenSource();
        var token = loadingCts.Token;

        try
        {
            IsBusy = true;

            if (ChoreId == 0)
            {
                Chore = new Chore { IsActive = true };
            }
            else
            {
                var chore = await Task.Run(() => databaseService.GetChoreAsync(ChoreId), token);

                if (token.IsCancellationRequested)
                {
                    return;
                }

                if (chore != null)
                {
                    Chore = chore;
                }
            }

            await LoadTagsAsync(token);

            if (ChoreId != 0 && !IsReturningFromSubPage)
            {
                _ = LoadHistory(ChoreId, token);
            }

            IsReturningFromSubPage = false;
        }
        catch (OperationCanceledException) { }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Load error: {ex.Message}");
        }
        finally
        {
            IsBusy = false;
        }
    }

    private async Task LoadTagsAsync(CancellationToken token)
    {
        var tagsTask = Task.Run(databaseService.GetTagsAsync, token);
        var selectedTask = Task.Run(() => databaseService.GetTagsForChoreAsync(ChoreId), token);

        await Task.WhenAll(tagsTask, selectedTask);

        if (token.IsCancellationRequested)
        {
            return;
        }

        var allTags = tagsTask.Result;
        var choreTags = selectedTask.Result;

        MainThread.BeginInvokeOnMainThread(() =>
        {
            if (token.IsCancellationRequested)
            {
                return;
            }

            SelectedTags.Clear();
            foreach (var tag in choreTags)
            {
                SelectedTags.Add(tag);
            }

            AvailableTags.Clear();
            foreach (var tag in allTags)
            {
                tag.IsSelected = choreTags.Any(t => t.Id == tag.Id);
                AvailableTags.Add(tag);
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
            var records = await Task.Run(() => databaseService.GetHistoryAsync(id), token);

            if (token.IsCancellationRequested)
            {
                return;
            }

            MainThread.BeginInvokeOnMainThread(() =>
            {
                if (token.IsCancellationRequested)
                {
                    return;
                }

                History.Clear();
                foreach (var record in records)
                {
                    History.Add(record);
                }
            });
        }
        catch (Exception) { }
        finally
        {
            IsHistoryLoading = false;
        }
    }

    async partial void OnChoreIdChanged(int value)
    {
        if (History.Count > 0)
        {
            History.Clear();
        }
        if (AvailableTags.Count > 0)
        { 
            AvailableTags.Clear();
        }
        if (SelectedTags.Count > 0)
        {
            SelectedTags.Clear();
        }

        Chore = null;
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
            "Delete Completion Record",
            $"Are you sure you want to delete this record'? This action cannot be undone",
            "Yes, Delete",
            "Cancel"
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
        string newNote = await Shell.Current.DisplayPromptAsync(
            "Edit Completion Note",
            $"Edit the note for completion on {record.CompletedAt:M/d/yy}.",
            "Save",
            "Cancel",
            initialValue: record.Note ?? "");


        if (newNote != null)
        {
            record.Note = newNote;
            await databaseService.UpdateCompletionRecordAsync(record);
            await LoadHistory(Chore!.Id, loadingCts?.Token ?? CancellationToken.None);
            WeakReferenceMessenger.Default.Send(new ChoresDataChangedMessage());
        }
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

        bool isNew = Chore.Id == 0;
        int result = await databaseService.SaveChoreAsync(Chore);
        if (result == -1)
        {
            await Shell.Current.DisplayAlert("Error", "Chore name already exists", "OK");
            return;
        }

        await databaseService.UpdateChoreTagsAsync(Chore.Id, SelectedTags.Select(t => t.Id));

        if (isNew)
        {
            WeakReferenceMessenger.Default.Send(new ChoreAddedMessage());
        }
        else
        {
            WeakReferenceMessenger.Default.Send(new ChoresDataChangedMessage());
        }

        await Shell.Current.GoToAsync("..");
    }

    [RelayCommand]
#pragma warning disable CA1822 // Mark members as static
    async Task AddTag() => await Shell.Current.GoToAsync("TagsPage");
#pragma warning restore CA1822 // Mark members as static

    public async void Receive(ReturningFromTagsMessage message)
    {
        IsReturningFromSubPage = true;
        await LoadTagsAsync(loadingCts?.Token ?? CancellationToken.None);
    }

    public async void Receive(UndoCompleteChoreMessage message)
    {
        if (ChoreId > 0)
        {
            await LoadHistory(ChoreId, loadingCts?.Token ?? CancellationToken.None);
        }
    }
}
