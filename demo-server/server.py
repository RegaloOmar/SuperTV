#!/usr/bin/env python3
"""Mini-servidor compatible con el API de Xtream Codes, SOLO para la cuenta demo
que revisa Apple.

No sirve contenido propio: redirige a streams HLS públicos y legales (películas de
Blender de dominio público y streams de prueba oficiales de Apple/Mux).

Implementa exactamente lo que llama SuperTV:
  1) GET /player_api.php?username=&password=                       -> auth (user_info)
  2) GET /player_api.php?...&action=get_live_categories            -> categorías
  3) GET /player_api.php?...&action=get_live_streams[&category_id] -> canales
  4) GET /live/<user>/<pass>/<stream_id>.m3u8                      -> 302 al HLS real

Sin dependencias: solo la librería estándar de Python 3.
    python3 server.py
"""

import json
import os
import re
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

# Credenciales de la cuenta demo (las que pondrás en App Store Connect).
# Se pueden sobreescribir por variables de entorno al desplegar.
DEMO_USER = os.environ.get("DEMO_USER", "demo")
DEMO_PASS = os.environ.get("DEMO_PASS", "demo")
PORT = int(os.environ.get("PORT", "8080"))

# Catálogo demo. Cada canal apunta a un HLS público y legal.
CATEGORIES = [
    {"category_id": "1", "category_name": "Movies (Public Domain)"},
    {"category_id": "2", "category_name": "Test Streams"},
]

STREAMS = [
    {"stream_id": 1, "num": 101, "name": "Big Buck Bunny", "category_id": "1",
     "url": "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"},
    {"stream_id": 2, "num": 102, "name": "Tears of Steel", "category_id": "1",
     "url": "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"},
    {"stream_id": 3, "num": 201, "name": "Apple BipBop (HLS oficial)", "category_id": "2",
     "url": "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8"},
    {"stream_id": 4, "num": 202, "name": "Mux Test Stream", "category_id": "2",
     "url": "https://test-streams.mux.dev/pts_shift/master.m3u8"},
]

LIVE_RE = re.compile(r"^/live/([^/]+)/([^/]+)/(\d+)\.(m3u8|ts|mp4)$")


def auth_payload(authenticated):
    """Respuesta de auth con la forma que espera UserInfoDTO."""
    if not authenticated:
        return {"user_info": {"auth": 0}}
    # exp_date en el futuro lejano (10 años) para que nunca aparezca "Expired".
    exp_date = str(int(time.time()) + 10 * 365 * 24 * 3600)
    return {"user_info": {
        "auth": 1,
        "status": "Active",
        "exp_date": exp_date,
        "is_trial": "0",
        "active_cons": "0",
        "max_connections": "5",
    }}


class Handler(BaseHTTPRequestHandler):
    def _json(self, status, body):
        payload = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _text(self, status, text):
        payload = text.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        q = parse_qs(parsed.query)

        # Página de estado para verificar que el servidor está arriba.
        if path in ("/", "/health"):
            return self._text(200, "SuperTV demo Xtream server OK")

        # 1-3) API de Xtream
        if path == "/player_api.php":
            user = q.get("username", [None])[0]
            pass_ = q.get("password", [None])[0]
            action = q.get("action", [None])[0]
            authed = user == DEMO_USER and pass_ == DEMO_PASS

            if not authed:
                return self._json(200, auth_payload(False))
            if not action:
                return self._json(200, auth_payload(True))
            if action == "get_live_categories":
                return self._json(200, CATEGORIES)
            if action == "get_live_streams":
                category_id = q.get("category_id", [None])[0]
                items = [
                    {
                        "stream_id": s["stream_id"],
                        "num": s["num"],
                        "name": s["name"],
                        "stream_type": "live",
                        "stream_icon": "",
                        "epg_channel_id": "",
                        "category_id": s["category_id"],
                    }
                    for s in STREAMS
                    if not category_id or s["category_id"] == category_id
                ]
                return self._json(200, items)
            # Acción no soportada: array vacío (la app lo tolera).
            return self._json(200, [])

        # 4) Reproducción: /live/<user>/<pass>/<stream_id>.m3u8 -> redirige al HLS real.
        m = LIVE_RE.match(path)
        if m:
            user, pass_, sid, _ext = m.groups()
            if user != DEMO_USER or pass_ != DEMO_PASS:
                return self._text(403, "Forbidden")
            stream = next((s for s in STREAMS if str(s["stream_id"]) == sid), None)
            if stream is None:
                return self._text(404, "Stream not found")
            self.send_response(302)
            self.send_header("Location", stream["url"])
            self.end_headers()
            return

        return self._text(404, "Not found")

    def log_message(self, fmt, *args):
        # Log compacto en una línea.
        print("%s - %s" % (self.address_string(), fmt % args))


if __name__ == "__main__":
    print("SuperTV demo Xtream server escuchando en :%d" % PORT)
    print("Usuario demo: %s / %s" % (DEMO_USER, DEMO_PASS))
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
