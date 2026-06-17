---
name: GeoService Professional
colors:
  surface: "#f7f9fb"
  surface-dim: "#d8dadc"
  surface-bright: "#f7f9fb"
  surface-container-lowest: "#ffffff"
  surface-container-low: "#f2f4f6"
  surface-container: "#eceef0"
  surface-container-high: "#e6e8ea"
  surface-container-highest: "#e0e3e5"
  on-surface: "#191c1e"
  on-surface-variant: "#45464d"
  inverse-surface: "#2d3133"
  inverse-on-surface: "#eff1f3"
  outline: "#76777d"
  outline-variant: "#c6c6cd"
  surface-tint: "#565e74"
  primary: "#000000"
  on-primary: "#ffffff"
  primary-container: "#131b2e"
  on-primary-container: "#7c839b"
  inverse-primary: "#bec6e0"
  secondary: "#0051d5"
  on-secondary: "#ffffff"
  secondary-container: "#316bf3"
  on-secondary-container: "#fefcff"
  tertiary: "#000000"
  on-tertiary: "#ffffff"
  tertiary-container: "#001a42"
  on-tertiary-container: "#3980f4"
  error: "#ba1a1a"
  on-error: "#ffffff"
  error-container: "#ffdad6"
  on-error-container: "#93000a"
  primary-fixed: "#dae2fd"
  primary-fixed-dim: "#bec6e0"
  on-primary-fixed: "#131b2e"
  on-primary-fixed-variant: "#3f465c"
  secondary-fixed: "#dbe1ff"
  secondary-fixed-dim: "#b4c5ff"
  on-secondary-fixed: "#00174b"
  on-secondary-fixed-variant: "#003ea8"
  tertiary-fixed: "#d8e2ff"
  tertiary-fixed-dim: "#adc6ff"
  on-tertiary-fixed: "#001a42"
  on-tertiary-fixed-variant: "#004395"
  background: "#f7f9fb"
  on-background: "#191c1e"
  surface-variant: "#e0e3e5"
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: "700"
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: "600"
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: "600"
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: "400"
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: "400"
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: "400"
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: "600"
    lineHeight: 20px
    letterSpacing: 0.05em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: "500"
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-margin-mobile: 1rem
  container-margin-desktop: 2.5rem
  gutter: 1rem
  stack-sm: 0.5rem
  stack-md: 1rem
  stack-lg: 1.5rem
---

## Brand & Style

This design system is engineered to project reliability, precision, and local competence. The target audience includes both service providers and end-users who require immediate, high-trust interactions within their physical vicinity.

The aesthetic is **Corporate / Modern**, leaning heavily on architectural clarity and functional minimalism. It utilizes a refined color palette to establish authority through deep tones while driving action through vibrant, high-contrast focal points. The interface avoids unnecessary ornamentation, focusing instead on information density that remains legible and organized, ensuring users feel secure when booking professional services.

## Colors

The palette is anchored by **Deep Navy (#0F172A)**, used for top-level navigation, headers, and primary text to evoke stability and institutional trust.

**Vibrant Royal Blue (#2563EB)** serves as the primary action color for CTAs, ensuring high discoverability against the **Clean White (#FFFFFF)** and **Light Grey (#F8FAFC)** backgrounds. Status-specific colors are utilized for functional signaling: **Emerald (#10B981)** for 'Online' availability and a muted **Slate (#94A3B8)** for 'Offline' states, maintaining a professional demeanor even in inactive statuses.

## Typography

The design system exclusively utilizes **Inter**, a typeface designed for screen legibility and functional neutrality.

The type hierarchy is strictly enforced to guide users through complex service listings. Headlines use heavier weights (SemiBold to Bold) with slight negative letter-spacing to appear compact and authoritative. Body text maintains a generous line height to ensure readability during mobile use. Labels and status indicators use a medium weight to differentiate them from standard body copy without requiring excessive scale.

## Layout & Spacing

The layout follows a **Fluid Grid** model with a focus on vertical rhythm. On mobile devices, a single-column layout with 16px side margins is standard. As the viewport expands to tablet and desktop, the system transitions to a 12-column grid.

Spacing is based on an 8px base unit. Components such as service cards and map overlays use consistent internal padding (16px or 24px) to maintain a breathable, organized appearance. Logical grouping of elements should favor "Stack" patterns (vertical arrangement) to ensure the geo-localized data remains easy to scan while on the move.

## Elevation & Depth

This design system employs **Ambient Shadows** to create a sense of physical layering without appearing heavy.

1.  **Level 0 (Flat):** Used for the main background and map interface.
2.  **Level 1 (Soft):** Low-offset shadows (4px Y-axis, 12px blur, 4% opacity) used for service cards to subtly lift them from the background.
3.  **Level 2 (Floating):** Higher-offset shadows used for map markers and floating action buttons to ensure they remain distinct from the underlying map data.
4.  **Inlay:** Used for input fields to provide a clear "trough" for data entry, reinforcing the interactive nature of the component.

## Shapes

The shape language centers on **Rounded (8px - 12px)** corners. This radius strikes a balance between the clinical feel of sharp corners and the overly casual feel of fully rounded pill shapes.

- **Standard Components:** Buttons and input fields use an 8px radius.
- **Containers:** Service provider cards and modal sheets use a 12px radius to feel more approachable.
- **Indicators:** Status badges and small tags use a "semi-pill" radius (usually 4px or 6px depending on height) to maintain distinctiveness from larger structural elements.

## Components

### Map Markers

Markers must be "Pin-drop" style with a sharp point for precise location indicating. The primary marker for a selected service uses the Royal Blue hex, while secondary/nearby markers use a White fill with a thin Navy border. Icons inside markers should be 16px and centered.

### Status Badges

Badges for 'Online/Offline' consist of a small 8px dot (Emerald for online, Slate for offline) followed by text in `label-md`. The background of the badge is a 10% opacity tint of the status color to ensure the text remains the focal point.

### Service Provider Cards

Cards are white with a subtle Level 1 shadow and a 1px Slate-200 border. They feature a 64px circular avatar on the left, with the provider's name in `headline-sm` and their primary service in `body-sm`. The price or rating is pinned to the top-right for immediate scanning.

### Buttons

- **Primary:** Royal Blue background, White text, 8px radius. Used for "Book Now" or "Contact."
- **Secondary:** White background, Navy border (1px), Navy text. Used for "View Profile" or "Message."

### Input Fields

Inputs use a Light Grey (#F1F5F9) background in their rest state, transitioning to a White background with a Royal Blue 2px border on focus to provide clear feedback.
