# Minecraft Portable Server

Servidor de Minecraft **Paper 1.18.2** pensado para ejecutarse desde un USB en Linux/Fedora, con Java portable y un panel Bash.

> El repositorio contiene los scripts y la estructura del proyecto. Los binarios grandes (Java/Paper), mundos, logs y backups se excluyen de Git mediante `.gitignore`.

## Características

- Java portable dentro del proyecto.
- Paper 1.18.2.
- Panel de administración en terminal.
- Inicio/parada/reinicio.
- Consola del servidor.
- OP y whitelist.
- Editor de `server.properties`.
- Gestión básica de plugins.
- Backups `.tar.gz`.
- Información de red y servidor.
- Preparado para añadir publicación a Internet, dominio/DDNS y túneles.

## Estructura

```text
minecraft-portable-server/
├── PANEL.sh
├── INSTALAR.sh
├── INICIAR.sh
├── README.md
├── .gitignore
├── config/
│   └── server.properties.example
├── scripts/
│   └── check-network.sh
├── backups/
├── java/                 # Java portable; no se sube a Git
└── server/
    ├── paper.jar         # Paper; no se sube a Git
    ├── plugins/
    ├── logs/
    └── mundos/           # generados por Paper
```

## Instalación

En el USB, coloca Java 17 portable en `java/` y Paper 1.18.2 en `server/paper.jar`.

Después:

```bash
chmod +x INSTALAR.sh INICIAR.sh PANEL.sh
./INSTALAR.sh
```

Puedes iniciar el panel con:

```bash
./INICIAR.sh
```

## Panel

```text
1  Iniciar servidor
2  Parar servidor
3  Reiniciar servidor
4  Jugadores
5  Consola
6  Propiedades
7  Permisos / OP
8  Plugins
9  Copia de seguridad
10 Logs
11 Información
0  Salir
```

## Plugins

Copia los `.jar` compatibles con Paper 1.18.2 en:

```text
server/plugins/
```

Reinicia el servidor después de instalar o actualizar plugins.

## Internet

La publicación directa normalmente requiere:

1. Una IP local estable para el PC.
2. Redirección TCP del puerto 25565 en el router.
3. Que el operador no use CG-NAT, o una alternativa mediante túnel.
4. Opcionalmente un dominio DNS apuntando a la IP pública.

**Nunca pongas `server-ip` con tu IP pública.** En la mayoría de instalaciones debe quedarse vacío para que Paper escuche en todas las interfaces disponibles.

La futura integración prevista en el panel es:

```text
Red
├── Ver IP local
├── Ver IP pública
├── Comprobar puerto
├── Abrir servidor a Internet
├── Configurar dominio/DDNS
└── Cerrar acceso público
```

## Seguridad

- Mantén `online-mode=true` salvo que sepas exactamente por qué necesitas cambiarlo.
- Usa whitelist si el servidor es privado.
- No compartas archivos de configuración con credenciales o tokens.
- No subas mundos, logs ni backups privados a GitHub.
- Mantén Paper y los plugins actualizados dentro de la versión de Minecraft que hayas elegido.

## GitHub

Antes del primer commit:

```bash
git init
git add .
git status
git commit -m "Initial portable Minecraft server"
```

Después añade el repositorio remoto de GitHub y haz push.
