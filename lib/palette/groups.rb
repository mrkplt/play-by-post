# typed: false
# frozen_string_literal: true

# The colour data for Palette, split out so lib/palette.rb stays under the
# file-length ceiling. GROUPS is an ordered list of [heading, { token => hex }]
# pairs; the heading comments are reproduced in the generated @theme CSS so it
# reads like the original hand-written block. Edit colours HERE.
module Palette
  module Groups
    ALL = [
    [ "Ink & canvas", {
      "ink" => "#1a1a1a",
      "canvas" => "#fafafa",
    } ],
    [ "Dark surfaces (header bars, drawer)", {
      "sidebar-bg" => "#2b2d31",       # header bars
      "drawer-bg" => "#1a1b1e",        # nav drawer / darkest surface
      "sidebar-text" => "#cdd1d9",
      "sidebar-border" => "#3d3f45",
      "sidebar-hover" => "#3a3c42",
      "pill-idle" => "#3a3c42",        # inactive pill tab background
    } ],
    [ "Accent (gold)", {
      "accent" => "#c8a96e",
      "accent-ink" => "#1a1a1a",       # text on gold surfaces
    } ],
    [ "Light card surfaces", {
      "card" => "#ffffff",
      "card-border" => "#e8e6e1",
      "card-divider" => "#f0eee9",
      "input-border" => "#d8d5cd",     # warm border on text inputs / textareas
    } ],
    [ "Muted greys", {
      "muted" => "#8a8d94",            # labels, meta
      "muted-2" => "#9aa0ab",          # tertiary meta
      "body-ink" => "#2a2a2a",         # post body text
      "row-ink" => "#5c5e63",          # row secondary text
    } ],
    [ "Sodalite/azurite blue — retired / OOC / banned tint", {
      "tint-blue-bg" => "#e6ebf4",
      "tint-blue-border" => "#c7d2e6",
      "tint-blue-strong" => "#2a4570",
      "tint-blue-soft" => "#4d6690",
    } ],
    [ "Danger (ban / cancel / unban)", {
      "danger" => "#9c3a3a",
      "danger-soft" => "#7a3a3a",
    } ],
    [ "Avatar initials backgrounds (non-blue tones; blue reuses tint)", {
      "avatar-muted" => "#c2beb6",     # warm grey avatar
      "avatar-blue" => "#94a8c9",      # blue avatar
    } ],
    [ "Badge tones — dark chip backgrounds with tinted text/border", {
      "badge-danger-bg" => "#3a1717",
      "badge-danger-text" => "#e28a8a",
      "badge-danger-border" => "#5c2121",
      "badge-gold-bg" => "#3a3020",
      "badge-gold-text" => "#e2c48a",
      "badge-gold-border" => "#5c4a2c",
    } ],
    [ "Toast surfaces — light chips overlaid on content", {
      "toast-success-bg" => "#e7f4ec",
      "toast-success-text" => "#1f5133",
      "toast-success-border" => "#bcdcc9",
      "toast-error-bg" => "#fbeaea",
      "toast-error-text" => "#7a2626",
      "toast-error-border" => "#e6c3c3",
    } ],
    [ "OOC filter toggle indicator (Stimulus reads these via utility classes)", {
      "toggle-on" => "#16a34a",        # green "✓ On" text
      "toggle-off" => "#94a3b8",       # grey "Off" text
    } ],
    [ "Neutral slate scale — collected from raw Tailwind slate-* utilities "\
      "(surfaces, borders, and meta text on forms/galleries/breadcrumbs) "\
      "pending design-system dispensation", {
      "surface-50" => "#f8fafc",       # was slate-50  — faint panel fill
      "surface-100" => "#f1f5f9",      # was slate-100 — chip / code fill
      "surface-200" => "#e2e8f0",      # was slate-200 — light divider fill
      "line-200" => "#e2e8f0",         # was border-slate-200 — hairline border
      "line-300" => "#cbd5e1",         # was border-slate-300 — stronger border
      "meta-400" => "#94a3b8",         # was slate-400 — faint meta text
      "meta-500" => "#64748b",         # was slate-500 — meta text
      "meta-600" => "#475569",         # was slate-600 — secondary body text
      "meta-700" => "#334155",         # was slate-700 — body text on light
    } ],
    [ "Error/danger form states — collected from raw Tailwind red-* utilities "\
      "(inline validation on forms) pending design-system dispensation", {
      "error-bg" => "#fef2f2",         # was red-50  — error panel fill
      "error-border" => "#fecaca",     # was red-200 — error panel border
      "error-border-strong" => "#fca5a5", # was red-300 — stronger error border
      "error-text" => "#dc2626",       # was red-600 — error text / delete
      "error-text-strong" => "#991b1b", # was red-800 — error text on light fill
    } ],
    [ "Status-badge light tones — collected from raw Tailwind *-100/*-800 "\
      "utilities on Ui::BadgeComponent pending design-system dispensation", {
      "status-warn-bg" => "#fef9c3",   # was yellow-100
      "status-warn-text" => "#854d0e", # was yellow-800
      "status-neutral-bg" => "#f1f5f9", # was slate-100
      "status-neutral-text" => "#475569", # was slate-600
      "status-ok-bg" => "#dcfce7",     # was green-100
      "status-ok-text" => "#166534",   # was green-800
      "status-info-bg" => "#dbeafe",   # was blue-100
      "status-info-text" => "#1e40af", # was blue-800
    } ],
    [ "Scene summary surfaces — collected from raw Tailwind utilities pending "\
      "design-system dispensation (see Fizzy: detokenize summaries)", {
      "summary-amber-bg" => "#fffbeb",       # was bg-amber-50
      "summary-amber-border" => "#fde68a",   # was border-amber-200
      "summary-amber-heading" => "#78350f",  # was text-amber-900
      "summary-amber-meta" => "#b45309",     # was text-amber-700
      "summary-amber-body" => "#451a03",     # was text-amber-950
      "summary-slate-border" => "#e2e8f0",   # was border-slate-200
      "summary-slate-meta" => "#94a3b8",     # was text-slate-400
      "summary-slate-body" => "#334155",     # was text-slate-700
      "summary-delete" => "#dc2626",         # was text-red-600
      "summary-delete-hover" => "#991b1b",   # was text-red-800
    } ],
    [ "Email — inline styles in mailer views (mail clients can't use Tailwind)", {
      "mail-meta" => "#64748b",        # muted meta text in emails
      "mail-action" => "#1e40af",      # primary button background in emails
      "mail-rule" => "#e2e8f0",        # divider / left border in digests
    } ],
  ].freeze
  end
end
