# Shaw Consulting branding — no Python or Node required

Artwork that you commit:

- `assets/icon.svg` — standalone icon, also suitable for an SVG favicon.
- `assets/text.svg` — standalone vector wordmark.

Generated (not committed): `assets/logo.svg`.

The shell builder places the two SVGs inside a self-contained combined SVG (nested
`<svg>` elements with explicit placement). It does *not* use an external `<image>`
reference, so ordinary `<img src="assets/logo.svg">` works in modern browsers,
including their restrictions on external resources from SVG-as-image contexts.
Both components retain their embedded light/dark CSS; the combined SVG remains
transparent and switches automatically under the browser's `color-scheme`.

## Requirements

- **Windows:** Git for Windows (includes Git Bash, `sh`, and `awk`). Run
  shell commands in **Git Bash**. No separate Python, Node, or SVG tools.
- **macOS:** A working Git installation, `/bin/sh`, and `awk`.
  New Macs may prompt to install Apple's Command Line Tools when first using Git.
- **Ubuntu 26.04+:** Git and standard POSIX shell tools.

This script is purpose-built for the committed `assets/icon.svg` and
`assets/text.svg` formats. It checks their `viewBox` values and fails if the
components' coordinate systems change, rather than guessing a new layout.
Unlike a full XML parser, the shell script assumes normal SVG opening tags.

## Local build

From the repository root (Git Bash on Windows):

```sh
sh scripts/build-logo.sh
```

Override the output filename if you want to generate directly into a site
build directory:

```sh
sh scripts/build-logo.sh _site/assets/logo.svg
```

The script writes atomically. When `cmp` happens to be available, it also avoids
rewriting an unchanged `logo.svg`.

## Automatic setup when opening in VS Code

VS Code is the expected editor for Shaw Consulting site development. The committed
`.vscode/tasks.json` declares **Brand: Initialize Git hooks and generate logo**
with `runOptions.runOn: folderOpen`. Once the developer trusts the workspace and
approves automatic tasks, the task runs after the project opens and on later
reopenings. It calls `scripts/setup-hooks.sh`, which enables the committed Git
hooks if they are not already installed and generates `assets/logo.svg`.

**First opening of a new clone:**

1. Open the repository folder in VS Code.
2. If VS Code shows a Restricted Mode / Trust banner, **Trust** this repository.
   Current VS Code releases may show a banner instead of an immediate dialog.
3. If VS Code asks whether to allow automatic tasks, review the task and select
   **Allow**. This is a user-wide setting affecting *all trusted workspaces*,
   not a permission solely for this repository.

You should not need to run a setup command. VS Code deliberately prevents a
repository from silently granting itself execution permission. If automatic
tasks were previously disallowed, use the Command Palette action **Tasks:
Manage Automatic Tasks**, or manually run the **Brand: Initialize Git hooks and
generate logo** task from **Tasks: Run Task**.

The task's executable is `git`, not `sh` or `bash`. It uses a temporary Git
shell alias to invoke the portable script. Git for Windows supplies its own
shell, so this avoids requiring Git Bash to be the editor's default terminal
or available as `sh` on the Windows system PATH. `git` must be runnable from
VS Code's task environment (just as it must be available for normal Git work).
No permanent aliases or global Git settings are installed; `core.hooksPath`
is set **locally for this clone**.

**Regeneration:** The folder-open task rebuilds the logo each time the project
opens. The installed Git hooks also rebuild it before commits and after Git
checkout, merge, or rewrite. The script avoids unnecessary rewrites when the
output hasn't changed. VS Code has no built-in task trigger on ordinary file
saves; if you need to preview an artwork change before committing, run **Tasks:
Run Task → Brand: Regenerate logo**, or run the build command manually. The
GitHub Pages workflow builds the deployed logo independently on every push to
`main`, regardless of local configuration.

**Manual fallback** (Git Bash on Windows, Terminal on macOS/Linux):

```sh
sh scripts/setup-hooks.sh
```

The setup refuses to replace an existing custom `core.hooksPath` so it cannot
silently break an existing hook manager. If another hook manager is in use,
chain `sh scripts/build-logo.sh` into that manager instead.

## GitHub Pages

`.github/workflows/deploy.yml` rebuilds the combined logo **during every
push to `main`**, packages it alongside the site, and deploys it using the
GitHub Pages Actions workflow. Neither the generated SVG nor the `_site/`
staging directory is committed.

The included workflow assumes your checked-in website is under `site/`.
If your current site uses a framework or a different output directory,
replace the `cp -R site/. _site/` step with its normal build command. Keep
`sh scripts/build-logo.sh _site/assets/logo.svg` (adjust the destination
according to your actual asset pipeline) before `upload-pages-artifact`.

In GitHub repository Settings > Pages, choose **GitHub Actions** as the
build/deployment source. For existing Pages projects, integrate this build step
into their existing deploy workflow rather than creating competing workflows.

## HTML

```html
<link rel="icon" type="image/svg+xml" href="assets/icon.svg">
<img src="assets/logo.svg" alt="Shaw Consulting" width="420">
```

Use document-relative asset paths for GitHub Pages project sites, rather than
assuming the site always lives at the domain root.

## Dark mode

For an OS-driven website theme:

```css
:root { color-scheme: light dark; }
```

For a custom theme switcher, set `color-scheme: light` or `dark` on your HTML
root in sync with the selected theme. Print workflows and SVG converters may
ignore the media query, in which case export a static palette variant.
