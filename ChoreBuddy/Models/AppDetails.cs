namespace ChoreBuddy.Models;

public record AppDetails(
    string Name,
    string Version,
    string Build,
    string PackageName,
    string DatabasePath
);

//public partial class AppDetails(
//    string AppName,
//    string Version,
//    string Build,
//    string PackageName,
//    string DatabasePath) : BindableObject
//{
//    public string AppName { get; } = AppName;
//    public string Version { get; } = Version;
//    public string Build { get; } = Build;
//    public string PackageName { get; } = PackageName;
//    public string DatabasePath { get; } = DatabasePath;
//}
