# MavKa Personas

Five personalities the user can pick at first install. Each persona is a complete identity: name, character, symbolism, avatar, and a tight system prompt.

## Files

- `personas.json` — manifest of all 5 (consumed by installer + bot UI)
- `<id>/avatar.png` — square 512×512 portrait used in `/start` carousel and as a downloadable file the user can save to their TG profile
- `<id>/prompt.md` — short system prompt (~50–60 tokens) loaded into the bot's context once

## The five

| Display | Vibe | Color | Look |
|---------|------|-------|------|
| Atlas✨ | The strategist — cuts through noise, finds the pattern | blue | brunette |
| 🌙MoOn | The know-it-all — warm sage, loves to share | yellow | blonde |
| MavKa🍃 | The loyal friend — wise, honest, never lets you down | green | brunette |
| 🪩Echo | The analyst — lawyer with fresh data, reads between the lines | silver | white/silver hair |
| Moz!🦊 | The adventurer — restless, burns with ideas, growth-driven | orange | redhead |

## Install flow

1. `install.sh` finishes setup → bot launches
2. First `/start` → bot posts each avatar with its name + one-line description
3. User picks one (inline button) → bot writes `~/.mavka/persona.json` with the chosen `id`
4. Bot loads matching `prompt.md` as its system prompt for the rest of its life
5. Bot offers to send the avatar PNG so the user can set it as their own TG profile photo (optional)

## Naming rules — strict

Display names are written **without spaces** between text and emoji, and case matters:

- `Atlas✨` (emoji after)
- `🌙MoOn` (emoji before, capital M and O)
- `MavKa🍃` (emoji after, capital M and K)
- `🪩Echo` (emoji before)
- `Moz!🦊` (emoji after, exclamation is part of the name)

## Status

- [x] Manifest schema
- [x] Square 512×512 avatars (originals kept as `avatar-original.png`)
- [x] One-sentence personalities + ~50–60 token prompts
- [x] Banner / social preview
- [ ] Selection UI in installer/bot (`pi-telegram` extension)
- [ ] Hot-swap between personas (post-MVP)
