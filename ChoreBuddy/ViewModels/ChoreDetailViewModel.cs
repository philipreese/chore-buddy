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

    public ObservableCollection<CompletionRecord> History { get; } = [];
    public ObservableCollection<Tag> AvailableTags { get; } = [];
    public ObservableCollection<Tag> SelectedTags { get; } = [];


    [ObservableProperty]
    public partial Chore Chore { get; set; }

    public int ChoreId
    {
        get => field;
        set
        {
            field = value;
            Task.Run(async () => await LoadHistory(field));
        }
    }

    public ChoreDetailViewModel(ChoreDatabaseService databaseService)
    {
        this.databaseService = databaseService;
    }

    private async Task LoadHistory(int choreId)
    {
        var chore = await databaseService.GetChoreAsync(choreId);
        if (chore != null)
        {
            Chore = chore;
        }

        var allTags = await databaseService.GetTagsAsync();
        AvailableTags.Clear();


        var myTags = await databaseService.GetTagsForChoreAsync(choreId);
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

            foreach (var t in allTags)
            {
                t.IsSelected = SelectedTags.Any(mt => mt.Id == t.Id);
                AvailableTags.Add(t);
            }

            foreach (var record in records)
            {
                History.Add(record);
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
            await LoadHistory(Chore.Id);
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
        if (string.IsNullOrWhiteSpace(Chore.Name)) return;

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
}
