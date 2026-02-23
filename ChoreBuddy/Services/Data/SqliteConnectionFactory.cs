using ChoreBuddy.Models;
using SQLite;

namespace ChoreBuddy.Services.Data;

public class SqliteConnectionFactory : ISqliteConnectionFactory
{
    private SQLiteAsyncConnection? database;
    private const string DatabaseFilename = "ChoreBuddy.db3";
    
    public static string DatabasePath => Path.Combine(FileSystem.AppDataDirectory, DatabaseFilename);

    public async Task<SQLiteAsyncConnection> GetConnectionAsync()
    {
        if (database is not null)
        {
            return database;
        }

        database = new SQLiteAsyncConnection(DatabasePath, SQLiteOpenFlags.ReadWrite | SQLiteOpenFlags.Create);

        // Create the tables if they don't exist
        await database.CreateTableAsync<Chore>();
        await database.CreateTableAsync<CompletionRecord>();
        await database.CreateTableAsync<Tag>();
        await database.CreateTableAsync<ChoreTag>();

        await database.ExecuteScalarAsync<string>("PRAGMA journal_mode=WAL;");

        return database;
    }

    public async Task FlushDatabaseAsync()
    {
        if (database == null) return;

        // Full checkpoint ensures all transactions are written to the main file
        await database.ExecuteScalarAsync<int>("PRAGMA wal_checkpoint(FULL);");
    }

    public async Task CloseConnectionAsync()
    {
        if (database != null)
        {
            await database.CloseAsync();
            database = null;
        }
    }
}
