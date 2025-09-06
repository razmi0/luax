# Luax

```js

import { defineConfig } from 'vite'

export default defineConfig({
  root: 'src',
  base: '/',
  build: {
    outDir: '../dist',
    emptyOutDir: true,
  },
  server: {
    port: 3000,
    open: true,
  },
  resolve: {
    alias: {
      '@': '/src',
    },
  },
})
```

```json
{
  "compilerOptions": {
    "target": "es2022",
    "module": "es2022",
    "lib": [
      "dom",
      "dom.iterable",
      "esnext"
    ],
    "jsx": "react-jsx",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "baseUrl": "./",
    "paths": {
      "@/*": [
        "src/*"
      ]
    }
  },
  "include": [
    "src"
  ],
  "exclude": [
    "node_modules",
    "dist"
  ]
}
```
