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

public partial class MainViewModel : ObservableObject, IRecipient<ChoresDataChangedMessage>, IRecipient<TagsChangedMessage>
{
    private readonly ChoreDatabaseService databaseService = null!;
    public ObservableCollection<ChoreDisplayItem> Chores { get; } = [];

    [ObservableProperty]
    public partial string NewChoreName { get; set; } = string.Empty;

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

    public string DateSortIconGlyph => "\uf073";

    public MainViewModel() { }

    public MainViewModel(ChoreDatabaseService databaseService)
    {
        this.databaseService = databaseService;

        LoadChoresCommand.Execute(null);
        WeakReferenceMessenger.Default.Register<ChoresDataChangedMessage>(this);
        WeakReferenceMessenger.Default.Register<TagsChangedMessage>(this);
    }

    [RelayCommand]
    private async Task LoadChores()
    {
        var chores = await databaseService.GetActiveChoresAsync();

        IEnumerable<Chore> sortedChores = CurrentSortOrder switch
        {
            ChoreSortOrder.Name => (CurrentDirection == SortDirection.Ascending)
                                    ? chores.OrderBy(c => c.Name)
                                    : chores.OrderByDescending(c => c.Name),
            ChoreSortOrder.LastCompleted => (CurrentDirection == SortDirection.Ascending)
                                             ? chores.OrderBy(c => c.LastCompleted.HasValue)
                                                     .ThenBy(c => c.LastCompleted)
                                             : chores.OrderByDescending(c => c.LastCompleted.HasValue)
                                                     .ThenByDescending(c => c.LastCompleted),
            _ => chores
        };

        Chores.Clear();
        foreach (var chore in sortedChores)
        {
            var tags = await databaseService.GetTagsForChoreAsync(chore.Id);
            Chores.Add(ChoreDisplayItem.FromChore(chore, tags));
        }

        DeleteAllChoresCommand.NotifyCanExecuteChanged();
    }

    [RelayCommand(CanExecute = nameof(CanAddNewChore))]
    private async Task AddChore()
    {
        if (string.IsNullOrWhiteSpace(NewChoreName))
        {
            return;
        }

        var newChore = new Chore { Name = NewChoreName.Trim() };
        int result = await databaseService.SaveChoreAsync(newChore);
        if (result == -1)
        {
            await Shell.Current.DisplayAlert("Error", "Chore name already exists", "OK");
            return;
        }

        Chores.Add(ChoreDisplayItem.FromChore(newChore, []));
        NewChoreName = string.Empty;

        WeakReferenceMessenger.Default.Send(new ChoreAddedMessage());
    }

    private bool CanAddNewChore()
    {
        return !string.IsNullOrWhiteSpace(NewChoreName);
    }

    partial void OnNewChoreNameChanged(string value)
    {
        AddChoreCommand.NotifyCanExecuteChanged();
        DeleteAllChoresCommand.NotifyCanExecuteChanged();
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

        await LoadChoresCommand.ExecuteAsync(null);

        await Snackbar.Make(
            "Chore completed",
            action: async () =>
            {
                await databaseService.DeleteCompletionRecordAsync(recordId);
                LoadChoresCommand.Execute(null);
            },
            actionButtonText: "UNDO",
            duration: TimeSpan.FromSeconds(5))
        .Show();

        OnPropertyChanged(nameof(Chores));
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
            Chores.Remove(chore);
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
            Chores.Clear();
        }
    }

    private bool CanDeleteAllChores()
    {
        return Chores.Count > 0;
    }

    [RelayCommand]
    private static async Task GoToDetails(ChoreDisplayItem item)
    {
        int id = item?.Id ?? 0;
        await Shell.Current.GoToAsync($"ChoreDetailsPage?ChoreId={id}");
    }

    [RelayCommand]
    static async Task NavigateToTags() => await Shell.Current.GoToAsync("TagsPage");

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

        await LoadChores();
    }

    public async void Receive(ChoresDataChangedMessage message) => await LoadChores();
    public async void Receive(TagsChangedMessage message) => await LoadChores();
}