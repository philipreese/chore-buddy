using ChoreBuddy.Models;

namespace ChoreBuddy.Services.Logic;

public interface IChoreDataService
{
    Task InitializeAsync();
    
    // Chore Operations
    Task<List<Chore>> GetActiveChoresAsync();
    Task<List<Chore>> GetArchivedChoresAsync();
    Task<Chore?> GetChoreAsync(int choreId);
    Task<int> SaveChoreAsync(Chore chore);
    Task DeleteChoreAsync(Chore chore);
    Task DeleteAllChoresAsync();
    
    // Completion Record Operations
    Task AddCompletionRecordAsync(Chore chore, string note);
    Task DeleteCompletionRecordAsync(CompletionRecord completionRecord);
    Task DeleteCompletionRecordAsync(int recordId);
    Task<List<CompletionRecord>> GetHistoryAsync(int choreId);
    Task<int> CompleteChoreAsync(Chore chore, CompletionRecord record);
    Task UpdateCompletionRecordAsync(CompletionRecord record);
    Task<(DateTime? lastCompleted, string? lastNote)> GetLastCompletionDetailsAsync(int choreId);

    // Tag Operations
    Task<List<Tag>> GetTagsAsync();
    Task<int> SaveTagAsync(Tag tag);
    Task DeleteTagAsync(Tag tag);
    Task DeleteTagsAsync();
    Task<List<Tag>> GetTagsForChoreAsync(int choreId);
    Task UpdateChoreTagsAsync(int choreId, IEnumerable<int> tagIds);
    Task<List<ChoreTagMap>> GetAllChoreTagMappingsAsync();
}
