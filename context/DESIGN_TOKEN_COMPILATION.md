# Arbitrary-hex Tailwind utilities do not compile from `.rb`/`.js` — use `@theme` tokens

## The bug this documents (Fizzy #59)

The profile "Hide OOC by default" toggle shipped **invisible** — the switch track
had no background colour. Same latent break affected `Ui::AvatarComponent`
(dark/muted/blue tones) and `Ui::BadgeComponent` (slate/danger/goldish tones).

Root cause: those components applied Tailwind **arbitrary-value colour utilities**
written as raw hex — `bg-[#3a3c42]`, `text-[#e28a8a]`, `border-[#5c2121]`, etc. —
from **Ruby string literals** (component tone tables) and one **JS** Stimulus
controller (`ooc_filter_controller.js`).

Tailwind CSS v4's content scanner extracts candidate class names from scanned
files, but it does **not reliably pull arbitrary-value utilities out of Ruby/JS
string literals**. So `.bg-[#3a3c42]` was never emitted into
`app/assets/builds/tailwind.css` (verified: **0** occurrences in the built CSS,
vs. `.bg-accent` which compiled fine because it is a real token utility used in
ERB). No CSS rule → no background → the control renders transparent.

Confirmed for every arbitrary-hex utility that lived in a `.rb`/`.js` file: all
compiled to **0** rules.

## The rule

**Never write an arbitrary-hex colour utility (`bg-[#…]`, `text-[#…]`,
`border-[#…]`, …) anywhere in app source.** Define a named colour in the
`@theme` block of `app/assets/tailwind/application.css`
(`--color-<name>: #hex;`) and use the token utility (`bg-<name>`).

This holds in ERB too (an arbitrary hex there bypasses the design system), but
in `.rb`/`.js` it is strictly worse: the class silently never compiles.

## Why the gate did not catch it

`bin/check-design-tokens` originally scanned **only ERB** and deliberately
excluded `.rb`/`.js` — the (wrong) reasoning being that component Ruby tone
tables were "the sanctioned home for the raw palette." They were not sanctioned;
they were silently broken. The gate now scans `app/components/**/*.rb` and
`app/javascript/**/*.js` in addition to ERB, so a raw-hex utility in any of them
fails the build.

`@theme` token **definitions** in the Tailwind stylesheet
(`--color-x: #hex`) are the one sanctioned home for raw hex and are not scanned.

## Workflow when adding a colour

1. Add `--color-<name>: #hex;` to the `@theme` block in
   `app/assets/tailwind/application.css`.
2. Use `bg-<name>` / `text-<name>` / `border-<name>` in the component.
3. Rebuild: `bin/rails tailwindcss:build` (regenerates
   `app/assets/builds/tailwind.css`).
4. Verify the utility compiled:
   `grep -oF '.bg-<name>' app/assets/builds/tailwind.css` returns ≥1.
5. `bin/check-design-tokens` must pass.
