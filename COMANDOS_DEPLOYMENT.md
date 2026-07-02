# 🚀 COMANDOS PARA DESPLEGAR - Ejecutar en orden

## 📋 PARTE 1: DESPLEGAR BACKEND

### Paso 1: Ir a la carpeta del backend
```bash
cd c:\Users\USER\Documents\JalatonJuC\demo
```

### Paso 2: Crear namespace del backend
```bash
kubectl apply -f k8s/jhon-silva-00-namespace-be.yml
```

### Paso 3: Crear secrets del backend (con valores en base64)
```bash
kubectl apply -f k8s/jhon-silva-00-secret-be.yml
```

### Paso 4: Crear servicio LoadBalancer del backend
```bash
kubectl apply -f k8s/jhon-silva-00-service-be.yml
```

### Paso 5: Crear deployment del backend (2 pods)
```bash
kubectl apply -f k8s/jhon-silva-00-deployment-be.yml
```

### Paso 6: Ver el estado de los pods del backend
```bash
kubectl get pods -n jhon-silva-backend
```
**Espera hasta que veas**: `2/2 Running`

### Paso 7: Obtener la IP EXTERNA del backend (¡IMPORTANTE!)
```bash
kubectl get service jhon-silva-backend-service -n jhon-silva-backend
```
**Nota**: Si aparece `<pending>`, espera 1-2 minutos y ejecuta el comando de nuevo.

**COPIA LA EXTERNAL-IP** - La necesitarás para el frontend.

Ejemplo de salida:
```
NAME                          TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
jhon-silva-backend-service    LoadBalancer   10.96.45.123    34.123.45.67     8080:30123/TCP
```
En este caso, la IP es: **34.123.45.67**

### Paso 8: Probar que el backend funciona
```bash
# Reemplaza <IP-DEL-BACKEND> con la IP que obtuviste
curl http://<IP-DEL-BACKEND>:8080/api/users
```
Deberías ver los usuarios en formato JSON.

---

## 📋 PARTE 2: DESPLEGAR FRONTEND

### Paso 9: Convertir la URL del backend a base64

**IMPORTANTE**: Reemplaza `<IP-DEL-BACKEND>` con la IP que obtuviste en el Paso 7.

```bash
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://<IP-DEL-BACKEND>:8080'))"
```

**Ejemplo** (si tu IP fuera 34.123.45.67):
```bash
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://34.123.45.67:8080'))"
```

**COPIA EL RESULTADO** (será algo como: `aHR0cDovLzM0LjEyMy40NS42Nzo4MDgw`)

### Paso 10: Editar el secret del frontend

Abre el archivo:
```
c:\Users\USER\Documents\JalatonJuC\demo-front\k8s\jhon-silva-00-secret-fe.yml
```

Busca esta línea:
```yaml
API_URL: aHR0cDovLzxFWFRFUk5BTC1JUC1CQUNLRU5EPjo4MDgw
```

Reemplázala con el base64 que obtuviste en el Paso 9:
```yaml
API_URL: aHR0cDovLzM0LjEyMy40NS42Nzo4MDgw
```

**Guarda el archivo.**

### Paso 11: Ir a la carpeta del frontend
```bash
cd c:\Users\USER\Documents\JalatonJuC\demo-front
```

### Paso 12: Crear namespace del frontend
```bash
kubectl apply -f k8s/jhon-silva-00-namespace-fe.yml
```

### Paso 13: Crear secrets del frontend (con URL del backend en base64)
```bash
kubectl apply -f k8s/jhon-silva-00-secret-fe.yml
```

### Paso 14: Crear servicio LoadBalancer del frontend
```bash
kubectl apply -f k8s/jhon-silva-00-service-fe.yml
```

### Paso 15: Crear deployment del frontend (2 pods)
```bash
kubectl apply -f k8s/jhon-silva-00-deployment-fe.yml
```

### Paso 16: Ver el estado de los pods del frontend
```bash
kubectl get pods -n jhon-silva-frontend
```
**Espera hasta que veas**: `2/2 Running`

### Paso 17: Obtener la IP EXTERNA del frontend
```bash
kubectl get service jhon-silva-frontend-service -n jhon-silva-frontend
```
**Nota**: Si aparece `<pending>`, espera 1-2 minutos y ejecuta el comando de nuevo.

**COPIA LA EXTERNAL-IP** - Esta es tu aplicación web.

Ejemplo de salida:
```
NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
jhon-silva-frontend-service    LoadBalancer   10.96.78.234    35.234.56.78     80:31234/TCP
```
En este caso, la IP es: **35.234.56.78**

### Paso 18: Abrir la aplicación en el navegador
```
http://<IP-DEL-FRONTEND>
```

Ejemplo:
```
http://35.234.56.78
```

---

## ✅ VERIFICACIÓN COMPLETA

### Ver todo lo desplegado en backend
```bash
kubectl get all -n jhon-silva-backend
```

### Ver todo lo desplegado en frontend
```bash
kubectl get all -n jhon-silva-frontend
```

### Ver logs del backend (si hay problemas)
```bash
kubectl logs -n jhon-silva-backend -l app=jhon-silva-backend --tail=100
```

### Ver logs del frontend (si hay problemas)
```bash
kubectl logs -n jhon-silva-frontend -l app=jhon-silva-frontend --tail=100
```

---

## 🧪 PROBAR LOS ENDPOINTS DEL BACKEND

Una vez que tengas la IP del backend, prueba estos comandos:

### 1. Listar todos los usuarios
```bash
curl http://<IP-BACKEND>:8080/api/users
```

### 2. Obtener usuario por ID
```bash
curl http://<IP-BACKEND>:8080/api/users/1
```

### 3. Crear un nuevo usuario
```bash
curl -X POST http://<IP-BACKEND>:8080/api/users -H "Content-Type: application/json" -d "{\"username\":\"testuser\",\"email\":\"test@example.com\",\"firstName\":\"Test\",\"lastName\":\"User\",\"phone\":\"+51-999-888-777\",\"address\":\"Calle Test 123\"}"
```

### 4. Actualizar usuario (ID 1)
```bash
curl -X PUT http://<IP-BACKEND>:8080/api/users/1 -H "Content-Type: application/json" -d "{\"username\":\"updated\",\"email\":\"updated@example.com\",\"firstName\":\"Updated\",\"lastName\":\"User\",\"phone\":\"+51-999-888-777\",\"address\":\"Updated 456\",\"status\":\"ACTIVE\"}"
```

### 5. Activar usuario
```bash
curl -X PATCH http://<IP-BACKEND>:8080/api/users/1/activate
```

### 6. Desactivar usuario
```bash
curl -X PATCH http://<IP-BACKEND>:8080/api/users/1/deactivate
```

### 7. Suspender usuario
```bash
curl -X PATCH http://<IP-BACKEND>:8080/api/users/1/suspend
```

### 8. Eliminar usuario
```bash
curl -X DELETE http://<IP-BACKEND>:8080/api/users/1
```

### 9. Buscar usuarios por nombre
```bash
curl http://<IP-BACKEND>:8080/api/users?name=Juan
```

---

## 🔄 COMANDOS ÚTILES

### Reiniciar el backend
```bash
kubectl rollout restart deployment jhon-silva-backend-deployment -n jhon-silva-backend
```

### Reiniciar el frontend
```bash
kubectl rollout restart deployment jhon-silva-frontend-deployment -n jhon-silva-frontend
```

### Ver logs en tiempo real del backend
```bash
kubectl logs -n jhon-silva-backend -l app=jhon-silva-backend -f
```

### Ver logs en tiempo real del frontend
```bash
kubectl logs -n jhon-silva-frontend -l app=jhon-silva-frontend -f
```

### Escalar el backend a 3 réplicas
```bash
kubectl scale deployment jhon-silva-backend-deployment --replicas=3 -n jhon-silva-backend
```

### Escalar el frontend a 3 réplicas
```bash
kubectl scale deployment jhon-silva-frontend-deployment --replicas=3 -n jhon-silva-frontend
```

---

## 🗑️ ELIMINAR TODO (si necesitas empezar de nuevo)

### Eliminar backend completo
```bash
kubectl delete namespace jhon-silva-backend
```

### Eliminar frontend completo
```bash
kubectl delete namespace jhon-silva-frontend
```

---

## 📊 RESUMEN DE IPs

Al final tendrás 2 IPs importantes:

1. **Backend API**: `http://<IP-BACKEND>:8080`
   - Ejemplo: `http://34.123.45.67:8080/api/users`

2. **Frontend Web**: `http://<IP-FRONTEND>`
   - Ejemplo: `http://35.234.56.78`

---

## ✅ CHECKLIST FINAL

- [ ] Backend pods corriendo (2/2)
- [ ] Backend service tiene EXTERNAL-IP
- [ ] Backend responde a curl
- [ ] Secret del frontend actualizado con IP del backend en base64
- [ ] Frontend pods corriendo (2/2)
- [ ] Frontend service tiene EXTERNAL-IP
- [ ] Frontend abre en navegador
- [ ] Frontend muestra lista de usuarios
- [ ] Puedo crear/editar/eliminar usuarios desde el frontend
- [ ] Botones de estado funcionan (Activar/Desactivar/Suspender)

---

## 🎉 ¡LISTO!

Si todos los pasos están completos, tu aplicación está corriendo en Kubernetes con:
- ✅ Backend reactivo (Spring WebFlux)
- ✅ Frontend moderno (Angular 21)
- ✅ Base de datos en la nube (Neon PostgreSQL)
- ✅ Alta disponibilidad (2 réplicas por servicio)
- ✅ Secrets en base64 como debe ser
