# Keys

<img src="keys-1024.png" width="128" alt="App icon">

A small macOS menu bar app that lets you make keys do more — change what a key does, paste frequently used text with a few keystrokes, switch languages with one key, or show your keystrokes on screen.

<img src="web/screenshot.webp" alt="Screenshot">

<video src="web/show-keystrokes.mp4" width="800" autoplay loop muted playsinline></video>

## What it can do

- **Remap keys** — turn one key (or a key combination, or a double-tap) into another, or into a special action
- **Switch keyboard language with one key** — e.g. press Caps Lock to flip between English and Russian
- **Snippet picker** — press a key to open a floating window, type a few letters, and paste a saved piece of text
- **Keystroke overlay** — display each key you press on screen (handy for videos and demos)
- **Plain text config** — everything lives in one text file, and changes apply automatically — no restart needed

## Requirements

- macOS 15 (Sequoia) or later

## Install

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/vladstudio/keys/main/install.sh)"
```

On first launch, macOS will ask you to grant **Accessibility** and **Input Monitoring** access in System Settings. Keys needs these to see your keystrokes. This is normal and safe — the data never leaves your Mac.

<details>
<summary>What does the install script do?</summary>

- Downloads the latest release from GitHub
- Installs to /Applications (replaces any existing version)
- Removes the quarantine flag so the unsigned app can run
- Opens the app

</details>

## Configuration

All settings live in a text file: `~/.config/keys/keys.conf`. Open it in any text editor (TextEdit, VS Code, etc.). Changes are picked up automatically as soon as you save.

```
[remap]
caps_lock: toggle_input
option+shift+a: control+b
control, control: snippets

[snippet]
Hello world
em: my.email@example.com
"Best regards,
Steve"
```

The file has two kinds of sections: `[remap]` for changing what keys do, and `[snippet]` for saved text.

### Remaps

Each line changes one key (or combination): `input: output`.

- **Combination**: join with `+` — `option+shift+a: control+b`
- **Double-tap**: join with `, ` — `control, control: snippets`

**Special things a key can do:**

| Output | What it does |
|--------|--------------|
| `snippets` | Open the snippet picker |
| `toggle_input` | Cycle through your keyboard languages (e.g. English → Russian → English) |
| `open(Safari)` | Launch an app |
| `bash(say hello)` | Run a shell command |
| `paste(Hello!)` | Paste the given text |
| `ignore` | Turn the key off completely |

**A note on Caps Lock:** if you remap Caps Lock to another real key (like `f20`), also set Caps Lock to **"No Action"** in *System Settings → Keyboard → Modifier Keys* so the two don't conflict.

### Snippets

Each line is a piece of text you can paste later. For multi-line text, or text containing a `:`, wrap it in double quotes:

```
"Best regards,
Steve"
```

You can give a snippet a short keyword to find it faster:

```
em: my.email@example.com
```

In the snippet picker, type to filter, use arrow keys to move, **Enter** to paste, **Escape** to close. Search is fuzzy and forgiving — typing `jd` will find `john@doe.com`.

### Key names

`a`–`z`, `0`–`9`, `f1`–`f20`, `return` (or `enter`), `tab`, `space`, `delete`, `escape`, `caps_lock`, `forward_delete`, `up`, `down`, `left`, `right`, `minus`, `equal`, `left_bracket`, `right_bracket`, `backslash`, `semicolon`, `quote`, `grave`, `comma`, `period`, `slash`, `shift`, `control`, `option`, `command` (and `right_*` variants).

**Media keys** (input only): `brightness_up`, `brightness_down`, `volume_up`, `volume_down`, `mute`, `play`, `next`, `previous`, `illumination_up`, `illumination_down`.

---

License: MIT
