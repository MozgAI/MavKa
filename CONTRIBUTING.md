# Contributing to MavKa

Thanks for thinking about contributing! MavKa is small and welcoming.

## Quick rules

- One PR, one thing. Don't bundle unrelated changes.
- Test on your machine before opening a PR. Mention OS + arch in the description.
- Keep the script readable. No dependency on bash 4 features (macOS still ships bash 3.2).
- Be honest in commit messages. "Fix X" beats "Various improvements."

## What's most useful right now

- Test on a fresh Linux distro and report what broke
- Test on Windows WSL2 and confirm it works (or doesn't)
- Better error messages in `install.sh`
- Translations in the i18n section
- Demo GIF for the README

## Things I'm NOT looking for yet

- Big architectural rewrites
- New AI providers (let's stabilize DeepSeek path first)
- Web UI (the whole point is "Telegram is the UI")

## Reporting bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). Include logs.

## Security issues

Don't open public issues. Email **lytvynca@gmail.com** with subject `[MavKa Security]`. See [SECURITY.md](SECURITY.md).
