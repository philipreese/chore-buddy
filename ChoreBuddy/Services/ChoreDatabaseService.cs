using ChoreBuddy.Models;
using SQLite;

namespace ChoreBuddy.Services;

public class ChoreDatabaseService
{
    private SQLiteAsyncConnection database = null!;
    private const string DatabaseFilename = "ChoreBuddy.db3";
    private static string DatabasePath => Path.Combine(FileSystem.AppDataDirectory, DatabaseFilename);

    public ChoreDatabaseService() { }

    public async Task InitializeAsync()
    {
        if (database is not null)
        {
            return;
        }

        database = new SQLiteAsyncConnection(DatabasePath, SQLiteOpenFlags.ReadWrite | SQLiteOpenFlags.Create | SQLiteOpenFlags.SharedCache);

        // Create the tables if they don't exist
        await database.CreateTableAsync<Chore>();
        await database.CreateTableAsync<CompletionRecord>();
        await database.CreateTableAsync<Tag>();
        await database.CreateTableAsync<ChoreTag>();
    }

    public Task<List<Chore>> GetActiveChoresAsync() => database.Table<Chore>().Where(c => c.IsActive).ToListAsync();

    public async Task<int> SaveChoreAsync(Chore chore)
    {
        var existing = await database.Table<Chore>()
                                     .Where(c => c.Name.ToLower() == chore.Name.ToLower())
                                     .FirstOrDefaultAsync();

        if (existing != null && existing.Id != chore.Id) return -1;

        return chore.Id != 0 ? await database.UpdateAsync(chore) : await database.InsertAsync(chore);
    }

    public Task<Chore> GetChoreAsync(int choreId) => database.Table<Chore>().Where(c => c.Id == choreId).FirstOrDefaultAsync();

    public async Task DeleteChoreAsync(Chore chore)
    {
        await database.DeleteAsync(chore);
        await database.Table<CompletionRecord>().Where(r => r.ChoreId == chore.Id).DeleteAsync();
        await database.Table<ChoreTag>().Where(c => c.ChoreId == chore.Id).DeleteAsync();
    }

    public async Task DeleteAllChoresAsync()
    {
        await database.DeleteAllAsync<Chore>();
        await database.DeleteAllAsync<CompletionRecord>();
    }

    public async Task AddCompletionRecordAsync(Chore chore, string note)
    {
        var record = new CompletionRecord
        {
            ChoreId = chore.Id,
            CompletedAt = DateTime.Now,
            Note = note
        };

        await database.InsertAsync(record);

        chore.LastCompleted = record.CompletedAt;
        chore.LastNote = record.Note;
        await database.UpdateAsync(chore);
    }

    public async Task DeleteCompletionRecordAsync(CompletionRecord completionRecord)
    {
        if (await database.DeleteAsync(completionRecord) > 0)
        {
            await UpdateChoreWithMostRecentRecord(completionRecord);
        }
    }

    public async Task DeleteCompletionRecordAsync(int recordId)
    {
        var record = await database.Table<CompletionRecord>()
                                   .Where(r => r.Id == recordId)
                                   .FirstOrDefaultAsync();
        if (record != null)
        {
            await DeleteCompletionRecordAsync(record);
        }
    }

    public Task<List<CompletionRecord>> GetHistoryAsync(int choreId)
    {
        return database.Table<CompletionRecord>()
                       .Where(r => r.ChoreId == choreId)
                       .OrderByDescending(r => r.CompletedAt)
                       .ToListAsync();
    }

    public async Task<int> CompleteChoreAsync(int choreId, string note)
    {
        var completionTime = DateTime.Now;

        var record = new CompletionRecord
        {
            ChoreId = choreId,
            CompletedAt = completionTime,
            Note = note
        };

        await database.InsertAsync(record);

        var chore = await GetChoreAsync(choreId);
        if (chore != null)
        {
            chore.LastCompleted = completionTime;
            chore.LastNote = record.Note;
            await database.UpdateAsync(chore);
        }

        return record.Id;
    }

    public async Task UpdateCompletionRecordAsync(CompletionRecord record)
    {
        if (await database.UpdateAsync(record) > 0)
        {
            await UpdateChoreWithMostRecentRecord(record);
        }
    }

    public async Task<(DateTime? lastCompleted, string? lastNote)> GetLastCompletionDetailsAsync(int choreId)
    {
        var lastRecord = await database.Table<CompletionRecord>()
                                        .Where(r => r.ChoreId == choreId)
                                        .OrderByDescending(r => r.CompletedAt)
                                        .FirstOrDefaultAsync();

        if (lastRecord == null)
        {
            return (null, null);
        }

        return (lastRecord.CompletedAt, lastRecord.Note);
    }

    public async Task<List<Tag>> GetTagsAsync() => await database.Table<Tag>().OrderBy(t => t.Name).ToListAsync();

    public async Task<int> SaveTagAsync(Tag tag)
    {
        var existing = await database.Table<Tag>()
                                     .Where(t => t.Name.ToLower() == tag.Name.ToLower())
                                     .FirstOrDefaultAsync();

        if (existing != null && existing.Id != tag.Id) return -1;

        return tag.Id != 0 ? await database.UpdateAsync(tag) : await database.InsertAsync(tag);
    }

    public async Task DeleteTagAsync(Tag tag)
    {
        await database.DeleteAsync(tag);
        await database.Table<ChoreTag>().Where(c => c.TagId == tag.Id).DeleteAsync();
    }

    public async Task<List<Tag>> GetTagsForChoreAsync(int choreId)
    {
        List<Tag> tags = [];
        List<ChoreTag> choreTags = await database.Table<ChoreTag>().Where(c => c.ChoreId == choreId).ToListAsync();
        foreach (var choreTag in choreTags)
        {
            Tag tag = await database.Table<Tag>().Where(t => t.Id == choreTag.TagId).FirstOrDefaultAsync();
            if (tag != null)
            {
                tags.Add(tag);
            }
        }

        return tags;
    }

    public async Task UpdateChoreTagsAsync(int choreId, IEnumerable<int> tagIds)
    {
        await database.Table<ChoreTag>().DeleteAsync(c => c.ChoreId == choreId);
        foreach(var tagId in tagIds)
        {
            await database.InsertAsync(new ChoreTag { ChoreId = choreId, TagId = tagId });
        }
    }

    private async Task UpdateChoreWithMostRecentRecord(CompletionRecord record)
    {
        var chore = await GetChoreAsync(record.ChoreId);
        if (chore == null) return;

        var (newLastCompleted, newLastNote) = await GetLastCompletionDetailsAsync(chore.Id);

        chore.LastCompleted = newLastCompleted;
        chore.LastNote = newLastNote ?? string.Empty;
        await database.UpdateAsync(chore);
    }
}
