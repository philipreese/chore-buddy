using System.Collections.ObjectModel;
using ChoreBuddy.Messages;
using ChoreBuddy.Models;
using ChoreBuddy.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.ViewModels;

[QueryProperty(nameof(ChoreId), nameof(ChoreId))]
public partial class ChoreDetailViewModel : ObservableObject
{
    private readonly ChoreDatabaseService databaseService;
    private int lastProcessedChoreId = -1;
    public ObservableCollection<CompletionRecord> History { get; } = [];
    public ObservableCollection<Tag> AvailableTags { get; } = [];
    public ObservableCollection<Tag> SelectedTags { get; } = [];

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(PageTitle))]
    public partial Chore? Chore { get; set; }

    public int ChoreId
    {
        get => field;
        set
        {
            field = value;
            if (value == lastProcessedChoreId)
            {
                return;
            }

            IsReturningFromSubPage = false;
            Task.Run(async () => await LoadHistory(field));
        }
    }

    public string PageTitle => Chore?.Id > 0 ? Chore.Name : "Add New Chore";

    [ObservableProperty]
    public partial bool IsEditPanelOpen { get; set; }

    public bool IsReturningFromSubPage { get; set; }

    public ChoreDetailViewModel(ChoreDatabaseService databaseService)
    {
        this.databaseService = databaseService;
        WeakReferenceMessenger.Default.Register<ReturningFromTagsMessage>(this, (r, m) =>
        {
            IsReturningFromSubPage = true;
        });
    }

    private async Task LoadHistory(int choreId)
    {
        var allTags = await databaseService.GetTagsAsync();
        List<Tag> myTags = [];

        if (choreId != 0)
        {
            var chore = await databaseService.GetChoreAsync(choreId);
            if (chore != null)
            {
                Chore = chore;
            }

            AvailableTags.Clear();

            myTags = await databaseService.GetTagsForChoreAsync(choreId);
            SelectedTags.Clear();

            var records = await databaseService.GetHistoryAsync(choreId);
            History.Clear();
            MainThread.BeginInvokeOnMainThread(() =>
            {   
                foreach (var t in myTags)
                {
                    t.IsSelected = true;
                    SelectedTags.Add(t);
                }
                foreach (var record in records)
                {
                    History.Add(record);
                }
            });
        }
        else
        {
            AvailableTags.Clear();
            SelectedTags.Clear();
            History.Clear();
            Chore = new Chore();
        }

        MainThread.BeginInvokeOnMainThread(() =>
        {
            foreach (var t in allTags)
            {
                t.IsSelected = SelectedTags.Any(mt => mt.Id == t.Id);
                AvailableTags.Add(t);
            }
        });
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
            await LoadHistory(Chore!.Id);
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
            await LoadHistory(Chore!.Id);
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
        if (string.IsNullOrWhiteSpace(Chore!.Name)) return;

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
    async Task AddTag() => await Shell.Current.GoToAsync("TagsPage");
}
