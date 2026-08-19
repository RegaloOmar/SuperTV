# SuperTV — Servidor demo Xtream (para el review de Apple)

Mini-servidor compatible con el API de Xtream Codes, **solo** para la cuenta demo que
revisa Apple. No sirve contenido propio: redirige a streams HLS **públicos y legales**
(Big Buck Bunny y Tears of Steel de Blender, dominio público; streams de prueba
oficiales de Apple y Mux).

Implementa exactamente lo que llama la app:

| Petición de la app | Respuesta |
|---|---|
| `GET /player_api.php?username=&password=` | auth (`user_info`) |
| `…&action=get_live_categories` | categorías |
| `…&action=get_live_streams[&category_id]` | canales |
| `GET /live/<user>/<pass>/<id>.m3u8` | `302` al HLS real |

Credenciales por defecto: **usuario `demo` / contraseña `demo`** (cámbialas con las
variables de entorno `DEMO_USER` / `DEMO_PASS`).

---

## 1. Probarlo en local (sin instalar nada)

```bash
python3 server.py
```

Queda escuchando en `http://localhost:8080`. Para probarlo **desde la app** en el
simulador o un dispositivo de tu misma red Wi-Fi, usa la IP de tu Mac:

- **Servidor:** `http://192.168.68.101:8080`
- **Usuario:** `demo`
- **Contraseña:** `demo`

(Si cambia tu red, saca la IP con `ipconfig getifaddr en0`.)

Deberías ver 2 categorías y 4 canales que reproducen.

---

## 2. Desplegarlo público (para que Apple lo alcance)

Apple revisa desde sus servidores, así que necesita una **URL pública**. La forma más
fácil y gratis es **Render**:

1. Sube este repo a GitHub (ya lo tienes).
2. En [render.com](https://render.com) → **New → Web Service** → conecta el repo.
3. Configura:
   - **Root Directory:** `demo-server`
   - **Runtime:** Python 3
   - **Build Command:** *(vacío)*
   - **Start Command:** `python3 server.py`
4. Deploy. Render te da una URL tipo `https://supertv-demo.onrender.com`.
5. Esa URL es tu **Servidor** para la cuenta demo (sin `:8080`; Render usa el puerto
   de la variable `PORT`, que el servidor ya respeta).

> ⚠️ **Cold start:** el plan gratis de Render **duerme** tras inactividad y la primera
> petición puede tardar ~30-60 s en despertar → el login del reviewer podría dar
> timeout. Para el periodo de review conviene el plan **always-on** (~7 USD/mes) o un
> VPS pequeño. Puedes bajarlo después de que aprueben la app.

Alternativas equivalentes: Railway, Fly.io, o cualquier VPS con Python 3.

---

## 3. Qué poner en App Store Connect

En **App Store Connect → tu app → App Review Information**:

- **Sign-In required:** sí
- **User name:** `demo`
- **Password:** `demo`
- **Notes:** (pega esto)

```
La app es un REPRODUCTOR de IPTV: no provee ni incluye contenido. El usuario
introduce las credenciales de su propio proveedor Xtream Codes. La cuenta demo
apunta a un servidor de prueba con streams de dominio público y de prueba
oficiales (Blender, Apple, Mux), solo para demostrar la funcionalidad.

Cómo probar:
1. Abrir la app.
2. Servidor: https://TU-URL-DE-RENDER   Usuario: demo   Contraseña: demo
3. Pulsar Conectar.
4. Elegir una categoría y luego un canal para reproducir.

Nota ATS: los paneles Xtream sirven por HTTP y el host lo introduce el usuario,
por eso NSAllowsArbitraryLoads.
```

Sustituye `https://TU-URL-DE-RENDER` por la URL real del despliegue.
