containere/
├── adsb/
│   ├── .env.example
│   ├── anubis-adsb-policies.yaml
│   └── docker-compose.yml
├── markdown-live-preview/
│   ├── .env.example
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── app/
│   │   ├── .gitignore
│   │   ├── .gitmodules
│   │   ├── LICENSE
│   │   ├── Makefile
│   │   ├── README.md
│   │   ├── firebase.json
│   │   ├── index.html
│   │   ├── package.json
│   │   ├── package-lock.json
│   │   ├── vite.config.mjs
│   │   ├── public/
│   │   │   ├── 404.html
│   │   │   ├── favicon.png
│   │   │   ├── css/
│   │   │   │   ├── github-markdown-dark.css
│   │   │   │   ├── github-markdown-dark_dimmed.css
│   │   │   │   ├── github-markdown-light.css
│   │   │   │   └── style.css
│   │   │   └── image/
│   │   │       ├── GitHub-Mark-Light-32px.webp
│   │   │       ├── Markdown-mark.svg
│   │   │       └── sample.webp
│   │   ├── scripts/
│   │   │   └── update-css-version.mjs
│   │   └── src/
│   │       └── main.js
│   └── nginx/
│       └── default.conf
├── microbin/
│   ├── .env.example
│   ├── docker-compose.yml
│   ├── microbin-stats.service
│   ├── microbin-stats.sh
│   ├── microbin-stats.timer
│   └── crowdsec/
│       ├── acquis.yaml
│       └── config.yaml.local
├── vaultwarden/
│   ├── .env.example
│   ├── backup_vw.sh
│   ├── docker-compose.yml
│   └── crowdsec/
│       └── acquis.yaml
└── wud/
    └── docker-compose.yml
