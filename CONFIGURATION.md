# 🔐 Configuración de Variables de Entorno - Virtual Pet

## 📋 Variables Requeridas

### Para Desarrollo Local

Crea un archivo `.env` en la raíz del proyecto (ya está en `.gitignore`):

```bash
# Base de Datos
DB_USERNAME=virtualpet_user
DB_PASSWORD=virtualpet123

# JWT Security
JWT_SECRET=miClaveSecretaSuperSeguraDeAlMenos256BitsParaFirmarTokensJWT123456789
JWT_EXPIRATION=3600000
```

### Para Producción

**⚠️ IMPORTANTE: NUNCA uses las credenciales de desarrollo en producción**

#### Opción 1: Variables de Entorno del Sistema

```bash
export DB_USERNAME=usuario_produccion
export DB_PASSWORD=contraseña_segura_produccion
export JWT_SECRET=$(openssl rand -base64 64)
export JWT_EXPIRATION=3600000
```

#### Opción 2: Variables en Docker

```yaml
# docker-compose.yml
services:
  app:
    image: virtualpet:latest
    environment:
      - DB_USERNAME=${DB_USERNAME}
      - DB_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - JWT_EXPIRATION=3600000
```

#### Opción 3: Secrets en Kubernetes

```yaml
# kubernetes-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: virtualpet-secrets
type: Opaque
data:
  db-username: <base64_encoded>
  db-password: <base64_encoded>
  jwt-secret: <base64_encoded>
```

#### Opción 4: AWS Systems Manager (Parameter Store)

```bash
# Almacenar secretos
aws ssm put-parameter --name "/virtualpet/prod/db-username" --value "usuario" --type SecureString
aws ssm put-parameter --name "/virtualpet/prod/db-password" --value "password" --type SecureString
aws ssm put-parameter --name "/virtualpet/prod/jwt-secret" --value "secret" --type SecureString
```

## 🔑 Generar JWT Secret Seguro

```bash
# Linux/Mac
openssl rand -base64 64

# Python
python -c "import secrets; print(secrets.token_urlsafe(64))"

# Node.js
node -e "console.log(require('crypto').randomBytes(64).toString('base64'))"
```

## 📝 Configuración Inicial

### 1. Copiar el archivo de ejemplo

```bash
cp src/main/resources/application.properties.example src/main/resources/application.properties
```

### 2. Crear archivo .env (desarrollo local)

```bash
cat > .env << 'EOF'
DB_USERNAME=virtualpet_user
DB_PASSWORD=virtualpet123
JWT_SECRET=miClaveSecretaSuperSeguraDeAlMenos256BitsParaFirmarTokensJWT123456789
JWT_EXPIRATION=3600000
EOF
```

### 3. Cargar variables de entorno

```bash
# Linux/Mac
export $(cat .env | xargs)

# Windows (PowerShell)
Get-Content .env | ForEach-Object { $var = $_.Split('='); [System.Environment]::SetEnvironmentVariable($var[0], $var[1]) }
```

## 🚀 Despliegue en Diferentes Entornos

### Heroku

```bash
heroku config:set DB_USERNAME=usuario
heroku config:set DB_PASSWORD=password
heroku config:set JWT_SECRET=$(openssl rand -base64 64)
heroku config:set JWT_EXPIRATION=3600000
```

### AWS Elastic Beanstalk

```bash
eb setenv DB_USERNAME=usuario DB_PASSWORD=password JWT_SECRET=secret JWT_EXPIRATION=3600000
```

### DigitalOcean App Platform

Configurar en la interfaz web:
- Settings → App-Level Environment Variables

### Railway

Configurar en la interfaz web:
- Variables → Add Variable

## 🔒 Mejores Prácticas

### ✅ HACER

- ✅ Usar variables de entorno para credenciales
- ✅ Usar gestores de secretos (AWS Secrets Manager, HashiCorp Vault)
- ✅ Rotar secretos regularmente
- ✅ Usar diferentes credenciales por entorno
- ✅ Generar JWT secrets únicos y largos (mínimo 256 bits)
- ✅ Mantener `.env` en `.gitignore`
- ✅ Documentar variables requeridas

### ❌ NO HACER

- ❌ Subir credenciales a Git
- ❌ Hardcodear passwords en el código
- ❌ Compartir secretos por email/chat
- ❌ Usar la misma password en dev y prod
- ❌ Usar JWT secrets débiles o predecibles
- ❌ Commitear archivos `.env`

## 🆘 Si Ya Subiste Credenciales a Git

### 1. Cambiar TODAS las credenciales inmediatamente

```sql
-- Cambiar password de DB
ALTER USER virtualpet_user WITH PASSWORD 'nueva_password_segura';
```

### 2. Limpiar historial de Git (opcional, peligroso)

```bash
# ADVERTENCIA: Esto reescribe el historial
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch src/main/resources/application.properties" \
  --prune-empty --tag-name-filter cat -- --all

# Forzar push (coordinar con el equipo)
git push origin --force --all
```

### 3. Usar BFG Repo-Cleaner (más seguro)

```bash
# Instalar BFG
brew install bfg  # Mac
# o descargar desde: https://rtyley.github.io/bfg-repo-cleaner/

# Limpiar archivo
bfg --delete-files application.properties

# Limpiar y push
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push origin --force --all
```

## 📚 Referencias

- [The Twelve-Factor App - Config](https://12factor.net/config)
- [OWASP - Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [Spring Boot - Externalized Configuration](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config)

## 🆘 Soporte

Si tienes dudas sobre la configuración de variables de entorno, revisa:
- `application.properties.example` - Template con valores de ejemplo
- Este documento - Guía completa de configuración
- `README.md` - Documentación general del proyecto

