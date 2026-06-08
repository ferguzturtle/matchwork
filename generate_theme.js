const fs = require('fs');
const colors = {
    'on-surface-variant': '#45464d',
    'surface-bright': '#f7f9fb',
    'background': '#f7f9fb',
    'on-secondary-fixed-variant': '#003ea8',
    'surface-dim': '#d8dadc',
    'on-tertiary-fixed': '#001a42',
    'primary-fixed-dim': '#bec6e0',
    'on-error': '#ffffff',
    'error-container': '#ffdad6',
    'on-secondary': '#ffffff',
    'outline': '#76777d',
    'secondary-fixed-dim': '#b4c5ff',
    'outline-variant': '#c6c6cd',
    'primary-fixed': '#dae2fd',
    'secondary-container': '#316bf3',
    'tertiary-fixed-dim': '#adc6ff',
    'surface-container-high': '#e6e8ea',
    'primary-container': '#131b2e',
    'inverse-primary': '#bec6e0',
    'on-tertiary-fixed-variant': '#004395',
    'surface-container-lowest': '#ffffff',
    'on-tertiary-container': '#3980f4',
    'inverse-surface': '#2d3133',
    'surface-container': '#eceef0',
    'on-primary-container': '#7c839b',
    'on-surface': '#191c1e',
    'on-primary': '#ffffff',
    'surface': '#f7f9fb',
    'on-tertiary': '#ffffff',
    'on-error-container': '#93000a',
    'on-secondary-fixed': '#00174b',
    'on-primary-fixed-variant': '#3f465c',
    'surface-variant': '#e0e3e5',
    'surface-container-highest': '#e0e3e5',
    'tertiary': '#000000',
    'tertiary-fixed': '#d8e2ff',
    'on-background': '#191c1e',
    'surface-tint': '#565e74',
    'tertiary-container': '#001a42',
    'secondary': '#0051d5',
    'secondary-fixed': '#dbe1ff',
    'surface-container-low': '#f2f4f6',
    'on-secondary-container': '#fefcff',
    'inverse-on-surface': '#eff1f3',
    'error': '#ba1a1a',
    'primary': '#000000',
    'on-primary-fixed': '#131b2e'
};

const darkColors = {
    'on-surface-variant': '#c4c6d0',
    'surface-bright': '#38393e',
    'background': '#111315',
    'on-secondary-fixed-variant': '#b4c5ff',
    'surface-dim': '#111315',
    'on-tertiary-fixed': '#d8e2ff',
    'primary-fixed-dim': '#bec6e0',
    'on-error': '#690005',
    'error-container': '#93000a',
    'on-secondary': '#00297a',
    'outline': '#8f9099',
    'secondary-fixed-dim': '#316bf3',
    'outline-variant': '#45464d',
    'primary-fixed': '#dae2fd',
    'secondary-container': '#003ea8',
    'tertiary-fixed-dim': '#adc6ff',
    'surface-container-high': '#282a2f',
    'primary-container': '#3f465c',
    'inverse-primary': '#565e74',
    'on-tertiary-fixed-variant': '#adc6ff',
    'surface-container-lowest': '#090b0d',
    'on-tertiary-container': '#d8e2ff',
    'inverse-surface': '#e2e2e6',
    'surface-container': '#1d1f24',
    'on-primary-container': '#dae2fd',
    'on-surface': '#e2e2e6',
    'on-primary': '#283044',
    'surface': '#111315',
    'on-tertiary': '#00297a',
    'on-error-container': '#ffdad6',
    'on-secondary-fixed': '#dbe1ff',
    'on-primary-fixed-variant': '#bec6e0',
    'surface-variant': '#45464d',
    'surface-container-highest': '#33353a',
    'tertiary': '#b4c5ff',
    'tertiary-fixed': '#d8e2ff',
    'on-background': '#e2e2e6',
    'surface-tint': '#bec6e0',
    'tertiary-container': '#003ea8',
    'secondary': '#b4c5ff',
    'secondary-fixed': '#dbe1ff',
    'surface-container-low': '#191b20',
    'on-secondary-container': '#dbe1ff',
    'inverse-on-surface': '#2d3133',
    'error': '#ffb4ab',
    'primary': '#bec6e0',
    'on-primary-fixed': '#dae2fd'
};

let css = ':root {\n';
for (const [key, value] of Object.entries(colors)) {
    css += `  --color-${key}: ${value};\n`;
}
css += '}\n\n.dark {\n';
for (const [key, value] of Object.entries(darkColors)) {
    css += `  --color-${key}: ${value};\n`;
}
css += '}\n';

let tailwind = '{\n';
for (const key of Object.keys(colors)) {
    tailwind += `        "${key}": "var(--color-${key})",\n`;
}
tailwind += '      }';

fs.mkdirSync('scratch', { recursive: true });
fs.writeFileSync('scratch/theme.css', css);
fs.writeFileSync('scratch/tailwind_colors.txt', tailwind);
console.log('Generated CSS and Tailwind config parts');
