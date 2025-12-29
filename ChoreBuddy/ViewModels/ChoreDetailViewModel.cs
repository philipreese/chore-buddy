using System.Collections.ObjectModel;
using ChoreBuddy.Messages;
using ChoreBuddy.Models;
using ChoreBuddy.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.ViewModels;

[QueryProperty(nameof(ChoreId), nameof(ChoreId))]
[QueryProperty(nameof(ChoreName), nameof(ChoreName))]
public partial class ChoreDetailViewModel : ObservableObject
{
    private readonly ChoreDatabaseService databaseService;

    public ObservableCollection<CompletionRecord> History { get; } = [];

    [ObservableProperty]
    public partial int ChoreId { get; set; }

    [ObservableProperty]
    public partial string ChoreName { get; set; } = string.Empty;

    public ChoreDetailViewModel(ChoreDatabaseService databaseService)
    {
        this.databaseService = databaseService;
    }

    partial void OnChoreIdChanged(int value)
    {
        Task.Run(async () => await LoadHistory(value));
    }

    private async Task LoadHistory(int choreId)
    {
        History.Clear();
        var records = await databaseService.GetHistoryAsync(choreId);

        MainThread.BeginInvokeOnMainThread(() =>
        {
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
            await LoadHistory(ChoreId);
            WeakReferenceMessenger.Default.Send(new ChoresDataChangedMessage());
        }
    }
}
