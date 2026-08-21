# SuperTV — App Store

Guía de envío a review. **Objetivo: pasar review al primer intento.**

> ⚠️ Riesgo principal de apps tipo IPTV: rechazo por facilitar acceso a contenido con
> copyright o por posicionarse como "reproductor IPTV genérico". La estrategia es
> presentar SuperTV como un **reproductor de medios que el usuario configura con su
> propia suscripción** (BYO credenciales), sin contenido incluido ni sugerido.

---

## Posicionamiento (copy)

**Qué SÍ decir**: reproductor personal, tú traes tu servicio, controles de reproducción,
PiP, favoritos. **Qué NO decir**: nombres de canales/eventos, "ver TV gratis", "miles de
canales", marcas de contenido, deportes en directo, o cualquier cosa que implique que la
app provee el contenido.

### Nombre
`SuperTV` — (subtítulo) `Tu reproductor personal de streams`

### Subtítulo (30 car.)
`Reproductor para tu servicio`

### Texto promocional (170 car.)
`Conecta tu propia suscripción compatible y reproduce tus streams con controles nativos,
Picture in Picture y Control Center. Tú traes el servicio; SuperTV lo reproduce.`

### Descripción
```
SuperTV es un reproductor de medios para tu propia suscripción compatible (Xtream Codes).
La app no incluye ni ofrece ningún contenido: eres tú quien introduce los datos de acceso
de un servicio que ya contrataste.

• Conecta con tu servidor introduciendo servidor, usuario y contraseña.
• Navega tus categorías y canales, con búsqueda y logos.
• Reproducción con controles nativos: play/pausa, volumen, pantalla completa.
• Picture in Picture y controles en el Centro de Control.
• Funciona sin conexión con el último catálogo en caché.
• Tus credenciales se guardan de forma segura en el Llavero, solo en tu dispositivo.

SuperTV no provee canales ni contenido de ningún tipo. Requiere que dispongas de una
suscripción propia y legal a un servicio compatible.
```

### Palabras clave (100 car.)
`reproductor,media player,xtream,streams,player,pip,picture in picture,m3u,reproducción`

> Evita palabras clave de contenido (nombres de canales, "iptv gratis", deportes, marcas).

### Categoría
Principal: **Utilidades** o **Entretenimiento**. (Utilidades reduce el escrutinio de contenido.)

---

## Notas para el revisor (App Review Information → Notes)

```
SuperTV es un reproductor de medios genérico. NO incluye ni distribuye contenido.
El usuario debe introducir las credenciales de su propia suscripción a un servicio
compatible (protocolo Xtream Codes) para reproducir SUS streams.

Cómo probar:
1. En la pantalla de inicio, introducir servidor, usuario y contraseña de la cuenta
   de demo (abajo).
2. Pulsar "Conectar" → se listan las categorías → seleccionar una → seleccionar un canal
   → se reproduce.

Cuenta de demo (solo para review):
  Servidor:   [RELLENAR: host de demo, p. ej. http://tu-demo:8080]
  Usuario:    [RELLENAR]
  Contraseña: [RELLENAR]

Nota técnica (ATS): la app permite conexiones HTTP arbitrarias
(NSAllowsArbitraryLoads) porque los servidores compatibles los configura el usuario y
suelen servir por HTTP; no hay una lista de dominios que declarar por adelantado. No se
transmite ningún dato del usuario a los desarrolladores.
```

> **Acción requerida del desarrollador**: crear una cuenta de demo real y estable (que no
> caduque durante la review) y rellenar los campos de arriba. Sin una cuenta de demo
> funcional, la review se rechaza casi seguro.

---

## Privacidad (App Privacy → nutrition labels)

- **Data Not Collected.** La app no recopila datos. Marca "No, no recopilamos datos".
- Las credenciales se guardan en Keychain (dispositivo) y solo se envían al servidor del
  propio usuario. No van a los desarrolladores ni a terceros.
- Coherente con `SuperTV/PrivacyInfo.xcprivacy` (sin tracking, sin datos recopilados).

---

## Checklist técnico de envío

- [x] `PrivacyInfo.xcprivacy` incluido en el bundle.
- [x] ATS justificado (arriba).
- [ ] Cuenta de demo creada y puesta en las notas de review.
- [ ] Icono de app (1024×1024, sin transparencia).
- [ ] Capturas por tamaño de dispositivo requerido (6.9", 6.5"…).
- [ ] Política de privacidad publicada en una URL pública (ver `docs/PrivacyPolicy.md`).
- [ ] `MARKETING_VERSION` y `CURRENT_PROJECT_VERSION` correctos.
- [ ] Probar en dispositivo real antes de subir.
