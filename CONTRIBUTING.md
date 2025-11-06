# Guía de Contribución

¡Gracias por tu interés en contribuir a Virtual Pet E-Commerce! 🐾

## 🌟 Cómo Contribuir

### 1. Fork y Clone
```bash
# Fork el repositorio en GitHub
# Luego clona tu fork
git clone https://github.com/tu-usuario/virtual-pet.git
cd virtual-pet
```

### 2. Crear una Rama
```bash
git checkout -b feature/mi-nueva-funcionalidad
# o
git checkout -b fix/correccion-de-bug
```

### 3. Hacer Cambios
- Escribe código limpio y documentado
- Sigue las convenciones de código existentes
- Agrega tests para nuevas funcionalidades
- Actualiza la documentación si es necesario

### 4. Commit
```bash
git add .
git commit -m "feat: agregar nueva funcionalidad X"
```

#### Convenciones de Commits
Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Nueva funcionalidad
- `fix:` Corrección de bug
- `docs:` Cambios en documentación
- `test:` Agregar o modificar tests
- `refactor:` Refactorización de código
- `style:` Cambios de formato (sin afectar código)
- `chore:` Tareas de mantenimiento

### 5. Push y Pull Request
```bash
git push origin feature/mi-nueva-funcionalidad
```

Luego abre un Pull Request en GitHub.

---

## 📋 Checklist para Pull Requests

- [ ] El código compila sin errores
- [ ] Todos los tests pasan
- [ ] Se agregaron tests para nuevas funcionalidades
- [ ] La documentación está actualizada
- [ ] El código sigue las convenciones del proyecto
- [ ] Los commits siguen Conventional Commits
- [ ] Se probó manualmente la funcionalidad

---

## 🧪 Ejecutar Tests

```bash
# Tests unitarios
mvn test

# Tests de integración
./scripts/setup/run-all-tests.sh
```

---

## 🎨 Estilo de Código

### Java
- Usar **camelCase** para variables y métodos
- Usar **PascalCase** para clases
- Indentar con **4 espacios** (no tabs)
- Máximo **120 caracteres** por línea
- Agregar JavaDoc a métodos públicos

### Ejemplo
```java
/**
 * Crea un nuevo pedido desde el carrito del usuario.
 *
 * @param userId ID del usuario
 * @param request Datos del pedido
 * @return Respuesta con el pedido creado
 */
public OrderResponse createOrder(Long userId, CreateOrderRequest request) {
    // Implementación
}
```

---

## 📁 Estructura de Módulos

Cada módulo debe seguir esta estructura:

```
module-name/
├── controller/
├── service/
├── repository/
├── dto/
│   ├── request/
│   └── response/
└── entity/
```

---

## 🐛 Reportar Bugs

Usa el [Issue Tracker](https://github.com/tu-usuario/virtual-pet/issues) con:

- **Descripción clara** del problema
- **Pasos para reproducir**
- **Comportamiento esperado vs actual**
- **Logs o screenshots** si es posible
- **Versión** del proyecto

---

## 💡 Sugerir Funcionalidades

Abre un Issue con:

- **Descripción** de la funcionalidad
- **Caso de uso**
- **Beneficio** esperado
- **Implementación sugerida** (opcional)

---

## 📞 Contacto

- **Issues**: [GitHub Issues](https://github.com/tu-usuario/virtual-pet/issues)
- **Discusiones**: [GitHub Discussions](https://github.com/tu-usuario/virtual-pet/discussions)

---

¡Gracias por contribuir! 🙏✨

