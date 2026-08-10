using ChoreBuddy.Models;
using Microsoft.Extensions.Caching.Memory;

namespace ChoreBuddy.Services.Logic;

public class CachedChoreDataService(IChoreDataService innerService, IMemoryCache cache) : IChoreDataService
{
    private readonly IChoreDataService innerService = innerService;
    private readonly IMemoryCache cache = cache;
    
    // Cache Keys
    private const string ActiveChoresCacheKey = "ActiveChoresList";
    private const string TagsCacheKey = "TagsList";
    private static string ChoreKey(int id) => $"Chore_{id}";
    private static string HistoryKey(int id) => $"History_{id}";
    private static string ChoreTagsKey(int id) => $"ChoreTags_{id}";

    public Task InitializeAsync() => innerService.InitializeAsync();

    // --- Active Chores ---
    public async Task<List<Chore>> GetActiveChoresAsync()
    {
        if (!cache.TryGetValue(ActiveChoresCacheKey, out List<Chore>? cached) || cached == null)
        {
            cached = await innerService.GetActiveChoresAsync();
            cache.Set(ActiveChoresCacheKey, cached, TimeSpan.FromMinutes(10));
        }

        return cached;
    }

    private void InvalidateActiveLists() => cache.Remove(ActiveChoresCacheKey);

    public Task<List<Chore>> GetArchivedChoresAsync() => innerService.GetArchivedChoresAsync();

    // --- Chore ---
    public async Task<int> SaveChoreAsync(Chore chore)
    {
        var result = await innerService.SaveChoreAsync(chore);
        if (result != -1) 
        {
            InvalidateActiveLists();
            cache.Remove(ChoreKey(chore.Id));
        }

        return result;
    }

    public async Task<Chore?> GetChoreAsync(int choreId)
    {
        if (!cache.TryGetValue(ChoreKey(choreId), out Chore? cached))
        {
            cached = await innerService.GetChoreAsync(choreId);
            if (cached != null)
            {
                cache.Set(ChoreKey(choreId), cached, TimeSpan.FromMinutes(10));
            }
        }
        return cached;
    }

    public async Task DeleteChoreAsync(Chore chore)
    {
        await innerService.DeleteChoreAsync(chore);
        InvalidateActiveLists();
        cache.Remove(ChoreKey(chore.Id));
        cache.Remove(HistoryKey(chore.Id));
        cache.Remove(ChoreTagsKey(chore.Id));
    }

    public async Task DeleteAllChoresAsync()
    {
        await innerService.DeleteAllChoresAsync();
        InvalidateActiveLists();
    }

    // --- History ---
    public async Task AddCompletionRecordAsync(Chore chore, string note)
    {
        await innerService.AddCompletionRecordAsync(chore, note);
        InvalidateActiveLists();
        cache.Remove(ChoreKey(chore.Id));
        cache.Remove(HistoryKey(chore.Id));
    }

    public async Task DeleteCompletionRecordAsync(CompletionRecord completionRecord)
    {
        await innerService.DeleteCompletionRecordAsync(completionRecord);
        InvalidateActiveLists();
        cache.Remove(ChoreKey(completionRecord.ChoreId));
        cache.Remove(HistoryKey(completionRecord.ChoreId));
    }

    public async Task DeleteCompletionRecordAsync(int recordId)
    {
        await innerService.DeleteCompletionRecordAsync(recordId);
        InvalidateActiveLists();
        // Dynamic History keys will naturally expire for this edge case.
    }

    public async Task<List<CompletionRecord>> GetHistoryAsync(int choreId)
    {
        if (!cache.TryGetValue(HistoryKey(choreId), out List<CompletionRecord>? cached) || cached == null)
        {
            cached = await innerService.GetHistoryAsync(choreId);
            cache.Set(HistoryKey(choreId), cached, TimeSpan.FromMinutes(10));
        }
        return cached;
    }

    public async Task<int> CompleteChoreAsync(Chore chore, CompletionRecord record)
    {
        var result = await innerService.CompleteChoreAsync(chore, record);
        InvalidateActiveLists();
        cache.Remove(ChoreKey(chore.Id));
        cache.Remove(HistoryKey(chore.Id));
        return result;
    }

    public async Task UpdateCompletionRecordAsync(CompletionRecord record)
    {
        await innerService.UpdateCompletionRecordAsync(record);
        InvalidateActiveLists();
        cache.Remove(ChoreKey(record.ChoreId));
        cache.Remove(HistoryKey(record.ChoreId));
    }

    public Task<(DateTime? lastCompleted, string? lastNote)> GetLastCompletionDetailsAsync(int choreId) => innerService.GetLastCompletionDetailsAsync(choreId);

    // --- Tags ---
    public async Task<List<Tag>> GetTagsAsync()
    {
        if (!cache.TryGetValue(TagsCacheKey, out List<Tag>? cached) || cached == null)
        {
            cached = await innerService.GetTagsAsync();
            cache.Set(TagsCacheKey, cached, TimeSpan.FromMinutes(10));
        }

        return cached;
    }

    public async Task<int> SaveTagAsync(Tag tag)
    {
        var result = await innerService.SaveTagAsync(tag);
        if (result != -1)
        {
            cache.Remove(TagsCacheKey);
        }

        return result;
    }

    public async Task DeleteTagAsync(Tag tag)
    {
        await innerService.DeleteTagAsync(tag);
        cache.Remove(TagsCacheKey);
    }

    public async Task DeleteTagsAsync()
    {
        await innerService.DeleteTagsAsync();
        cache.Remove(TagsCacheKey);
    }

    public async Task<List<Tag>> GetTagsForChoreAsync(int choreId)
    {
        if (!cache.TryGetValue(ChoreTagsKey(choreId), out List<Tag>? cached) || cached == null)
        {
            cached = await innerService.GetTagsForChoreAsync(choreId);
            cache.Set(ChoreTagsKey(choreId), cached, TimeSpan.FromMinutes(10));
        }

        return cached;
    }

    public async Task UpdateChoreTagsAsync(int choreId, IEnumerable<int> tagIds)
    {
        await innerService.UpdateChoreTagsAsync(choreId, tagIds);
        cache.Remove(ChoreTagsKey(choreId));
    }

    public Task<List<ChoreTagMap>> GetAllChoreTagMappingsAsync() => innerService.GetAllChoreTagMappingsAsync();
}
