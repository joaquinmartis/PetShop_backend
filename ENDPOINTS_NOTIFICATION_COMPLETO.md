# Documentación Completa - Endpoints de Notificaciones

## 📋 Índice
1. [Preferencias de Notificación (Usuario)](#preferencias-de-notificación-usuario)
2. [Consulta de Notificaciones (Backoffice)](#consulta-de-notificaciones-backoffice)
3. [Implementación Frontend - WhatsApp Link](#-implementación-frontend---whatsapp-link-en-backoffice)
4. [Autenticación](#-autenticación)
5. [Estados y Canales de Notificación](#-estados-de-notificación)
6. [Flujo de Uso Completo](#-flujo-de-uso-completo)
7. [Testing y Solución de Problemas](#-testing)

---

## 🔔 Preferencias de Notificación (Usuario)

Estos endpoints permiten a los usuarios gestionar sus preferencias de notificación.

### 1. Crear Preferencias

**Endpoint:** `POST /api/notifications/preferences`

**Descripción:** Crea las preferencias de notificación para el usuario. Por defecto, todos los canales están desactivados.

**Autenticación:** ✅ Requerida (JWT Token)

**Rol requerido:** USER, ADMIN o WAREHOUSE

**Body (Opcional):**
```json
{
  "emailEnabled": true,
  "whatsappEnabled": true,
  "whatsappNumber": "+543515551234",
  "smsEnabled": true,
  "smsNumber": "+543515551234",
  "telegramEnabled": true,
  "telegramChatId": "123456789"
}
```

**Notas sobre el Body:**
- Si envías un body vacío `{}` o no envías body, se crearán preferencias con **todos los canales desactivados por defecto**
- Solo incluye los campos que deseas activar
- `whatsappNumber` y `smsNumber` deben incluir el código de país (ej: +54)
- `telegramChatId` es el ID de chat de Telegram

**Response exitoso (201 Created):**
```json
{
  "id": 1,
  "userId": 203,
  "emailEnabled": false,
  "whatsappEnabled": false,
  "whatsappNumber": null,
  "smsEnabled": false,
  "smsNumber": null,
  "telegramEnabled": false,
  "telegramChatId": null,
  "createdAt": "2025-11-28T20:21:13.898824",
  "updatedAt": "2025-11-28T20:21:13.898824"
}
```

**Errores posibles:**
- `409 Conflict`: Ya existen preferencias para este usuario
- `401 Unauthorized`: Token inválido o no enviado
- `500 Internal Server Error`: Error del servidor

---

### 2. Obtener Mis Preferencias

**Endpoint:** `GET /api/notifications/preferences`

**Descripción:** Retorna las preferencias de notificación del usuario autenticado.

**Autenticación:** ✅ Requerida (JWT Token)

**Rol requerido:** USER, ADMIN o WAREHOUSE

**Body:** No requiere

**Response exitoso (200 OK):**
```json
{
  "id": 1,
  "userId": 203,
  "emailEnabled": true,
  "whatsappEnabled": true,
  "whatsappNumber": "+543515551234",
  "smsEnabled": true,
  "smsNumber": "+543515551234",
  "telegramEnabled": true,
  "telegramChatId": "123456789",
  "createdAt": "2025-11-28T20:21:13.898824",
  "updatedAt": "2025-11-28T20:32:29.936788"
}
```

**Errores posibles:**
- `404 Not Found`: No se encontraron preferencias (debe crearlas primero con POST)
- `401 Unauthorized`: Token inválido o no enviado
- `500 Internal Server Error`: Error del servidor

---

### 3. Actualizar Preferencias

**Endpoint:** `PUT /api/notifications/preferences`

**Descripción:** Actualiza las preferencias de notificación del usuario. Solo actualiza los campos enviados en el body.

**Autenticación:** ✅ Requerida (JWT Token)

**Rol requerido:** USER, ADMIN o WAREHOUSE

**Body (Parcial - envía solo lo que quieres actualizar):**
```json
{
  "emailEnabled": true,
  "whatsappEnabled": false,
  "smsEnabled": true,
  "smsNumber": "+543519999999"
}
```

**Ejemplo - Activar solo Email:**
```json
{
  "emailEnabled": true
}
```

**Ejemplo - Activar WhatsApp con número:**
```json
{
  "whatsappEnabled": true,
  "whatsappNumber": "+543515551234"
}
```

**Response exitoso (200 OK):**
```json
{
  "id": 1,
  "userId": 203,
  "emailEnabled": true,
  "whatsappEnabled": false,
  "whatsappNumber": null,
  "smsEnabled": true,
  "smsNumber": "+543519999999",
  "telegramEnabled": false,
  "telegramChatId": null,
  "createdAt": "2025-11-28T20:21:13.898824",
  "updatedAt": "2025-11-28T21:15:42.123456"
}
```

**Errores posibles:**
- `404 Not Found`: No se encontraron preferencias (debe crearlas primero con POST)
- `401 Unauthorized`: Token inválido o no enviado
- `500 Internal Server Error`: Error del servidor

---

### 4. Verificar Estado de Preferencias

**Endpoint:** `GET /api/notifications/preferences/status`

**Descripción:** Verifica si el usuario tiene preferencias configuradas o no.

**Autenticación:** ✅ Requerida (JWT Token)

**Rol requerido:** USER, ADMIN o WAREHOUSE

**Body:** No requiere

**Response si EXISTEN preferencias (200 OK):**
```json
{
  "exists": true,
  "preferences": {
    "id": 1,
    "userId": 203,
    "emailEnabled": true,
    "whatsappEnabled": true,
    "whatsappNumber": "+543515551234",
    "smsEnabled": false,
    "smsNumber": null,
    "telegramEnabled": true,
    "telegramChatId": "123456789",
    "createdAt": "2025-11-28T20:21:13.898824",
    "updatedAt": "2025-11-28T20:32:29.936788"
  }
}
```

**Response si NO EXISTEN preferencias (200 OK):**
```json
{
  "exists": false,
  "message": "No tienes preferencias configuradas aún"
}
```

**Errores posibles:**
- `401 Unauthorized`: Token inválido o no enviado
- `500 Internal Server Error`: Error del servidor

---

## 🏢 Consulta de Notificaciones (Backoffice)

Este endpoint permite al backoffice consultar qué notificaciones se enviaron para cada pedido.

### 5. Obtener Notificaciones de un Pedido

**Endpoint:** `GET /api/backoffice/notifications/orders/{orderId}`

**Descripción:** Retorna todas las notificaciones enviadas para un pedido específico. Incluye el link de WhatsApp si fue enviado.

**Autenticación:** ✅ Requerida (JWT Token)

**Rol requerido:** WAREHOUSE (solo el personal de backoffice puede acceder)

**Parámetros de URL:**
- `orderId` (Long): ID del pedido a consultar

**Body:** No requiere

**Ejemplo de llamada:**
```
GET /api/backoffice/notifications/orders/225
```

**Response exitoso (200 OK):**
```json
[
  {
    "id": 5,
    "userId": 203,
    "orderId": 225,
    "channel": "EMAIL",
    "status": "FAILED",
    "message": "Hola gonzalo, desde VirtualPet te contamos que en el día de hoy estarás recibiendo en Av. Córdoba 1234, Córdoba Capital, Argentina el pedido #225 que has realizado en nuestro portal. Que tengas un buen día. Atte VirtualPet",
    "errorMessage": "Error al enviar email: Authentication failed",
    "recipient": "gonzaloleon@gmail.com",
    "sentAt": "2025-11-28T20:36:41.382724",
    "whatsappLink": null
  },
  {
    "id": 6,
    "userId": 203,
    "orderId": 225,
    "channel": "WHATSAPP",
    "status": "SENT",
    "message": "WhatsApp link generado",
    "errorMessage": null,
    "recipient": "+543515551234",
    "sentAt": "2025-11-28T20:36:41.385172",
    "whatsappLink": "https://wa.me/543515551234?text=Hola+gonzalo%2C+desde+VirtualPet..."
  },
  {
    "id": 7,
    "userId": 203,
    "orderId": 225,
    "channel": "SMS",
    "status": "SENT",
    "message": "Hola gonzalo, desde VirtualPet te contamos que en el día de hoy estarás recibiendo en Av. Córdoba 1234, Córdoba Capital, Argentina el pedido #225 que has realizado en nuestro portal. Que tengas un buen día. Atte VirtualPet",
    "errorMessage": null,
    "recipient": "+543515551234",
    "sentAt": "2025-11-28T20:36:41.488179",
    "whatsappLink": null
  },
  {
    "id": 8,
    "userId": 203,
    "orderId": 225,
    "channel": "TELEGRAM",
    "status": "SENT",
    "message": "Hola gonzalo, desde VirtualPet te contamos que en el día de hoy estarás recibiendo en Av. Córdoba 1234, Córdoba Capital, Argentina el pedido #225 que has realizado en nuestro portal. Que tengas un buen día. Atte VirtualPet",
    "errorMessage": null,
    "recipient": "123456789",
    "sentAt": "2025-11-28T20:36:41.491593",
    "whatsappLink": null
  }
]
```

**Campos del Response:**
- `id`: ID único del log de notificación
- `userId`: ID del usuario que recibió la notificación
- `orderId`: ID del pedido asociado
- `channel`: Canal usado (EMAIL, WHATSAPP, SMS, TELEGRAM)
- `status`: Estado (SENT, FAILED)
- `message`: Mensaje enviado
- `errorMessage`: Mensaje de error si falló (null si fue exitoso)
- `recipient`: Email, número de teléfono o chat ID según el canal
- `sentAt`: Fecha y hora de envío
- `whatsappLink`: Link de WhatsApp Web (solo para canal WHATSAPP, null para otros)

**Si no hay notificaciones para el pedido (200 OK):**
```json
[]
```

**Errores posibles:**
- `401 Unauthorized`: Token inválido o no enviado
- `403 Forbidden`: Usuario no tiene rol WAREHOUSE
- `500 Internal Server Error`: Error del servidor

---

### 📲 Implementación Frontend - WhatsApp Link en Backoffice

El frontend debe implementar la visualización del link de WhatsApp para que el empleado de depósito pueda contactar directamente al cliente.

#### 🎨 Cómo implementar en el Frontend:

**1. Hacer la petición al endpoint:**
```javascript
// Ejemplo con fetch
const getOrderNotifications = async (orderId, token) => {
  const response = await fetch(
    `http://localhost:8080/api/backoffice/notifications/orders/${orderId}`,
    {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  if (!response.ok) {
    throw new Error('Error al obtener notificaciones');
  }
  
  return await response.json();
};
```

**2. Filtrar y renderizar notificaciones de WhatsApp:**
```javascript
// React Example
const NotificationsList = ({ orderId, token }) => {
  const [notifications, setNotifications] = useState([]);

  useEffect(() => {
    getOrderNotifications(orderId, token)
      .then(data => setNotifications(data))
      .catch(err => console.error(err));
  }, [orderId]);

  return (
    <div className="notifications-container">
      <h3>Notificaciones Enviadas</h3>
      
      {notifications.map(notification => (
        <div key={notification.id} className="notification-item">
          <div className="notification-header">
            <span className={`badge ${notification.status.toLowerCase()}`}>
              {notification.status}
            </span>
            <span className="channel">{notification.channel}</span>
          </div>
          
          <div className="notification-body">
            <p><strong>Destinatario:</strong> {notification.recipient}</p>
            <p><strong>Enviado:</strong> {new Date(notification.sentAt).toLocaleString()}</p>
            
            {/* IMPORTANTE: Mostrar link de WhatsApp si existe */}
            {notification.channel === 'WHATSAPP' && notification.whatsappLink && (
              <div className="whatsapp-action">
                <a 
                  href={notification.whatsappLink} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="btn-whatsapp"
                >
                  📱 Abrir WhatsApp
                </a>
                <small className="help-text">
                  El empleado puede hacer clic aquí para contactar al cliente directamente
                </small>
              </div>
            )}
            
            {notification.errorMessage && (
              <div className="error-message">
                <strong>Error:</strong> {notification.errorMessage}
              </div>
            )}
          </div>
        </div>
      ))}
      
      {notifications.length === 0 && (
        <p className="no-notifications">No se enviaron notificaciones para este pedido</p>
      )}
    </div>
  );
};
```

**3. Ejemplo con HTML/JavaScript Vanilla:**
```javascript
async function renderOrderNotifications(orderId, token) {
  try {
    const response = await fetch(
      `http://localhost:8080/api/backoffice/notifications/orders/${orderId}`,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    const notifications = await response.json();
    const container = document.getElementById('notifications-container');
    
    if (notifications.length === 0) {
      container.innerHTML = '<p>No se enviaron notificaciones para este pedido</p>';
      return;
    }
    
    let html = '<div class="notifications-list">';
    
    notifications.forEach(notif => {
      html += `
        <div class="notification-card ${notif.status.toLowerCase()}">
          <div class="notification-header">
            <span class="badge">${notif.status}</span>
            <span class="channel">${notif.channel}</span>
          </div>
          <p><strong>Destinatario:</strong> ${notif.recipient}</p>
          <p><strong>Enviado:</strong> ${new Date(notif.sentAt).toLocaleString()}</p>
      `;
      
      // IMPORTANTE: Agregar botón de WhatsApp si existe el link
      if (notif.channel === 'WHATSAPP' && notif.whatsappLink) {
        html += `
          <div class="whatsapp-section">
            <a href="${notif.whatsappLink}" 
               target="_blank" 
               rel="noopener noreferrer"
               class="btn-whatsapp">
              📱 Contactar por WhatsApp
            </a>
            <small>Haz clic para abrir WhatsApp Web y contactar al cliente</small>
          </div>
        `;
      }
      
      if (notif.errorMessage) {
        html += `<div class="error">${notif.errorMessage}</div>`;
      }
      
      html += '</div>';
    });
    
    html += '</div>';
    container.innerHTML = html;
    
  } catch (error) {
    console.error('Error:', error);
    document.getElementById('notifications-container').innerHTML = 
      '<p class="error">Error al cargar notificaciones</p>';
  }
}
```

**4. CSS sugerido para el botón de WhatsApp:**
```css
.whatsapp-action {
  margin-top: 1rem;
  padding: 1rem;
  background-color: #e8f5e9;
  border-radius: 8px;
  border-left: 4px solid #25d366;
}

.btn-whatsapp {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  background-color: #25d366;
  color: white;
  text-decoration: none;
  border-radius: 6px;
  font-weight: bold;
  transition: background-color 0.3s;
}

.btn-whatsapp:hover {
  background-color: #20ba5a;
}

.help-text {
  display: block;
  margin-top: 0.5rem;
  color: #666;
  font-size: 0.875rem;
}

.notification-item {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 1rem;
  margin-bottom: 1rem;
  background-color: white;
}

.badge {
  padding: 0.25rem 0.75rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: bold;
  text-transform: uppercase;
}

.badge.sent {
  background-color: #4caf50;
  color: white;
}

.badge.failed {
  background-color: #f44336;
  color: white;
}

.channel {
  padding: 0.25rem 0.75rem;
  background-color: #e3f2fd;
  color: #1976d2;
  border-radius: 4px;
  font-size: 0.875rem;
  font-weight: 500;
}

.error-message {
  margin-top: 0.5rem;
  padding: 0.75rem;
  background-color: #ffebee;
  border-left: 4px solid #f44336;
  border-radius: 4px;
  color: #c62828;
}
```

#### 🔑 Puntos Clave para el Frontend:

1. **Siempre verificar `channel === 'WHATSAPP'`** antes de mostrar el link
2. **Verificar que `whatsappLink !== null`** antes de renderizar el botón
3. **Usar `target="_blank"`** para abrir WhatsApp en una nueva pestaña
4. **Agregar `rel="noopener noreferrer"`** por seguridad
5. **Indicar claramente al empleado** que puede hacer clic para contactar al cliente
6. **Mostrar el estado de la notificación** (SENT/FAILED) de forma visual
7. **Si `status === 'FAILED'`**, mostrar el `errorMessage` para debugging

#### 📱 Comportamiento esperado:

Cuando el empleado de depósito haga clic en el link de WhatsApp:
1. Se abrirá WhatsApp Web (o la app móvil si está en celular)
2. Se abrirá el chat con el número del cliente
3. El mensaje de notificación estará **prellenado** y listo para enviar
4. El empleado puede enviar el mensaje tal cual o editarlo antes de enviar

#### ✅ Ventajas de esta implementación:

- **Un solo clic** para contactar al cliente
- **Mensaje prellenado** con toda la info del pedido
- **No requiere copiar/pegar** números de teléfono
- **Funciona en desktop y móvil**
- **Mantiene historial** de qué notificaciones se enviaron

---

## 🔐 Autenticación

Todos los endpoints requieren autenticación mediante JWT Token en el header:

```
Authorization: Bearer <tu_token_jwt>
```

### Cómo obtener el token:
1. Login: `POST /api/auth/login`
```json
{
  "email": "usuario@example.com",
  "password": "tu_contraseña"
}
```

2. Usar el token en los headers:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 📊 Estados de Notificación

Las notificaciones pueden tener los siguientes estados:

- **SENT**: Notificación enviada exitosamente
- **FAILED**: Error al enviar la notificación (ver `errorMessage` para detalles)

---

## 📱 Canales de Notificación

### EMAIL
- Requiere configuración SMTP en `application.properties`
- El usuario debe tener un email válido en su perfil
- Status `FAILED` si hay problemas de autenticación SMTP

### WHATSAPP
- Genera un link de WhatsApp Web
- Requiere `whatsappNumber` con código de país (+54...)
- El link permite abrir WhatsApp con el mensaje prellenado
- Formato del link: `https://wa.me/{numero}?text={mensaje_codificado}`

### SMS
- **Simulado** en esta versión
- Registra el envío en la base de datos pero no envía SMS reales
- Requiere `smsNumber` con código de país

### TELEGRAM
- Envía mensaje vía API de Telegram
- Requiere:
  - Token del bot configurado en `application.properties`
  - `telegramChatId` del usuario
- Status `FAILED` si el token es inválido o el chat ID no existe

---

## 🎯 Flujo de Uso Completo

### Para el Frontend (Usuario):

1. **Usuario se registra** → `POST /api/auth/register`
2. **Usuario hace login** → `POST /api/auth/login` (obtiene JWT)
3. **Usuario crea preferencias** → `POST /api/notifications/preferences`
   - Puede activar/desactivar canales
   - Puede dejar todo desactivado (no recibirá notificaciones)
4. **Usuario actualiza preferencias** → `PUT /api/notifications/preferences`
   - Puede cambiar canales activos
   - Puede actualizar números de teléfono
5. **Usuario consulta sus preferencias** → `GET /api/notifications/preferences`

### Para el Backoffice:

1. **Admin hace login** → `POST /api/auth/login` con cuenta warehouse
2. **Admin cambia estado de pedido a DELIVERED** → `PUT /api/orders/{orderId}/status`
   - Esto dispara automáticamente el envío de notificaciones
3. **Admin consulta qué notificaciones se enviaron** → `GET /api/backoffice/notifications/orders/{orderId}`
   - Ve si se enviaron exitosamente
   - Ve el link de WhatsApp si corresponde
   - Ve errores si hubo problemas

---

## ⚠️ Notas Importantes

1. **Las notificaciones se envían automáticamente** cuando un pedido cambia a estado `DELIVERED`
2. **Solo se envían notificaciones a canales activos** en las preferencias del usuario
3. **Si el usuario no tiene preferencias o todos los canales están desactivados**, no se envía ninguna notificación
4. **El link de WhatsApp** solo está disponible para notificaciones del canal WHATSAPP
5. **El endpoint de backoffice** solo es accesible por usuarios con rol WAREHOUSE
6. **Los números de teléfono** deben incluir el código de país (ej: +54...)

---

## 🧪 Testing

Para probar los endpoints, puedes usar herramientas como:
- Postman
- Thunder Client (extensión de VS Code)
- cURL desde terminal

Ejemplo con cURL:
```bash
# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"usuario@example.com","password":"password123"}'

# Crear preferencias (con el token obtenido)
curl -X POST http://localhost:8080/api/notifications/preferences \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN_AQUI" \
  -d '{"emailEnabled":true,"whatsappEnabled":true,"whatsappNumber":"+543515551234"}'

# Obtener preferencias
curl -X GET http://localhost:8080/api/notifications/preferences \
  -H "Authorization: Bearer TU_TOKEN_AQUI"
```

---

## 🆘 Solución de Problemas

### Error 401 Unauthorized
- Verifica que el token JWT sea válido
- Verifica que el token no haya expirado
- Verifica que el header `Authorization: Bearer <token>` esté bien formado

### Error 403 Forbidden
- Verifica que tu usuario tenga el rol correcto
- El endpoint de backoffice requiere rol WAREHOUSE

### Error 404 Not Found (en GET preferences)
- El usuario aún no creó sus preferencias
- Usar `POST /api/notifications/preferences` primero

### Error 409 Conflict (en POST preferences)
- El usuario ya tiene preferencias creadas
- Usar `PUT /api/notifications/preferences` para actualizar

### Notificación no se envió
- Verifica que el usuario tenga preferencias activas
- Verifica que el canal específico esté activado
- Consulta los logs con el endpoint de backoffice para ver errores

---

Documentación generada el 29/11/2025

