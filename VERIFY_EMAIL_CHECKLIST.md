# ✅ VERIFICACIÓN PASO A PASO: Email de Verificación

## 🎯 Objetivo
Confirmar que los usuarios reciben un correo de verificación al registrarse en AndiCrochett.

---

## 📋 LISTA DE VERIFICACIÓN

### PARTE 1: Código (✅ YA ESTÁ LISTO)

- [x] **AuthRepository.sendVerificationEmail()** 
  - Implementa ActionCodeSettings ✅
  - Maneja errores correctamente ✅
  - Lanza excepciones útiles ✅

- [x] **AuthProvider.register()**
  - Separa errores de registro y email ✅
  - Continúa si email falla ✅
  - Proporciona mensajes claros ✅

- [x] **AuthProvider.resendVerificationEmail()**
  - Reintentos simples ✅
  - Manejo de errores mejorado ✅

### PARTE 2: Firebase Console (⚠️ REQUIERE CONFIGURACIÓN)

- [ ] **Email/Password Provider**
  - [ ] Ve a: https://console.firebase.google.com/u/0/project/YOUR_PROJECT_ID/authentication/providers
  - [ ] Busca "Email/Password"
  - [ ] Haz clic en el lápiz (✏️)
  - [ ] Asegúrate que está **habilitado** (verde)
  - [ ] Haz clic en **Save**

- [ ] **Billing Email**
  - [ ] Ve a: https://console.firebase.google.com/u/0/project/YOUR_PROJECT_ID/settings/general
  - [ ] Busca "Billing email" en la sección Project
  - [ ] Si está vacío, **agrega tu email**
  - [ ] ⚠️ SIN ESTO, Firebase NO envía correos

- [ ] **Authorized Domains**
  - [ ] En la misma página, busca "Authorized domains"
  - [ ] Verifica que `localhost` está en la lista
  - [ ] Si falta, haz clic en "+ Add domain" y agrega `localhost`

- [ ] **Email Template**
  - [ ] Ve a: https://console.firebase.google.com/u/0/project/YOUR_PROJECT_ID/authentication/templates
  - [ ] Busca "Email verification"
  - [ ] Haz clic en el lápiz (✏️)
  - [ ] Verifica que el email contiene `[LINK]`
  - [ ] Personaliza si es necesario
  - [ ] Haz clic en **Save**

---

## 🧪 TEST: Probar el Registro

### Paso 1: Limpiar (Opcional)
```bash
# Elimina la BD local anterior
flutter clean
```

### Paso 2: Ejecutar la app
```bash
flutter run -d chrome --web-hostname localhost --web-port 5000
```

### Paso 3: Registrarse
1. Abre: `http://localhost:5000`
2. Haz clic en **"Registrate en segundos"** (o en "Crear una cuenta")
3. Ingresa:
   - **Email:** `tu_correo_real@gmail.com` (IMPORTANTE: usar un correo real)
   - **Contraseña:** `MiPassword123!`
   - **Confirmar:** `MiPassword123!`
4. Haz clic en **"Crear cuenta y enviar verificación"**

### Paso 4: Revisar Logs
En la **consola del navegador** (F12), busca:
```
✓ Email verification sent successfully
```

O en Firebase Console → Authentication → Users:
- El usuario debe aparecer con estado "Email Verified: No"

### Paso 5: Revisar el Correo
1. Abre tu bandeja de entrada en Gmail/Outlook
2. **Espera 5-30 segundos** (Firebase puede ser lento)
3. Busca un correo de Firebase
4. Si no aparece:
   - Revisa **Spam / Correo no deseado**
   - Espera más tiempo
   - Intenta con otro correo

### Paso 6: Verificar la Cuenta
1. Abre el enlace del correo
2. Verás una página de Firebase que dice "Email verified successfully"
3. En Firebase Console → Authentication → Users:
   - El estado ahora dice "Email Verified: Yes" ✅

### Paso 7: Iniciar Sesión
1. Vuelve a: `http://localhost:5000`
2. Haz clic en **"Iniciar sesión"**
3. Ingresa el correo y contraseña
4. ✅ Deberías poder entrar al dashboard

---

## 🔍 TROUBLESHOOTING

### CASO 1: "Cuenta creada pero no pudimos enviar el correo"

**Síntoma:**
```
⚠️ Cuenta creada, pero no pudimos enviar el correo: [error]
```

**Causa:** Firebase no puede enviar emails

**Soluciones (en orden):**

1. **Verificar Billing Email** (IMPORTANTE)
   - Ve a Project Settings
   - Busca "Billing email"
   - Si está vacío o says "No billing email", **AGREGA UNO**
   - Sin esto, Firebase NO envía correos

2. **Verificar Authorized Domains**
   - Ve a Authentication → Settings
   - Busca "Authorized domains"
   - Verifica que `localhost` está en la lista
   - Si falta, agrégalo

3. **Revisar Email Template**
   - Ve a Authentication → Templates
   - Abre "Email verification"
   - Verifica que contiene `[LINK]`
   - Si no, cópialo desde arriba

4. **Esperar 5+ minutos**
   - A veces Firebase tarda en configurar
   - Intenta otra vez

---

### CASO 2: El correo no llega después de 1 minuto

**Síntoma:**
```
Usuario registrado ✅
Pero bandeja de entrada vacía ❌
```

**Causa:** Posiblemente problemas de configuración o retrasos

**Soluciones:**

1. **Revisar Spam/Correo no deseado**
   - A veces Gmail/Outlook lo detecta como spam
   - Búscalo en "Correo no deseado"
   - Márcalo como "No es spam"

2. **Verificar que el correo fue enviado**
   - Ve a Firebase Console
   - Authentication → Users
   - Busca al usuario
   - Si dice "Email Verified: No", el correo fue enviado pero no abierto
   - Si dice "Email Verified: Yes", ya fue verificado ✅

3. **Intentar Reenvío**
   - En la app, haz clic en "Reenviar correo"
   - Espera 30+ segundos

4. **Usar otro correo**
   - A veces un correo específico tiene problemas
   - Intenta con Gmail, Outlook, Yahoo, etc.

---

### CASO 3: "Aún no vemos la verificación"

**Síntoma:**
```
Abrir el correo, verificar, pero la app dice "no verificado"
```

**Causa:** La app no ha recargado el estado

**Soluciones:**

1. **Hacer clic en "Ya verifiqué"**
   - La app recargará el estado desde Firebase
   - Si aparece un ✅, la verificación fue exitosa

2. **Refrescar la página manualmente**
   - F5 en el navegador
   - Intenta iniciar sesión de nuevo

3. **Verificar en Firebase Console**
   - Ve a Authentication → Users
   - Busca al usuario
   - ¿Dice "Email Verified: Yes"?
   - Si sí, la verificación fue exitosa en Firebase

---

### CASO 4: Errores en la Consola del Navegador

**Error Común:**
```
FirebaseError: Firebase is not initialized or you do not have permission to access 'messaging'
```

**Causa:** Problema de configuración de Firebase (no afecta emails)

**Solución:** Este error no impide que funcionen los emails. Ignóralo.

**Otro Error Común:**
```
[firebase_auth] Verification email could not be sent
```

**Causa:** Firebase no puede enviar el correo

**Soluciones:**
1. Verificar Billing email (arriba)
2. Verificar Authorized domains
3. Esperar 5+ minutos
4. Revisar email template

---

## ✅ VERIFICACIÓN FINAL

Si completaste todos los pasos y:

- [x] Me registré con un correo real
- [x] Revisé mi bandeja de entrada (y spam)
- [x] Abrí el correo de Firebase
- [x] Verifiqué la cuenta
- [x] Puedo iniciar sesión

**¡FELICIDADES! ✅ El email de verificación está funcionando.**

---

## 📞 Si TODAVÍA No Funciona

1. **Revisa esta lista en orden:**
   - [ ] Billing email configurado
   - [ ] Authorized domains incluye `localhost`
   - [ ] Email/Password provider activado
   - [ ] Email template con `[LINK]`

2. **Elimina la app y vuelve a registrarte:**
   - En Firebase Console → Authentication → Users
   - Elimina el usuario de prueba
   - Intenta registrarse de nuevo

3. **Espera 10+ minutos:**
   - A veces Firebase tarda en sincronizar cambios

4. **Revisa los logs:**
   - Firebase Console → Cloud Logging
   - Busca errores de `sendEmailVerification`

5. **Contacta a Firebase Support:**
   - Si nada funciona, abre un ticket con Google Cloud Support
   - Adjunta: Project ID, usuario de prueba, y errores

---

## 📚 Referencia Rápida

| Componente | Estado | Acción |
|-----------|--------|--------|
| Código | ✅ Listo | Ninguna |
| Email/Password | ❌ Manual | Ve a Firebase Console |
| Billing Email | ❌ Manual | Ve a Project Settings |
| Authorized Domains | ❌ Manual | Ve a Authentication → Settings |
| Email Template | ❌ Manual | Ve a Authentication → Templates |

---

## 🎓 Entender el Flujo

```
Usuario Registra
    ↓
App: register(email, password)
    ↓
Firebase Auth: createUserWithEmailAndPassword()
    ↓ (crea usuario con emailVerified: false)
Firestore: createUserProfile() 
    ↓ (guarda documento en 'users')
Firebase Auth: sendEmailVerification(ActionCodeSettings)
    ↓
Firebase: Envía correo con link de verificación
    ↓
Usuario: Abre correo, haz clic en link
    ↓
Firebase: Marca emailVerified: true
    ↓
Usuario: Puede iniciar sesión
```

---

## 🚀 Una Vez Que Funcione

Puedes:
- [x] Registrarse con verificación de email
- [x] Reenviar correo si no llega
- [x] Iniciar sesión solo si email está verificado
- [x] Recuperar contraseña (también envía email)

¡Todo el flujo de autenticación estará completo! 🎉
