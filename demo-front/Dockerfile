# Stage 1: Build
FROM node:20-alpine AS build
WORKDIR /app

# Copiar package files primero (para cache de dependencias)
COPY package*.json ./
RUN npm ci --production=false

# Copiar código fuente y compilar
COPY . .
RUN npm run build -- --configuration production

# Stage 2: Runtime con Nginx
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Eliminar archivos default de nginx
RUN rm -rf ./*

# Copiar archivos compilados desde stage de build
COPY --from=build /app/dist/demo-front/browser ./

# Configuración de Nginx para SPA
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
