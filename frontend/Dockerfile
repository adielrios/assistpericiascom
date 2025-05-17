FROM node:16-alpine as build

WORKDIR /app

# Copiar arquivos de configuração
COPY package*.json ./
RUN npm install

# Copiar código fonte
COPY . .

# Compilar para produção
RUN npm run build

# Imagem de produção
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
