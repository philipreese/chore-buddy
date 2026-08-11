using System.Linq.Expressions;

namespace ChoreBuddy.Services.Data;

public interface IRepository<T> where T : class, new()
{
    Task<List<T>> GetAllAsync();
    Task<List<T>> GetAsync(Expression<Func<T, bool>> predicate);
    Task<T?> GetByIdAsync(int id);
    Task<int> InsertAsync(T entity);
    Task<int> UpdateAsync(T entity);
    Task<int> DeleteAsync(T entity);
    Task<int> DeleteAllAsync();
    Task RunInTransactionAsync(Action<SQLite.SQLiteConnection> action);
    Task<List<TModel>> QueryAsync<TModel>(string sql, params object[] args) where TModel : new();
}
