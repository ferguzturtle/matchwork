import { defineConfig } from "vite";
import { resolve } from "path";

export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, "index.html"),
        bienvenida_y_registro: resolve(
          __dirname,
          "bienvenida_y_registro/index.html",
        ),
        centro_de_mensajer_a: resolve(
          __dirname,
          "centro_de_mensajer_a/index.html",
        ),
        mapa_de_b_squeda_cliente: resolve(
          __dirname,
          "mapa_de_b_squeda_cliente/index.html",
        ),
        panel_del_prestador: resolve(
          __dirname,
          "panel_del_prestador/index.html",
        ),
        perfil_del_cliente: resolve(__dirname, "perfil_del_cliente/index.html"),
        perfil_del_prestador: resolve(
          __dirname,
          "perfil_del_prestador/index.html",
        ),
        landingpage: resolve(__dirname, "landingpage/index.html"),
      },
    },
  },
});
