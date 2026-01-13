using ChoreBuddy.Models;
using Plugin.LocalNotification;

namespace ChoreBuddy.Services;

public class NotificationService
{
    private readonly SettingsService settingsService;

    public NotificationService(SettingsService settingsService)
    {
        this.settingsService = settingsService;
    }

    public async Task<bool> RequestPermissions()
    {
        bool isEnabled = await LocalNotificationCenter.Current.AreNotificationsEnabled();

        if (!isEnabled)
        {
            return await LocalNotificationCenter.Current.RequestNotificationPermission();
        }

        return true;
    }

    public void ScheduleChoreNotification(Chore chore)
    {
        CancelChoreNotification(chore?.Id ?? 0);

        if (!settingsService.IsGlobalNotificationsEnabled)
        {
            return;
        }

        if (chore == null || !chore.NextDueDate.HasValue || !chore.IsNotificationEnabled)
        {
            return;
        }

        if (chore!.NextDueDate!.Value < DateTime.Now)
        {
            return;
        }

        var request = new NotificationRequest
        {
            NotificationId = chore.Id,
            Title = "Mission Alert: " + chore.Name,
            Description = "It's time to engage your next mission.",
            BadgeNumber = 1,
            Schedule = new NotificationRequestSchedule
            {
                NotifyTime = chore.NextDueDate.Value,
                RepeatType = NotificationRepeat.No
            }
        };

        LocalNotificationCenter.Current.Show(request);
    }

    public void CancelChoreNotification(int choreId)
    {
        if (choreId <= 0)
        {
            return;
        }

        LocalNotificationCenter.Current.Cancel(choreId);
    }

    public void CancelAllNotifications()
    {
        LocalNotificationCenter.Current.CancelAll();
    }
}