# 📊 Reporte de Tests - Módulo User Management

**Fecha:** 2025-11-06 11:25:49
**Base URL:** http://localhost:8080/api

---

## 📋 Resumen Ejecutivo

| Métrica | Valor |
|---------|-------|
| **Total Tests** | 13 |
| **Passed** | ✅ 13 |
| **Failed** | ❌ 0 |
| **Success Rate** | 100.00% |

---

## 🧪 Tests Ejecutados

1. Registrar usuario válido → **✅**
2. Registrar email duplicado (409) → **✅**
3. Registrar email inválido (400) → **✅**
4. Registrar sin campos (400) → **✅**
5. Login válido con token → **✅**
6. Login password incorrecta (401) → **✅**
7. Login email no existe (401) → **✅**
8. Obtener perfil con token → **✅**
9. Obtener perfil sin token (403) → **✅**
10. Obtener perfil token inválido (403) → **✅**
11. Actualizar perfil con datos → **✅**
12. Actualizar perfil sin token (403) → **✅**
13. Login con datos vacíos (400) → **✅**

---

**Generado:** 2025-11-06 11:25:49
