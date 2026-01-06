using System.Collections.ObjectModel;
using ChoreBuddy.Messages;
using ChoreBuddy.Models;
using ChoreBuddy.Services;
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;

namespace ChoreBuddy.ViewModels;

public partial class ArchiveViewModel : ObservableObject
{
    private readonly ChoreDatabaseService databaseService = null!;
    public ObservableCollection<Chore> ArchivedChores { get; } = [];

    public ArchiveViewModel(ChoreDatabaseService databaseService)
    {
        this.databaseService = databaseService;
        Task.Run(LoadData);
    }

    public async Task LoadData()
    {
        var chores = await databaseService.GetArchivedChoresAsync() ?? [];
        ArchivedChores.Clear();
        foreach (var chore in chores)
        {
            ArchivedChores.Add(chore);
        }
    }


    [RelayCommand]
    private async Task UnarchiveChore(Chore chore)
    {
        if (chore == null)
        {
            return;
        }

        bool confirm = await Application.Current!.Windows[0].Page!.DisplayAlert(
            "Unarchive Chore",
            $"Are you sure you want to UNarchive '{chore.Name}'?",
            "Yes, Unarchive",
            "Cancel"
        );

        if (confirm)
        {
            chore.IsActive = true;
            await databaseService.SaveChoreAsync(chore);
            await Snackbar.Make("Chore unarchived", duration: TimeSpan.FromMilliseconds(500)).Show();
            await LoadData();
            WeakReferenceMessenger.Default.Send(new ChoreActivatedMessage());
        }
    }
}
