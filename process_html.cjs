const fs = require('fs');
const path = require('path');

const folders = [
  'bienvenida_y_registro',
  'centro_de_mensajer_a',
  'geoservice_professional',
  'mapa_de_b_squeda_cliente',
  'panel_del_prestador',
  'perfil_del_prestador'
];

folders.forEach(folder => {
  const oldPath = path.join(__dirname, folder, 'code.html');
  const newPath = path.join(__dirname, folder, 'index.html');
  
  if (fs.existsSync(oldPath)) {
    let content = fs.readFileSync(oldPath, 'utf8');
    
    // Remove the CDN script
    content = content.replace(/<script src="https:\/\/cdn\.tailwindcss\.com\?plugins=forms,container-queries"><\/script>/g, '');
    
    // Remove the inline tailwind config
    content = content.replace(/<script id="tailwind-config">[\s\S]*?<\/script>/g, '');
    
    // Inject the local style.css in the head if not there
    if (!content.includes('<link rel="stylesheet" href="/style.css" />')) {
      content = content.replace('</head>', '  <link rel="stylesheet" href="/style.css" />\n</head>');
    }
    
    fs.writeFileSync(newPath, content);
    fs.unlinkSync(oldPath);
    console.log(`Processed ${folder}`);
  }
});
