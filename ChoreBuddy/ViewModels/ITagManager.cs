using ChoreBuddy.Models;
using CommunityToolkit.Mvvm.Input;

namespace ChoreBuddy.ViewModels;

public interface ITagManager
{
    IAsyncRelayCommand<Tag> ToggleTagCommand { get; }
}
