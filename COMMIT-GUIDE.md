# 🚀 Comandos para Aplicar Cambios de Seguridad

## 📋 Estado Actual

Estos archivos están listos para ser commiteados:

```
NUEVOS ARCHIVOS:
 + CONFIGURATION.md                           (Guía de configuración)
 + SECURITY-CHANGES-SUMMARY.md                (Resumen de cambios)
 + SECURITY-INCIDENT-GUIDE.md                 (Guía de emergencia)
 + .env.example                               (Plantilla sin credenciales)
 + src/main/resources/application.properties.example (Plantilla)

ARCHIVOS MODIFICADOS:
 M .gitignore                                  (protege .env)
 M README.md                                   (sección de configuración)
 M src/main/resources/application.properties  (usa variables de entorno)

ARCHIVOS PROTEGIDOS (NO se subirán):
 - .env                                        (credenciales reales)
```

---

## ✅ Opción 1: Commit Seguro (RECOMENDADO)

```bash
cd /home/optimus/Desktop/VirtualPet

# 1. Verificar que .env NO está en staging
git status | grep .env
# NO debería mostrar .env (solo .env.example) ✅

# 2. Agregar archivos de configuración
git add .gitignore
git add .env.example
git add CONFIGURATION.md
git add SECURITY-CHANGES-SUMMARY.md
git add SECURITY-INCIDENT-GUIDE.md
git add src/main/resources/application.properties.example

# 3. Agregar archivos modificados
git add README.md
git add src/main/resources/application.properties

# 4. Verificar qué se va a commitear
git status

# 5. Hacer commit
git commit -m "🔒 Security: Implement environment variables for sensitive data

- Add .env.example template (without real credentials)
- Update .gitignore to protect .env files
- Modify application.properties to use environment variables
- Add comprehensive configuration documentation (CONFIGURATION.md)
- Add security incident guide (SECURITY-INCIDENT-GUIDE.md)
- Add security changes summary
- Update README.md with secure configuration section

BREAKING CHANGE: Developers must now copy .env.example to .env
and configure local credentials.

Refs: #security"

# 6. Push
git push origin main
```

---

## ⚠️ Opción 2: Si YA Subiste Credenciales (URGENTE)

**NO hagas push todavía. Primero limpia el historial:**

```bash
cd /home/optimus/Desktop/VirtualPet

# 1. Cambiar TODAS las credenciales
psql -U postgres
ALTER USER virtualpet_user WITH PASSWORD 'nueva_password_super_segura_$(openssl rand -hex 16)';
\q

# 2. Actualizar .env con nuevas credenciales
nano .env

# 3. Instalar BFG
brew install bfg

# 4. Hacer backup
cp -r /home/optimus/Desktop/VirtualPet /home/optimus/Desktop/VirtualPet-backup

# 5. Clonar mirror
cd /home/optimus/Desktop
git clone --mirror https://github.com/tu-usuario/VirtualPet.git VirtualPet-mirror
cd VirtualPet-mirror

# 6. Limpiar credenciales del historial
bfg --delete-files application.properties

# 7. Limpiar referencias
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 8. Forzar push (ADVERTENCIA: Reescribe historial)
git push --force

# 9. Volver al repositorio original
cd /home/optimus/Desktop/VirtualPet
git fetch origin
git reset --hard origin/main

# 10. Aplicar cambios de seguridad (Opción 1 de arriba)
```

---

## 🔍 Verificaciones Pre-Commit

```bash
# ✅ Verificar que .env NO está en Git
git ls-files | grep "^\.env$"
# Resultado esperado: (vacío) ✅

# ✅ Verificar que .env.example SÍ está
git ls-files | grep "\.env\.example"
# Resultado esperado: .env.example ✅

# ✅ Verificar contenido de application.properties
grep "DB_PASSWORD" src/main/resources/application.properties
# Resultado esperado: ${DB_PASSWORD:virtualpet123} ✅

# ✅ Verificar que .gitignore protege .env
git check-ignore .env
# Resultado esperado: .env ✅
```

---

## 📨 Mensaje para el Equipo (si aplica)

Si trabajas en equipo, notifica después del push:

```
🔒 CAMBIOS DE SEGURIDAD APLICADOS

Se han implementado variables de entorno para proteger credenciales sensibles.

ACCIONES REQUERIDAS:

1. Hacer pull de los cambios:
   git pull origin main

2. Copiar archivo de configuración:
   cp .env.example .env

3. Editar .env con tus credenciales locales:
   nano .env

4. Verificar que .env NO está en Git:
   git check-ignore .env
   # Debe mostrar: .env

5. Ejecutar la aplicación:
   mvn spring-boot:run

DOCUMENTACIÓN:
- CONFIGURATION.md - Guía completa de configuración
- README.md - Sección actualizada de configuración
- SECURITY-INCIDENT-GUIDE.md - Guía de emergencia

PREGUNTAS: Revisar CONFIGURATION.md o contactar al equipo.
```

---

## 🎯 Checklist Final

Antes de hacer push, verifica:

- [ ] `.env` NO está en staging (`git status` no lo muestra)
- [ ] `.env.example` SÍ está en staging
- [ ] `application.properties` usa variables de entorno (`${DB_PASSWORD}`)
- [ ] `.gitignore` protege `.env`
- [ ] Documentación completa agregada
- [ ] README.md actualizado
- [ ] Si ya subiste credenciales, las cambiaste

---

## 🚀 Comandos Rápidos (Copy-Paste)

```bash
# Verificar estado
cd /home/optimus/Desktop/VirtualPet
git status

# Agregar todos los archivos de seguridad
git add .gitignore .env.example CONFIGURATION.md SECURITY-CHANGES-SUMMARY.md SECURITY-INCIDENT-GUIDE.md src/main/resources/application.properties.example README.md src/main/resources/application.properties

# Verificar qué se va a commitear
git status

# Commit
git commit -m "🔒 Security: Implement environment variables for sensitive data"

# Push
git push origin main
```

---

## 🆘 Troubleshooting

### Problema: "Git quiere agregar .env"
```bash
# Verificar .gitignore
cat .gitignore | grep .env

# Si no está, agregarlo
echo ".env" >> .gitignore
git add .gitignore
git commit -m "Add .env to .gitignore"

# Remover .env del staging
git rm --cached .env
```

### Problema: "No tengo BFG instalado"
```bash
# Mac
brew install bfg

# Linux
sudo apt-get install bfg

# Manual
wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar
alias bfg='java -jar bfg-1.14.0.jar'
```

### Problema: "Mi equipo necesita actualizar"
```bash
# Notificar al equipo ANTES de hacer push --force
# Después, cada miembro debe:
git fetch origin
git reset --hard origin/main
cp .env.example .env
nano .env
```

---

**🎉 ¡Todo listo para aplicar los cambios de seguridad!**

---

*Generado: 2025-11-06*
*Proyecto: Virtual Pet E-Commerce*

