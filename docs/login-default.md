# Launch at Login default

User request: enable Launch at Login automatically for downloaded copies. A download cannot register itself; apply the default on the first launch from /Applications or the user's Applications directory. Use the existing supported SMAppService.mainApp API, not a launch agent, installer, or privileged helper.

Persist a per-user marker before the first automatic registration attempt. Existing enabled or approval-pending registrations need no second registration. Any later launch leaves the OS setting untouched, including if disabled through System Settings. Explicit toggles in the app also persist the marker before performing their action, so disabling before installation is respected. Registration failure is reported once and can be retried manually in Settings. Development/Downloads/translocated copies do not consume the default and do not register themselves. The default applies once on upgrade to 1.2 when no marker exists; earlier versions did not record explicit login choices.

Keep the toggle available, show enabled-by-default wording in setup/settings, and surface macOS approval requirements. Verify the once-only policy with isolated UserDefaults and injected registration actions, build a universal app, update the installed copy, and inspect actual registration status. Reboot/login behavior still needs a manual check.
