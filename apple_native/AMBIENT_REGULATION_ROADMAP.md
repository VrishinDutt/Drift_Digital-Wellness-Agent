# Drift Ambient Regulation Layer Roadmap

Project: Drift_Digital-Wellness-Agent
Product: Drift

Core principle: Attention state > screen time.

This is a disciplined roadmap, not a single implementation sprint. Each phase must preserve privacy, reduce decision fatigue, and make Drift less actively used while increasing value per glance. Drift should remain local-first, optional, emotionally neutral, and agency preserving.

Drift should communicate: "Here is your current digital rhythm. I can help if you want."

Drift must not become a productivity dashboard, surveillance tool, blocking tool, therapy chatbot, or screen-time shame interface.

## Non-Negotiable Boundaries

Do not collect or infer from screenshots, keystrokes, clipboard contents, page text, private messages, microphone input, camera input, screen recording, browsing history, music listening history, cloud behavioral analytics, cloud profiling, or emotional diagnosis.

Apple Music, local soundscapes, and future visual ambience remain optional and user-initiated. Local soundscapes remain the default regulation path. All reasoning remains local and deterministic for now.

## Phase 1 - Mini-player Liquid Glass UI Refinement

Goal: Make Drift feel like an Apple Music mini-player and macOS Tahoe liquid-glass attention widget.

Scope:
- Compact widget-first design.
- Expanded detail card, not a dashboard.
- No black outer void around the widget.
- Native traffic-light controls visually attached to the glass surface.
- Liquid glass polish with legible typography.
- Stable hover behavior with no layout jumps.
- No dashboard clutter.

Implementation boundary:
- Preserve Mock mode, Live App mode, expand/collapse, local soundscape playback, Apple Music connection, Open Music handoff, intervention cards, rhythm suggestions, and breathing cue support.

## Phase 2 - Apple Music Recommendation Handoff

Goal: Make Apple Music useful without invasive data access.

Scope:
- Map current attention state and rhythm to safe Apple Music search or handoff suggestions.
- Example handoff searches: ambient focus, lofi focus, calm piano, brown noise, rain ambience, deep focus electronic, sunset ambient.
- User-initiated "Find in Apple Music" action.
- No autoplay.
- No library or history reading.
- No music taste profiling.
- Local soundscapes remain default.

Implementation boundary:
- Do not add MusicKit playback beyond authorization and handoff until a later explicit pass.

## Phase 3 - Local Soundscape Asset Expansion

Goal: Expand local and offline cues without cloud dependency.

Scope:
- CC0, compatible royalty-free, or original tiny audio loops.
- Deep work loop.
- Downshift loop.
- Rising energy cue.
- Sunset wind-down cue.
- No Endel assets.
- No Apple Music content.
- No large bundled assets until licensing is clear.

Implementation boundary:
- Keep bundled assets small, inspectable, and replaceable.

## Phase 4 - Visual Ambience / "Where Would You Like a Seat?"

Goal: Add non-invasive visual regulation based on user agency.

Concept: The user can choose or ask Drift to suggest an ambience metaphor.

Options:
- Library.
- Coffee Shop.
- Research Lab.
- Window Seat.
- Night Desk.
- Quiet Studio.
- Open Air.
- Rain Room.

Scope:
- Suggestion only.
- "Surprise me" button.
- No automatic wallpaper changes yet.
- No screen capture.
- No private context scraping.
- Possible future local wallpaper assets only with explicit user action.

Implementation boundary:
- Ambience is a voluntary setting, not an inferred identity or mood label.

## Phase 5 - Breathing Orb Refinement

Goal: Make the breathing cue visual and pleasant, not just audio or text.

Scope:
- Orb expands and contracts.
- Inhale and exhale phases.
- Low-resource animation.
- Optional sound cue.
- No full-screen takeover.
- No clinical anxiety framing.

Implementation boundary:
- The cue should stay small, dismissible, and quiet.

## Phase 6 - Grounding Workflow Scaffold

Goal: Support attention-deficit or overload states gently.

Scope:
- 5-4-3-2-1 grounding.
- Hidden unless relevant.
- No popups.
- Optional transient text field.
- Local-only.
- No forced persistence.
- No clinical framing.

Implementation boundary:
- Grounding remains an optional tool, never a diagnosis or required recovery flow.

## Phase 7 - Local Pattern Learning Architecture

Goal: Adapt locally over time without privacy invasion.

Scope:
- Bounded local summaries.
- Accepted and dismissed suggestions.
- Rhythm choices.
- Local cue plays.
- Ambience choices.
- No long-term raw window title storage.
- No private content.
- Clear local reset later.

Implementation boundary:
- Learn from explicit choices and coarse local summaries, not hidden behavioral surveillance.

## Phase 8 - Menu Bar / Passive Widget Behavior

Goal: Make Drift a true passive macOS companion.

Scope:
- Menu bar item.
- Show/hide widget.
- Low-presence companion behavior.
- No dashboard feel.
- Future launch-at-login option.

Implementation boundary:
- Drift should be easy to ignore and easy to summon.

## Phase Discipline

Each phase must answer:
- Does this reduce active usage?
- Does this preserve local-first reasoning?
- Does this avoid shame, diagnosis, and hidden collection?
- Does this keep user action in control of music, sound, and ambience?
- Does this make the next glance clearer rather than adding another dashboard?
