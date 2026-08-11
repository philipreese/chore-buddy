using ChoreBuddy.Models;
using ChoreBuddy.Services.Data;

namespace ChoreBuddy.Services.Logic;

public class ChoreDataService(
    ISqliteConnectionFactory connectionFactory,
    IRepository<Chore> choreRepo,
    IRepository<CompletionRecord> recordRepo,
    IRepository<Tag> tagRepo,
    IRepository<ChoreTag> choreTagRepo) : IChoreDataService
{
    private readonly ISqliteConnectionFactory connectionFactory = connectionFactory;
    private readonly IRepository<Chore> choreRepo = choreRepo;
    private readonly IRepository<CompletionRecord> recordRepo = recordRepo;
    private readonly IRepository<Tag> tagRepo = tagRepo;
    private readonly IRepository<ChoreTag> choreTagRepo = choreTagRepo;

    public async Task InitializeAsync()
    {
        // Still requires a direct connection to ensure tables are built on first run.
        await connectionFactory.GetConnectionAsync();
    }

    public Task<List<Chore>> GetActiveChoresAsync()
    {
        return choreRepo.GetAsync(c => c.IsActive);
    }

    public Task<List<Chore>> GetArchivedChoresAsync()
    {
        return choreRepo.GetAsync(c => !c.IsActive);
    }

    public async Task<List<ChoreTagMap>> GetAllChoreTagMappingsAsync()
    {
        var query = @"
            SELECT ct.ChoreId, t.Id as TagId, t.Name, t.ColorHex 
            FROM ChoreTag ct
            INNER JOIN Tag t ON ct.TagId = t.Id";

        return await choreTagRepo.QueryAsync<ChoreTagMap>(query);
    }

    public async Task<int> SaveChoreAsync(Chore chore)
    {
        var existingResult = await choreRepo.GetAsync(c => c.Name.ToLower() == chore.Name.ToLower());
        var existing = existingResult.FirstOrDefault();

        return existing != null && existing.Id != chore.Id
            ? -1
            : chore.Id != 0 ? await choreRepo.UpdateAsync(chore) : await choreRepo.InsertAsync(chore);
    }

    public Task<Chore?> GetChoreAsync(int choreId)
    {
        return choreRepo.GetByIdAsync(choreId);
    }

    public async Task DeleteChoreAsync(Chore chore)
    {
        await choreRepo.DeleteAsync(chore);

        var records = await recordRepo.GetAsync(r => r.ChoreId == chore.Id);
        foreach (var record in records)
        {
            await recordRepo.DeleteAsync(record);
        }

        var links = await choreTagRepo.GetAsync(c => c.ChoreId == chore.Id);
        foreach (var link in links)
        {
            await choreTagRepo.DeleteAsync(link);
        }
    }

    public async Task DeleteAllChoresAsync()
    {
        await choreRepo.DeleteAllAsync();
        await recordRepo.DeleteAllAsync();
    }

    public async Task AddCompletionRecordAsync(Chore chore, string note)
    {
        var record = new CompletionRecord
        {
            ChoreId = chore.Id,
            CompletedAt = DateTime.Now,
            Note = note
        };

        await recordRepo.InsertAsync(record);

        chore.LastCompleted = record.CompletedAt;
        chore.LastNote = record.Note;
        await choreRepo.UpdateAsync(chore);
    }

    public async Task DeleteCompletionRecordAsync(CompletionRecord completionRecord)
    {
        if (await recordRepo.DeleteAsync(completionRecord) > 0)
        {
            await UpdateChoreWithMostRecentRecord(completionRecord.ChoreId);
        }
    }

    public async Task DeleteCompletionRecordAsync(int recordId)
    {
        var record = await recordRepo.GetByIdAsync(recordId);
        if (record != null)
        {
            await DeleteCompletionRecordAsync(record);
        }
    }

    public async Task<List<CompletionRecord>> GetHistoryAsync(int choreId)
    {
        var records = await recordRepo.GetAsync(r => r.ChoreId == choreId);
        return [.. records.OrderByDescending(r => r.CompletedAt)];
    }

    public async Task<int> CompleteChoreAsync(Chore chore, CompletionRecord record)
    {
        chore.LastNote = record.Note;
        chore.LastCompleted = record.CompletedAt;
        record.ChoreId = chore.Id;

        await recordRepo.InsertAsync(record);

        var existingChore = await GetChoreAsync(chore.Id);
        if (existingChore != null)
        {
            await choreRepo.UpdateAsync(chore);
        }

        return record.Id;
    }

    public async Task UpdateCompletionRecordAsync(CompletionRecord record)
    {
        if (await recordRepo.UpdateAsync(record) > 0)
        {
            await UpdateChoreWithMostRecentRecord(record.ChoreId);
        }
    }

    public async Task<(DateTime? lastCompleted, string? lastNote)> GetLastCompletionDetailsAsync(int choreId)
    {
        var records = await recordRepo.GetAsync(r => r.ChoreId == choreId);
        var lastRecord = records.OrderByDescending(r => r.CompletedAt).FirstOrDefault();

        if (lastRecord == null)
        {
            return (null, null);
        }

        return (lastRecord.CompletedAt, lastRecord.Note);
    }

    public async Task<List<Tag>> GetTagsAsync()
    {
        var tags = await tagRepo.GetAllAsync();
        return [.. tags.OrderBy(t => t.Name)];
    }

    public async Task<int> SaveTagAsync(Tag tag)
    {
        var existingResult = await tagRepo.GetAsync(t => t.Name.ToLower() == tag.Name.ToLower());
        var existing = existingResult.FirstOrDefault();

        if (existing != null && existing.Id != tag.Id) return -1;

        return tag.Id != 0 ? await tagRepo.UpdateAsync(tag) : await tagRepo.InsertAsync(tag);
    }

    public async Task DeleteTagAsync(Tag tag)
    {
        await tagRepo.DeleteAsync(tag);
        
        var links = await choreTagRepo.GetAsync(c => c.TagId == tag.Id);
        foreach (var link in links)
        {
             await choreTagRepo.DeleteAsync(link);
        }
    }

    public async Task DeleteTagsAsync()
    {
        await tagRepo.DeleteAllAsync();
        await choreTagRepo.DeleteAllAsync();
    }

    public async Task<List<Tag>> GetTagsForChoreAsync(int choreId)
    {
        // Single JOIN query instead of a serial N+1 loop.
        var query = @"
            SELECT t.Id, t.Name, t.ColorHex
            FROM Tag t
            INNER JOIN ChoreTag ct ON ct.TagId = t.Id
            WHERE ct.ChoreId = ?";

        return await choreTagRepo.QueryAsync<Tag>(query, choreId);
    }

    public async Task UpdateChoreTagsAsync(int choreId, IEnumerable<int> tagIds)
    {
        var existingLinks = await choreTagRepo.GetAsync(c => c.ChoreId == choreId);
        foreach(var link in existingLinks)
        {
             await choreTagRepo.DeleteAsync(link);
        }

        await choreTagRepo.RunInTransactionAsync(tran =>
        {
            foreach (var tagId in tagIds)
            {
                tran.Insert(new ChoreTag { ChoreId = choreId, TagId = tagId });
            }
        });
    }

    private async Task UpdateChoreWithMostRecentRecord(int choreId)
    {
        var chore = await GetChoreAsync(choreId);
        if (chore == null)
        {
            return;
        }

        var (newLastCompleted, newLastNote) = await GetLastCompletionDetailsAsync(chore.Id);

        chore.LastCompleted = newLastCompleted;
        chore.LastNote = newLastNote ?? string.Empty;
        await choreRepo.UpdateAsync(chore);
    }
}
