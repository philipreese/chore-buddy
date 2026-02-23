using System.Linq.Expressions;
using SQLite;

namespace ChoreBuddy.Services.Data;

public class SqliteRepository<T>(ISqliteConnectionFactory connectionFactory)
    : IRepository<T> where T : class, new()
{
    private readonly ISqliteConnectionFactory connectionFactory = connectionFactory;

    private async Task<SQLiteAsyncConnection> GetConnectionAsync()
    {
        return await connectionFactory.GetConnectionAsync();
    }

    public async Task<List<T>> GetAllAsync()
    {
        var db = await GetConnectionAsync();
        return await db.Table<T>().ToListAsync();
    }

    public async Task<List<T>> GetAsync(Expression<Func<T, bool>> predicate)
    {
        var db = await GetConnectionAsync();
        return await db.Table<T>().Where(predicate).ToListAsync();
    }

    public async Task<T?> GetByIdAsync(int id)
    {
        var db = await GetConnectionAsync();
        // Fallback to table query if mapping is simple
        return await db.Table<T>().Where(BuildIdPredicate(id)).FirstOrDefaultAsync();
    }

    public async Task<int> InsertAsync(T entity)
    {
        var db = await GetConnectionAsync();
        return await db.InsertAsync(entity);
    }

    public async Task<int> UpdateAsync(T entity)
    {
        var db = await GetConnectionAsync();
        return await db.UpdateAsync(entity);
    }

    public async Task<int> DeleteAsync(T entity)
    {
        var db = await GetConnectionAsync();
        return await db.DeleteAsync(entity);
    }

    public async Task<int> DeleteAllAsync()
    {
        var db = await GetConnectionAsync();
        return await db.DeleteAllAsync<T>();
    }

    public async Task<List<TModel>> QueryAsync<TModel>(string sql, params object[] args) where TModel : new()
    {
        var db = await GetConnectionAsync();
        return await db.QueryAsync<TModel>(sql, args);
    }

    public async Task RunInTransactionAsync(Action<SQLiteConnection> action)
    {
        var db = await GetConnectionAsync();
        await db.RunInTransactionAsync(action);
    }
    
    // SQLite-net PCL relies on reflection mapping for primary keys. 
    // To keep the repository generic but allow GetById, we build a dynamic Expression tree to match "Id == id".
    private static Expression<Func<T, bool>> BuildIdPredicate(int id)
    {
        var parameter = Expression.Parameter(typeof(T), "x");
        var property = Expression.Property(parameter, "Id");
        var constant = Expression.Constant(id);
        var equal = Expression.Equal(property, constant);
        return Expression.Lambda<Func<T, bool>>(equal, parameter);
    }
}
