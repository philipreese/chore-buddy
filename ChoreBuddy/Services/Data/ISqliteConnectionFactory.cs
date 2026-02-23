using SQLite;

namespace ChoreBuddy.Services.Data;

public interface ISqliteConnectionFactory
{
    Task<SQLiteAsyncConnection> GetConnectionAsync();
    Task CloseConnectionAsync();
    Task FlushDatabaseAsync();
}
