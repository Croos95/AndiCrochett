# Configuración de Firebase para Email Verification

## ⚠️ Problema: El email de verificación no se está enviando

Si los usuarios se registran correctamente en Firestore pero **no reciben el correo de verificación**, sigue estos pasos:

---

## ✅ Solución: Configurar Firebase Console

### 1️⃣ Ir a Firebase Console

1. Abre [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto **andicrochett**
3. Ve a **Authentication** (Autenticación)

### 2️⃣ Habilitar Email/Password Provider

1. En la pestaña **Sign-in method** (Método de inicio de sesión)
2. Busca **Email/Password**
3. Haz clic en el lápiz ✏️ para editar
4. Activa:
   - ✅ **Email/Password** (necesario)
   - ✅ **Email link sign-in (passwordless)** (opcional)
5. Haz clic en **Save** (Guardar)

### 3️⃣ Configurar Template de Email (Importante)

1. En Authentication → **Templates** (Plantillas)
2. Busca **Email verification** (Verificación de correo)
3. Haz clic en el lápiz ✏️

#### Personaliza el email:

**Asunto:**
```
Verifica tu cuenta en AndiCrochett
```

**Correo:**
```html
Hola,

Gracias por registrarte en AndiCrochett.

Para completar tu registro y acceder al panel administrativo, 
haz clic en el enlace de abajo dentro de las próximas 24 horas:

[LINK]

Si no solicitaste este correo, ignóralo.

Saludos,
El equipo de AndiCrochett
```

4. **Asegúrate de incluir `[LINK]`** - Firebase lo reemplaza automáticamente
5. Haz clic en **Save** (Guardar)

### 4️⃣ Configurar Dominio Autorizado

1. En Authentication → **Settings** (Configuración)
2. Busca **Authorized domains** (Dominios autorizados)
3. **Verifica que `localhost` está en la lista**:
   - ✅ `localhost` (para desarrollo local)
   - ✅ Tu dominio de producción (cuando depliegues)
4. Si falta, haz clic en **Add domain** (Agregar dominio)

### 5️⃣ Verificar Información de Contacto del Proyecto (Crítico)

1. Ve a **Project settings** (Configuración del proyecto)
   - Haz clic en el engranaje ⚙️ en la esquina superior izquierda
   - Selecciona **Project settings**

2. En la pestaña **General**, busca **Project ID** y cópialo

3. Baja a **Billing email** (Correo de facturación)
   - **DEBE estar configurado** para que Firebase envíe correos
   - Si falta, añade un email válido

4. Verifica que tu **país** está correcto

### 6️⃣ Habilitar SMTP (Opcional pero Recomendado)

Si los correos siguen sin llegar:

1. Ve a **Authentication → Templates**
2. En la esquina superior derecha, busca **Email provider** (Proveedor de email)
3. Selecciona **Firebase Emails** (Por defecto)
   - O configura tu propio **SMTP** si tienes credenciales

### 7️⃣ Probar el Envío de Email

```bash
# 1. Ejecuta la app en modo desarrollo
flutter run -d chrome --web-hostname localhost --web-port 5000

# 2. Registra un usuario de prueba
# Usa un correo real que puedas verificar

# 3. Espera 5-30 segundos (Firebase puede ser lento)

# 4. Revisa la bandeja de entrada (y spam)
```

---

## 🔍 Troubleshooting

### El correo no llega después de 1 minuto

| Síntoma | Solución |
|---------|----------|
| **No aparece en Spam** | Verifica que `localhost` esté en "Authorized domains" |
| **La cuenta se crea pero no el email** | Revisa que el **Billing email** está configurado |
| **Error 400 en la consola** | El dominio dinámico no está configurado |
| **Usuario muestra `emailVerified: false`** | El usuario aún no ha abierto el enlace del correo |

### Verificar logs en Firebase

1. Ve a **Cloud Functions** (si usas functions)
2. Busca la función `onUserCreate` o similar
3. Revisa los logs para errores

### Verificar que el correo se envió desde el servidor

En la terminal Flutter, busca:
```
[firebase_auth] Sending verification email...
[firebase_auth] ✓ Email verification sent successfully
```

Si no ves esto, el correo **nunca** fue enviado.

---

## 💡 Notas Importantes

### ✅ Lo que está correcto en el código

El código ahora incluye:
- `ActionCodeSettings` con dominio dinámico
- Mejor manejo de errores
- Mensajes descriptivos al usuario
- Reintento de reenvío

### ⚠️ Lo que podría fallar

1. **Email/Password no activado** → Activarlo en Firebase Console
2. **Billing email no configurado** → Firebase NO envía correos sin esto
3. **Dominio no autorizado** → Agregar `localhost` a authorized domains
4. **Template vacío o sin [LINK]** → Crear/editar template correctamente
5. **Conexión a internet lenta** → Esperar más tiempo

---

## 🚀 Verificar que funciona

### Paso 1: Registrar un usuario

```
Email: prueba@gmail.com
Password: 123456
```

### Paso 2: Verificar en Firebase Console

- Ve a **Authentication → Users**
- Busca el email registrado
- Debería estar con `Email Verified: No`

### Paso 3: Revisar el correo

- Revisa tu bandeja de entrada (y spam)
- Deberías recibir un correo con un enlace
- **Si no llega en 2 minutos**, sigue los pasos de troubleshooting

### Paso 4: Verificar la cuenta

- Abre el enlace del correo
- Firebase marcará la cuenta como `emailVerified: true`
- Ahora puedes iniciar sesión en la app

---

## 📞 Contacto / Más Ayuda

Si aún tienes problemas:

1. Revisa los **Cloud Logs** en Firebase Console
2. Verifica que el **email del proyecto** (billing email) existe
3. Intenta con otro dominio de correo (no usar dominios `@example.com`)
4. Revisa la [documentación oficial de Firebase](https://firebase.google.com/docs/auth/custom-email-handler)

---

## 🔗 Referencia Rápida de URLs

| Servicio | URL |
|----------|-----|
| Firebase Console | https://console.firebase.google.com/ |
| Proyecto AndiCrochett | https://console.firebase.google.com/project/andicrochett-YOUR_PROJECT_ID |
| Authentication | https://console.firebase.google.com/u/0/project/YOUR_PROJECT_ID/authentication/providers |
| Email Templates | https://console.firebase.google.com/u/0/project/YOUR_PROJECT_ID/authentication/templates |
| Project Settings | https://console.firebase.google.com/u/0/project/YOUR_PROJECT_ID/settings/general |
