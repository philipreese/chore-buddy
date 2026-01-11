using ChoreBuddy.Services;
using CommunityToolkit.Maui.Storage;
using Microsoft.Maui.ApplicationModel.DataTransfer;
using Microsoft.Maui.Storage;

namespace ChoreBuddy.Services;

public class MigrationService
{
    private readonly SettingsService settingsService;
    private readonly ChoreDatabaseService databaseService;
    private const string DatabaseName = "ChoreBuddy.db3";

    public MigrationService(ChoreDatabaseService dbService, SettingsService settingsService)
    {
        databaseService = dbService;
        this.settingsService = settingsService;
    }

    public async Task<bool> ExportDatabase()
    {
        try
        {
            string sourcePath = Path.Combine(FileSystem.AppDataDirectory, DatabaseName);
            if (!File.Exists(sourcePath))
            {
                return false;
            }
            await databaseService.FlushDatabaseAsync();
            using var sourceStream = File.OpenRead(sourcePath);

            string fileName = $"ChoreBuddy_Backup_{DateTime.Now:yyyyMMdd_HHmmss}.db3";
            var fileSaverResult = await FileSaver.Default.SaveAsync(
                fileName,
                sourceStream,
                CancellationToken.None);

            if (fileSaverResult.IsSuccessful)
            {
                settingsService.LastBackupDate = DateTime.Now;
                return true;
            }
            else
            {
                return false;
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Export failed: {ex.Message}");
            return false;
        }
    }

    public async Task<bool> ImportViaPicker()
    {
        try
        {
            var result = await FilePicker.Default.PickAsync(new PickOptions
            {
                PickerTitle = "Select ChoreBuddy Backup File (.db3)",
            });

            if (result == null)
            {
                return false;
            }

            if (!result.FileName.EndsWith(".db3", StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            string mainDbPath = Path.Combine(FileSystem.AppDataDirectory, DatabaseName);
            string walPath = mainDbPath + "-wal";
            string shmPath = mainDbPath + "-shm";

            byte[] backupData;
            using (var stream = await result.OpenReadAsync())
            {
                if (stream.Length == 0) return false;
                using var ms = new MemoryStream();
                await stream.CopyToAsync(ms);
                backupData = ms.ToArray();
            }

            await databaseService.CloseConnection();
            GC.Collect();
            GC.WaitForPendingFinalizers();
            await Task.Delay(1000);

            using var sourceStream = await result.OpenReadAsync();
            if (sourceStream.Length <= 0)
            {
                return false;
            }

            if (File.Exists(mainDbPath)) File.Delete(mainDbPath);
            if (File.Exists(walPath)) File.Delete(walPath);
            if (File.Exists(shmPath)) File.Delete(shmPath);

            using (var targetStream = new FileStream(mainDbPath, FileMode.Create, FileAccess.Write, FileShare.None, 4096, FileOptions.WriteThrough))
            {
                await sourceStream.CopyToAsync(targetStream);
                await targetStream.FlushAsync();
            }

            System.Diagnostics.Debug.WriteLine($"[Migration] Successfully imported {backupData.Length} bytes.");

            await databaseService.InitializeAsync();
            return true;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Import failed: {ex.Message}");
            return false;
        }
    }
}