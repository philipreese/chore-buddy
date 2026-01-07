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
    public ObservableCollection<ChoreDisplayItem> ArchivedChores { get; } = [];

    [ObservableProperty]
    public partial bool IsBusy { get; set; }

    public ArchiveViewModel(ChoreDatabaseService databaseService)
    {
        this.databaseService = databaseService;
    }

    public async Task LoadDataAsync()
    {
        if (IsBusy)
        {
            return;
        }

        IsBusy = true;

        try
        {
            var chores = await databaseService.GetArchivedChoresAsync();
            var mappings = await databaseService.GetAllChoreTagMappingsAsync();

            var tagLookup = mappings
                .GroupBy(m => m.ChoreId)
                .ToDictionary(g => g.Key, g => g.Select(m => new Tag { Id = m.TagId, Name = m.Name, ColorHex = m.ColorHex }).ToList());

            var filteredItems = chores
                .Select(c => ChoreDisplayItem.FromChore(c, tagLookup.TryGetValue(c.Id, out var tags) ? tags : []));


            var newList = filteredItems.ToList();

            MainThread.BeginInvokeOnMainThread(() =>
            {

                // Remove items no longer in the list
                for (int i = ArchivedChores.Count - 1; i >= 0; i--)
                {
                    if (newList.All(n => n.Id != ArchivedChores[i].Id))
                    {
                        ArchivedChores.RemoveAt(i);
                    }
                }

                // Add or move items
                for (int i = 0; i < newList.Count; i++)
                {
                    var newItem = newList[i];
                    var existingItemIndex = -1;

                    // Find if it exists
                    for (int j = 0; j < ArchivedChores.Count; j++)
                    {
                        if (ArchivedChores[j].Id == newItem.Id)
                        {
                            existingItemIndex = j;
                            break;
                        }
                    }

                    if (existingItemIndex == -1)
                    {
                        // Insert new item at correct position
                        ArchivedChores.Insert(i, newItem);
                    }
                    else if (existingItemIndex != i)
                    {
                        // Move existing item to correct sort position
                        ArchivedChores.Move(existingItemIndex, i);
                    }

                    // Check to see if the item needs updating
                    if (!ArchivedChores[i].Equals(newItem))
                    {
                        ArchivedChores[i] = newItem;
                    }
                }

                OnPropertyChanged(nameof(ArchivedChores));
            });
        }
        finally
        {
            IsBusy = false;
        }
    }

    [RelayCommand]
    private async Task RestoreChore(ChoreDisplayItem chore)
    {
        if (chore == null)
        {
            return;
        }

        bool confirm = await Application.Current!.Windows[0].Page!.DisplayAlert(
            "Restore Chore",
            $"Are you sure you want to restore '{chore.Name}'?",
            "Yes, Restore",
            "Cancel"
        );

        if (confirm)
        {
            Chore item = chore.ToBaseChore();
            item.IsActive = true;
            await databaseService.SaveChoreAsync(item);
            await Snackbar.Make("Chore restored", duration: TimeSpan.FromMilliseconds(350)).Show();
            await LoadDataAsync();
            WeakReferenceMessenger.Default.Send(new ChoreActivatedMessage());
        }
    }
}
