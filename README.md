# dlink-dst

Set the Daylight Saving flag on a D-Link DIR-878 (FW 1.10) to match your
local timezone.

The stock firmware has no named timezones — just a fixed UTC offset and a
manual "Daylight Saving" checkbox. Anything tied to the router clock (like a
port-forward schedule) drifts an hour at every DST transition until you flip
that checkbox by hand. This script flips it for you.

## How it works

Uses the router's HNAP1 SOAP API (the same one the web UI uses):

1. Two-step HMAC-MD5 challenge-response login (`/HNAP1/`)
2. `GetTimeSettings` to read the current `DaylightSaving` flag
3. `SetTimeSettings` to change it — only if it is already wrong

Python 3.10+ standard library only. No dependencies.

## Usage

```
dlink-dst status   show router time settings and local DST state
dlink-dst on       enable DaylightSaving
dlink-dst off      disable DaylightSaving
dlink-dst auto     set to match the local timezone's DST state
```

`--ip` overrides the router address (default `192.168.0.1`).

The admin password is read, in order, from the `DLINK_PASSWORD` env var, a
TTY prompt, or stdin (`echo secret | dlink-dst auto`). It is never stored.

## systemd system service + timer

`install.sh` installs a system-wide systemd unit (requires root) that runs
`dlink-dst auto` at the two DST transitions (second Sunday of March, first
Sunday of November), a minute after the clock change:

```
./install.sh        # prompts for the router admin password
```

It copies `dlink-dst` to `/usr/local/bin/`, renders `dlink-dst.service` with
your password into `/etc/systemd/system/` (mode 600), installs
`dlink-dst.timer`, and enables it. The password lives only in the rendered
unit, not in this repo.

```
systemctl status dlink-dst.timer
```

By default the systemd timer is configured for montreal/north america, other
regions may have to tweak the schedule.

`auto` is idempotent, so a late run (host was asleep; `Persistent=true`) is
harmless.
