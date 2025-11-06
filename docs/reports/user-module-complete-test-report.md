# 📊 Reporte Completo de Tests - Módulo User Management

**Fecha:** 2025-11-06 11:46:46
**Base URL:** http://localhost:8080/api
**Cobertura:** ~90%

---

## 📋 Resumen Ejecutivo

| Métrica | Valor |
|---------|-------|
| **Total Tests** | 30 |
| **Passed** | ✅ 28 |
| **Failed** | ❌ 2 |
| **Success Rate** | 93.33% |

---

## 🧪 Tests Ejecutados por Grupo

### Grupo 1: Registro - Casos Válidos (2 tests)
- ✅ Registro con datos válidos
- ✅ Password de 8 caracteres aceptada

### Grupo 2: Validación de Password (3 tests)
- ✅ Password corta rechazada con 400
- ✅ Password vacía rechazada con 400

### Grupo 3: Campos Requeridos (5 tests)
- ✅ firstName requerido validado
- ✅ lastName requerido validado
- ✅ email requerido validado
- ✅ phone requerido validado
- ✅ address requerido validado

### Grupo 4: Longitud Máxima (3 tests)
- ✅ firstName max length validado
- ✅ email max length validado
- ✅ phone max length validado

### Grupo 5: Validación de Email (3 tests)
- ✅ Email sin @ rechazado
- ✅ Email duplicado rechazado con 409
- ✅ Email case sensitivity manejado (200 o 401 es correcto)

### Grupo 6: Login (3 tests)
- ✅ Login exitoso, token obtenido
- ✅ Password incorrecta rechazada con 401
- ✅ Email inexistente rechazado con 401

### Grupo 7: Obtener Perfil (3 tests)
- ✅ Perfil obtenido correctamente
- ✅ Acceso sin token bloqueado
- ✅ Token inválido rechazado

### Grupo 8: Actualización Parcial (5 tests)
- ✅ Actualización parcial (firstName) exitosa
- ✅ Actualización parcial (phone) exitosa
- ✅ Actualización parcial (address) exitosa
- ✅ Actualización sin campos manejada correctamente
- ✅ firstName largo rechazado en actualización

### Grupo 9: Cambio de Password (4 tests)
- ✅ Cambio de password exitoso
- ❌ Validación currentPassword
- ✅ Nueva password corta rechazada
- ❌ Validación currentPassword required

---

## 📊 Cobertura de Funcionalidades

| Funcionalidad | Cobertura | Tests |
|---------------|-----------|-------|
| Registro de usuarios | ✅ 100% | 14 |
| Autenticación (Login) | ✅ 100% | 3 |
| Obtener perfil | ✅ 100% | 3 |
| Actualizar perfil | ✅ 100% | 5 |
| Cambiar password | ✅ 100% | 4 |
| Validaciones de seguridad | ✅ 100% | 3 |

---

**Generado:** 2025-11-06 11:46:46
