# 🆘 Guía de Emergencia: Credenciales Expuestas en Git

## ⚠️ SI YA SUBISTE CREDENCIALES A GIT

**ACCIÓN INMEDIATA REQUERIDA:**

### 1️⃣ Cambiar TODAS las Credenciales (URGENTE)

#### Cambiar Password de PostgreSQL
```bash
psql -U postgres
ALTER USER virtualpet_user WITH PASSWORD 'nueva_password_super_segura_$(openssl rand -hex 16)';
\q
```

#### Generar Nuevo JWT Secret
```bash
# Generar nuevo secret
NEW_JWT_SECRET=$(openssl rand -base64 64)
echo "Nuevo JWT Secret: $NEW_JWT_SECRET"

# Guardarlo en .env
echo "JWT_SECRET=$NEW_JWT_SECRET" >> .env
```

#### Actualizar application.properties
Asegúrate de que use variables de entorno:
```properties
jwt.secret=${JWT_SECRET:CHANGE_THIS}
spring.datasource.password=${DB_PASSWORD:changeme}
```

---

### 2️⃣ Opción A: Eliminar Archivo del Repositorio (Mantener Historial)

Si el historial no es crítico y quieres seguir adelante:

```bash
# 1. Agregar el archivo a .gitignore
echo "src/main/resources/application.properties" >> .gitignore

# 2. Eliminar del tracking de Git (mantiene el archivo local)
git rm --cached src/main/resources/application.properties

# 3. Commit
git commit -m "🔒 Remove sensitive credentials from tracking"

# 4. Push
git push origin main
```

**⚠️ ADVERTENCIA:** Las credenciales aún están en el historial de Git. Cualquiera puede verlas con `git log`.

---

### 3️⃣ Opción B: Limpiar Historial con BFG Repo-Cleaner (RECOMENDADO)

#### Instalar BFG
```bash
# Mac
brew install bfg

# Linux (Ubuntu/Debian)
sudo apt-get install bfg

# Windows/Manual
# Descargar desde: https://rtyley.github.io/bfg-repo-cleaner/
```

#### Usar BFG para Limpiar
```bash
# 1. Hacer backup del repositorio
cp -r /home/optimus/Desktop/VirtualPet /home/optimus/Desktop/VirtualPet-backup

# 2. Clonar una copia bare del repo
cd /home/optimus/Desktop
git clone --mirror https://github.com/tu-usuario/VirtualPet.git VirtualPet-mirror
cd VirtualPet-mirror

# 3. Eliminar el archivo con credenciales del historial
bfg --delete-files application.properties

# 4. Limpiar referencias
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 5. Forzar push (ADVERTENCIA: Reescribe historial)
git push --force

# 6. Volver al repositorio original
cd /home/optimus/Desktop/VirtualPet
git fetch origin
git reset --hard origin/main
```

**⚠️ IMPORTANTE:** 
- Coordina con tu equipo antes de hacer `git push --force`
- Todos tendrán que hacer `git reset --hard origin/main`
- El historial será reescrito completamente

---

### 4️⃣ Opción C: Limpiar con git filter-branch (Avanzado)

**⚠️ Solo usa esto si BFG no funciona**

```bash
# 1. Hacer backup
cp -r /home/optimus/Desktop/VirtualPet /home/optimus/Desktop/VirtualPet-backup

# 2. Eliminar el archivo del historial
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch src/main/resources/application.properties" \
  --prune-empty --tag-name-filter cat -- --all

# 3. Limpiar referencias
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 4. Forzar push
git push origin --force --all
git push origin --force --tags
```

---

### 5️⃣ Notificar al Equipo

Si trabajas en equipo, notifica a todos:

```
🚨 ALERTA DE SEGURIDAD

Se han expuesto credenciales en el repositorio.

ACCIONES TOMADAS:
- ✅ Credenciales cambiadas
- ✅ Historial de Git limpiado
- ✅ Variables de entorno implementadas

ACCIONES REQUERIDAS POR EL EQUIPO:
1. Hacer backup de cambios locales
2. Ejecutar: git fetch origin && git reset --hard origin/main
3. Copiar .env.example a .env y configurar variables
4. Verificar que .env NO esté en Git: git check-ignore .env

NUEVAS CREDENCIALES:
- DB_PASSWORD: [enviado por canal seguro]
- JWT_SECRET: [enviado por canal seguro]
```

---

### 6️⃣ Verificar que se Limpió

```bash
# Verificar que el archivo sensible no está en el historial
git log --all --full-history --source --find-object=<commit-hash>

# Buscar texto sensible en el historial
git log -p --all -S "virtualpet123" | less

# Verificar tamaño del repositorio (debería reducirse)
du -sh .git
```

---

### 7️⃣ Prevenir Futuros Problemas

#### Instalar git-secrets (AWS)
```bash
# Mac
brew install git-secrets

# Linux
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
make install

# Configurar
cd /home/optimus/Desktop/VirtualPet
git secrets --install
git secrets --register-aws
```

#### Pre-commit Hook Manual
```bash
# Crear .git/hooks/pre-commit
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
if git diff --cached | grep -E "(password|secret|token|key)" | grep -v "PASSWORD:" ; then
    echo "❌ ERROR: Posible credencial detectada"
    echo "Si es necesario, usa variables de entorno"
    exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```

---

## 📋 Checklist Post-Limpieza

- [ ] Cambié TODAS las credenciales
- [ ] Limpié el historial de Git
- [ ] Notifiqué al equipo
- [ ] Implementé variables de entorno
- [ ] Actualicé `.gitignore`
- [ ] Creé `.env.example`
- [ ] Documenté la configuración en `CONFIGURATION.md`
- [ ] Instalé `git-secrets` o pre-commit hooks
- [ ] Verifiqué que `.env` NO está en Git
- [ ] Actualicé credenciales en servidores de producción

---

## 🆘 Recursos Adicionales

- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- [git-secrets](https://github.com/awslabs/git-secrets)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

## ❓ Preguntas Frecuentes

### ¿Debo eliminar el repositorio y empezar de nuevo?
**No necesariamente.** Primero intenta limpiar el historial con BFG. Solo elimina el repo si:
- El historial es muy corto (pocos commits)
- No hay colaboradores externos
- Las credenciales eran de producción

### ¿Es suficiente con borrar el archivo y hacer commit?
**No.** Las credenciales siguen en el historial. Necesitas limpiar el historial o cambiar las credenciales.

### ¿Puedo usar GitHub's "Delete this repository"?
**Solo si es urgente y el proyecto es privado.** Pero es mejor limpiar el historial.

### Ya hice `git push --force`, ¿qué deben hacer los demás?
```bash
git fetch origin
git reset --hard origin/main
```

---

**🔒 La seguridad es responsabilidad de todos. Actúa rápido, documenta todo.**

