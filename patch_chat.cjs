const fs = require('fs');
const file = 'centro_de_mensajer_a/index.html';
let content = fs.readFileSync(file, 'utf8');

// Edit 1: Add ID to mobile nav
content = content.replace(
    '<nav class=\"md:hidden fixed bottom-0 w-full z-50 shadow-[0_-4px_12px_0px_rgba(0,0,0,0.04)] bg-surface-container-lowest flex justify-around items-center h-16 px-2 pb-safe border-t border-outline-variant\">',
    '<nav id=\"mobile-bottom-nav\" class=\"md:hidden fixed bottom-0 w-full z-50 shadow-[0_-4px_12px_0px_rgba(0,0,0,0.04)] bg-surface-container-lowest flex justify-around items-center h-16 px-2 pb-safe border-t border-outline-variant\">'
);

// Edit 2: Hide nav on chat open
content = content.replace(
    "        chatDetailView.classList.add('flex');\r\n    } else {",
    "        chatDetailView.classList.add('flex');\r\n        \r\n        const bNav = document.getElementById('mobile-bottom-nav');\r\n        if(bNav) bNav.classList.add('hidden');\r\n    } else {"
);
content = content.replace( // Try with just \n in case it was normalized
    "        chatDetailView.classList.add('flex');\n    } else {",
    "        chatDetailView.classList.add('flex');\n        \n        const bNav = document.getElementById('mobile-bottom-nav');\n        if(bNav) bNav.classList.add('hidden');\n    } else {"
);

// Edit 3: Show nav on back button
content = content.replace(
    "            chatListView.classList.add('flex');\r\n        }\r\n    });\r\n}",
    "            chatListView.classList.add('flex');\r\n            \r\n            const bNav = document.getElementById('mobile-bottom-nav');\r\n            if(bNav) bNav.classList.remove('hidden');\r\n        }\r\n    });\r\n}"
);
content = content.replace(
    "            chatListView.classList.add('flex');\n        }\n    });\n}",
    "            chatListView.classList.add('flex');\n            \n            const bNav = document.getElementById('mobile-bottom-nav');\n            if(bNav) bNav.classList.remove('hidden');\n        }\n    });\n}"
);

// Remove the padding-bottom 20 on mobile from chat-messages-container, since the bottom nav is hidden!
content = content.replace(
    'id="chat-messages-container" class="flex-1 overflow-y-auto p-gutter pb-20 md:pb-gutter',
    'id="chat-messages-container" class="flex-1 overflow-y-auto p-gutter pb-gutter'
);

fs.writeFileSync(file, content);
