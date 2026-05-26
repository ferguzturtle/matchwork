/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./**/*.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      "colors": {
        "on-surface-variant": "#45464d",
        "surface-bright": "#f7f9fb",
        "background": "#f7f9fb",
        "on-secondary-fixed-variant": "#003ea8",
        "surface-dim": "#d8dadc",
        "on-tertiary-fixed": "#001a42",
        "primary-fixed-dim": "#bec6e0",
        "on-error": "#ffffff",
        "error-container": "#ffdad6",
        "on-secondary": "#ffffff",
        "outline": "#76777d",
        "secondary-fixed-dim": "#b4c5ff",
        "outline-variant": "#c6c6cd",
        "primary-fixed": "#dae2fd",
        "secondary-container": "#316bf3",
        "tertiary-fixed-dim": "#adc6ff",
        "surface-container-high": "#e6e8ea",
        "primary-container": "#131b2e",
        "inverse-primary": "#bec6e0",
        "on-tertiary-fixed-variant": "#004395",
        "surface-container-lowest": "#ffffff",
        "on-tertiary-container": "#3980f4",
        "inverse-surface": "#2d3133",
        "surface-container": "#eceef0",
        "on-primary-container": "#7c839b",
        "on-surface": "#191c1e",
        "on-primary": "#ffffff",
        "surface": "#f7f9fb",
        "on-tertiary": "#ffffff",
        "on-error-container": "#93000a",
        "on-secondary-fixed": "#00174b",
        "on-primary-fixed-variant": "#3f465c",
        "surface-variant": "#e0e3e5",
        "surface-container-highest": "#e0e3e5",
        "tertiary": "#000000",
        "tertiary-fixed": "#d8e2ff",
        "on-background": "#191c1e",
        "surface-tint": "#565e74",
        "tertiary-container": "#001a42",
        "secondary": "#0051d5",
        "secondary-fixed": "#dbe1ff",
        "surface-container-low": "#f2f4f6",
        "on-secondary-container": "#fefcff",
        "inverse-on-surface": "#eff1f3",
        "error": "#ba1a1a",
        "primary": "#000000",
        "on-primary-fixed": "#131b2e"
      },
      "borderRadius": {
        "DEFAULT": "0.25rem",
        "lg": "0.5rem",
        "xl": "0.75rem",
        "full": "9999px"
      },
      "spacing": {
        "stack-sm": "0.5rem",
        "stack-md": "1rem",
        "gutter": "1rem",
        "container-margin-mobile": "1rem",
        "container-margin-desktop": "2.5rem",
        "stack-lg": "1.5rem"
      },
      "fontFamily": {
        "body-lg": ["Inter", "sans-serif"],
        "headline-lg": ["Inter", "sans-serif"],
        "body-md": ["Inter", "sans-serif"],
        "headline-md": ["Inter", "sans-serif"],
        "label-lg": ["Inter", "sans-serif"],
        "headline-sm": ["Inter", "sans-serif"],
        "body-sm": ["Inter", "sans-serif"],
        "label-md": ["Inter", "sans-serif"]
      },
      "fontSize": {
        "body-lg": ["18px", {"lineHeight": "28px", "fontWeight": "400"}],
        "headline-lg": ["32px", {"lineHeight": "40px", "letterSpacing": "-0.02em", "fontWeight": "700"}],
        "body-md": ["16px", {"lineHeight": "24px", "fontWeight": "400"}],
        "headline-md": ["24px", {"lineHeight": "32px", "letterSpacing": "-0.01em", "fontWeight": "600"}],
        "label-lg": ["14px", {"lineHeight": "20px", "letterSpacing": "0.05em", "fontWeight": "600"}],
        "headline-sm": ["20px", {"lineHeight": "28px", "fontWeight": "600"}],
        "body-sm": ["14px", {"lineHeight": "20px", "fontWeight": "400"}],
        "label-md": ["12px", {"lineHeight": "16px", "fontWeight": "500"}]
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/container-queries')
  ],
}
