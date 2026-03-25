# BF6 Chat Input Fix — Windows 11 Text Services Framework Hijack

## The Bug

When playing **Battlefield 6** on **Windows 11 (24H2+)**, pressing `Enter` to open in-game chat results in:

- Chat window opens and focuses (upper-left corner) ✅
- **Keyboard input doesn't register** — no characters appear ❌
- **`Esc` does not close the chat** ❌
- **Only a left-mouse click** exits the chat and returns to gameplay

This affects all chat types (team, squad, all). Reinstalling the game, unplugging/replacing keyboards, and updating drivers does not fix it.

## Root Cause

This is **not a Battlefield 6 bug**. It's a **Windows 11 input stack regression**.

Two system processes are responsible:

| Process | Role | Problem |
|---|---|---|
| `TextInputHost.exe` | Windows 11 modern text input framework (emoji picker, IME, touch keyboard) | Detects BF6's chat text field and hooks into the keyboard pipeline |
| `ctfmon.exe` | Collaborative Translation Framework loader | Manages text services; feeds input to TextInputHost |

### What happens step by step:

1. BF6 gameplay uses **Raw Input** — direct keyboard capture. Works perfectly.
2. Player presses `Enter` → game opens a **Win32 text control** for chat input.
3. Windows 11's Text Services Framework (TSF) detects the text control and **activates `TextInputHost.exe`** to manage it.
4. `TextInputHost.exe` **consumes all keyboard events** before BF6's chat field receives them.
5. `Esc` is also a keyboard event → also consumed. The player is stuck.
6. Mouse input uses a separate pipeline → left-click still reaches the game, which closes chat.

This regression was introduced in **Windows 11 24H2** where Microsoft made the modern input stack more aggressive about hooking text fields in DirectX applications.

## The Fix

Kill `TextInputHost.exe` and `ctfmon.exe` before launching the game. Both processes auto-restore after the gaming session ends.

### Quick Fix (already in-game)

If you're already in a match and chat is broken, Alt-Tab out and run as **Administrator**:

```powershell
powershell -ExecutionPolicy Bypass -File fix-bf6-chat-now.ps1
```

Alt-Tab back to BF6. Chat should work immediately.

### Full Launcher (recommended)

Kills both processes, launches BF6, monitors for respawns every 3 seconds, and restores everything when you close the game:

```powershell
powershell -ExecutionPolicy Bypass -File launch-bf6-chatfix.ps1
```

Requires **Administrator** privileges (needed to kill system processes).

### Auto-Elevating Desktop Shortcut (set-and-forget)

Run this **once** to create a desktop shortcut that launches with admin privileges and no UAC prompt:

```powershell
powershell -ExecutionPolicy Bypass -File create-bf6-shortcut.ps1
```

This creates a Scheduled Task (`BF6_ChatFix_Launcher`) that runs as admin, and a desktop shortcut that triggers it.

> **Note:** Edit the `$BF6Path` variable in `launch-bf6-chatfix.ps1` and the `$BF6Icon` variable in `create-bf6-shortcut.ps1` to match your BF6 install path. Look for the `CONFIGURE THIS` comments at the top of each script.

## What DICE/EA Could Do

This is fixable on the engine side. Any of these would work:

1. **Use Raw Input for chat** — Don't switch to a Win32 text control. Capture keystrokes via the same Raw Input pipeline used for gameplay and render the text buffer directly. This is what Source engine (CS2) and id Tech games do.
2. **Call `ITfThreadMgr::Deactivate()`** — The TSF API provides a function to tell the framework "don't manage this thread's text input." One API call when chat opens, reactivate on close.
3. **Set `DISALLOW_TSFATTACH`** — A window property (`TF_DISABLE_TSFATTACH`) that tells TSF to leave a specific `HWND` alone.

All three are minimal changes — likely under 20 lines of code in Frostbite's UI layer.

## Affected Systems

- **OS:** Windows 11 24H2+ (build 26100+)
- **Game:** Battlefield 6 (all versions as of March 2026)
- **Not affected:** Windows 10, Windows 11 23H2 and earlier

## Permanent Alternatives

If you'd rather not run a script every time:

| Fix | How | Trade-off |
|---|---|---|
| **Legacy input switcher** | Settings → Time & Language → Typing → Advanced keyboard settings → "Use the desktop language bar when it's available" | Minimal — old-style language bar icon |
| **IFEO block** | Registry key that permanently prevents `TextInputHost.exe` from launching | Loses Win+. emoji picker and touch keyboard |
| **Disable CTF Loader task** | Disable `TextServicesFramework` in Task Scheduler | Could affect non-English input methods |

## License

MIT — do whatever you want with this. If it helps you, consider sharing it.
