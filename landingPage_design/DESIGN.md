# Design System Document

## 1. Overview & Creative North Star: The Celestial Guide
This design system is built to transform the "Sleep Tech" category into a high-end, editorial experience. Moving away from utilitarian layouts, we embrace the concept of **"The Celestial Guide."** 

The interface should feel as deep and expansive as the night sky. We achieve this by breaking the traditional rigid grid—utilizing intentional asymmetry, overlapping elements that "float" on different atmospheric planes, and high-contrast typography scales. The goal is a digital environment that feels breathable, premium, and calm, using soft glows to guide the user’s eye through complex sleep data without overwhelming the senses.

---

## 2. Colors: Depth and Atmosphere
The palette is rooted in the depth of space, using high-tech lavenders to punctuate the darkness.

### The "No-Line" Rule
To maintain a premium, seamless feel, **1px solid borders are strictly prohibited** for sectioning. Structural boundaries must be defined exclusively through background shifts (e.g., a `surface-container-low` section sitting on a `surface` background) or subtle tonal transitions.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of frosted glass.
- **Base:** `surface` (#0c0c1d)
- **Primary Content Area:** `surface-container-low` (#111124)
- **Interactive Cards:** `surface-container-high` (#1d1d34) or `surface-container-highest` (#23233c)
- **Nesting:** An inner element should always use a tier higher than its parent to create a natural, "lit" hierarchy.

### The Glass & Gradient Rule
Floating elements (modals, persistent players) must use **Glassmorphism**. Apply semi-transparent `surface-variant` with a `backdrop-filter: blur(20px)`. Main CTAs should use a linear gradient (Primary #ba9eff to Primary-Dim #8455ef) at a 135° angle to provide "visual soul."

---

## 3. Typography: Editorial Authority
We utilize a pairing of **Plus Jakarta Sans** for structure and **Manrope** for readability.

*   **Display & Headlines (Plus Jakarta Sans):** These are your "Editorial" voices. Use `display-lg` (3.5rem) with tight letter-spacing (-0.02em) for hero moments. The contrast between these large headlines and small labels creates a custom, high-end feel.
*   **Body & Titles (Manrope):** Chosen for its modern, tech-focused legibility. Use `body-lg` for descriptive text to maintain an approachable but sophisticated tone.
*   **The Signature Scale:** Use `label-sm` (uppercase, tracked out +10%) for section headers (e.g., "FEATURES") to create a disciplined, "architectural" look.

---

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are too "heavy" for a sleep app. We use light to create distance.

*   **Layering Principle:** Stack `surface-container` tiers. A `surface-container-lowest` card placed on a `surface-container-low` section creates a "recessed" effect, while the inverse creates a "lifted" effect.
*   **Ambient Shadows:** When an element must float, use a shadow with a blur radius of 40px+ and 4%-8% opacity. Use a tinted shadow: `#17172c` (a darker purple-navy) rather than pure black.
*   **Ghost Borders:** If accessibility requires a border, use the `outline-variant` token at **15% opacity**. This creates a "Ghost Border" that defines the edge without breaking the atmospheric flow.
*   **Glows:** Primary buttons and active states should emit a soft glow using a 20px blur of the `primary-dim` (#8455ef) color at 30% opacity.

---

## 5. Components: Precision Primitives

### Buttons
- **Primary:** Gradient fill (`primary` to `primary-dim`), rounded-xl (1.5rem). High-contrast `on-primary` text.
- **Secondary:** Glassmorphism style. Semi-transparent `surface-bright` with a 15% `outline` ghost border.
- **Tertiary:** Text-only, using `primary` color with `label-md` typography.

### Chips & Selectors
- Use `rounded-full` (9999px). Active chips should use a solid `secondary-container` fill; inactive chips should use `surface-container-highest` with no border.

### Input Fields
- Avoid boxes. Use a `surface-container-low` background with a subtle bottom-only `outline` at 20% opacity. Focus states trigger a soft `primary` outer glow.

### Cards & Lists
- **The No-Divider Rule:** Explicitly forbid horizontal divider lines. Separate list items using the spacing scale (e.g., `spacing-4` / 1.4rem) or subtle background-color shifts between even and odd rows.
- **Feature Cards:** Use `surface-container-high`, `rounded-lg`, and an icon centered in a `primary-container` soft-glow circle.

---

## 6. Do’s and Don'ts

### Do
- **DO** use white space as a structural element. If a layout feels crowded, increase the spacing to `spacing-12` (4rem).
- **DO** overlap elements (e.g., a phone mockup overlapping a background glow) to create depth.
- **DO** use "on-surface-variant" (#aba9c0) for secondary text to maintain a soft, low-blue-light aesthetic.

### Don't
- **DON'T** use 100% white (#FFFFFF). Use `on-background` (#e6e3fc) to prevent eye strain in dark environments.
- **DON'T** use sharp corners. Every element must have at least `rounded-md` (0.75rem) to maintain the "calm" brand pillar.
- **DON'T** use standard system motion. Use slow, ease-out transitions (300ms+) to mimic the pace of breathing and sleep.