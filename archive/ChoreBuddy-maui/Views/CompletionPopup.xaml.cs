using ChoreBuddy.Models;
using CommunityToolkit.Maui.Views;

namespace ChoreBuddy.Views;

public partial class CompletionPopup : Popup<CompletionRecord>
{
    public DateTime SelectedTimestamp => SelectedDate.Date + SelectedTime;
    public string TitleText { get; set; }
    public string ButtonText { get; set; }
    public string Note { get; set; }
    public DateTime SelectedDate { get; set; }
    public TimeSpan SelectedTime { get; set; }

    public CompletionPopup(
        string title,
        string buttonText,
        DateTime? initialDate = null,
        string initialNote = "",
        bool canBeDismissedByTappingOutsideOfPopup = false)
    {
        InitializeComponent();

        TitleText = title.ToUpper();
        ButtonText = buttonText.ToUpper();
        CanBeDismissedByTappingOutsideOfPopup = canBeDismissedByTappingOutsideOfPopup;

        var timestamp = initialDate ?? DateTime.Now;
        SelectedDate = timestamp.Date;
        SelectedTime = timestamp.TimeOfDay;
        Note = initialNote;

        BindingContext = this;
    }

    private async void OnCancelClicked(object sender, EventArgs e) => await CloseAsync();

    private async void OnSaveClicked(object sender, EventArgs e)
    {
        await CloseAsync(new CompletionRecord
        {
            CompletedAt = SelectedTimestamp,
            Note = Note ?? string.Empty
        });
    }
}