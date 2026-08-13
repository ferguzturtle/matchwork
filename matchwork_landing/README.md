# MatchWork - Landing Page Oficial 🚀

Este repositorio contiene el código fuente de la Landing Page informativa y los Términos y Condiciones oficiales de la plataforma **MatchWork**. Está construida con tecnologías web estándar y empaquetada de forma ultra rápida usando **Vite**.

## 🛠️ Tecnologías y Lenguajes
- **HTML5**: Estructura semántica de la página.
- **CSS3 (Vanilla)**: Estilos, diseño responsive y animaciones (sin dependencias de frameworks CSS pesados).
- **JavaScript (ES6+)**: Interacciones sencillas, efectos de scroll y formulario de contacto.
- **Vite**: Entorno de desarrollo rápido y empaquetador para producción.

---

## 💻 Requisitos Previos
Debes tener instalado **Node.js** (versión 18 o superior recomendada) en tu sistema.

---

## 🚀 Pasos para Instalar y Correr Localmente

### 1. Clonar el repositorio
```bash
git clone https://github.com/ferguzturtle/ladingpage_matchwork.git
```

### 2. Entrar a la carpeta del proyecto
```bash
cd ladingpage_matchwork
```

### 3. Instalar las dependencias
```bash
npm install
```

### 4. Iniciar el servidor de desarrollo local
```bash
npm run dev
```
Una vez ejecutado, abre tu navegador en: 👉 **http://localhost:5173**

---

## 📦 Compilación para Producción (Lanzamiento)
Para generar los archivos listos para subir a hosting como **Netlify**, **Vercel** o servidores estáticos:

```bash
npm run build
```
Esto creará una carpeta llamada **`dist`** que contiene el código HTML/CSS/JS minificado y optimizado. Sube **únicamente el contenido de la carpeta `dist`** a tu plataforma de hosting.

---

## 📁 Estructura del Proyecto
- `index.html`: Página principal informativa.
- `terminos.html`: Página de Términos y Condiciones Legales.
- `style.css`: Estilos globales de la aplicación.
- `main.js`: Lógica del cliente e interactividad.
- `public/`: Assets estáticos del proyecto (Mockups de la app y fotos del equipo).
- `vite.config.js`: Configuración multi-página de Vite para compilar tanto el index como los términos.
