# Family Onboarding Checklist

Repeatable steps for setting up a new family member with access to
Nextcloud, both on the home network and remotely via Tailscale.

## Part A — Admin side (done by you, before handing anything over)

1. Create their Nextcloud account: **Nextcloud → Users → New account**,
   assign to the `family` group, set a reasonable quota.
2. Note down their exact **Username** (not display name) — this is
   what they log in with, along with their password.
3. Invite them to the Tailscale tailnet: **Tailscale admin console →
   Users → Invite member** → their personal email → they accept using
   their own account.

## Part B — Their side, on each device

### Home network access (DNS)

**Windows**
Settings → Network & Internet → Wi-Fi → your network → Edit DNS
settings → Manual → set Preferred DNS to `192.168.1.240`.

**Android**
Wi-Fi network → Modify network → IP settings → Static → set DNS 1 to
`192.168.1.240`.
Then, separately: Settings → Connections → More connection settings →
Private DNS → set to **Off**. (Easy to miss — Private DNS silently
overrides the manual DNS setting above if left on Automatic.)

**Debian/Linux (NetworkManager)**

    sudo nmcli connection modify "<connection-name>" ipv4.dns "192.168.1.240"
    sudo nmcli connection modify "<connection-name>" ipv4.ignore-auto-dns yes
    sudo nmcli connection up "<connection-name>"

**iOS**
Not yet tested in this project. Verify and update this section if a
family member uses an iPhone.

### Remote access (Tailscale)

1. Install the Tailscale app for their device's OS.
2. Accept the tailnet invite email, log in with their own account.
3. **Linux only:** also run `sudo tailscale up --accept-routes` — this
   is not automatic on Linux, unlike Windows/Android/iOS.

### Nextcloud app

1. Install the Nextcloud app.
2. Server address: `nextcloud.home.lab`
3. Log in with their **Username** (not display name) and password.

## Part C — Verify

- [ ] Login works on home Wi-Fi
- [ ] Login works with Wi-Fi off, on cellular/mobile data, via Tailscale

## Notes

- Static IP conflicts are a small residual risk since the ISP router's
  DHCP range can't be restricted — pick device IPs from the high end
  of the range (e.g. `.245` and up) to minimize collision chance.
- Each family member's Tailscale login is their own — access can be
  revoked individually per person from the admin console if ever
  needed, without affecting anyone else.
