# QuickDrop Client App

Super App de Delivery estilo Rappi para clientes.

Permite pedir comida, supermercado, farmacia, mensajería y más con seguimiento en tiempo real.

---

# 1. Visión del producto

QuickDrop es una aplicación móvil que permite a los usuarios solicitar productos o servicios desde múltiples comercios cercanos y recibirlos mediante repartidores en tiempo real.

La aplicación está inspirada en plataformas líderes como:

- Rappi
- Uber Eats
- DoorDash

---

# 2. Objetivos del sistema

El sistema busca:

• facilitar pedidos desde el móvil  
• ofrecer múltiples categorías de comercio  
• permitir seguimiento del pedido en tiempo real  
• simplificar el proceso de pago  
• mejorar la experiencia de entrega

---

# 3. Plataformas soportadas

Mobile

- iOS
- Android

Framework recomendado

Flutter

Alternativas

- React Native

---

# 4. Tipos de usuarios del sistema

El ecosistema completo incluye:

1. Cliente
2. Repartidor
3. Comercio
4. Administrador
5. Super Admin

Este repositorio corresponde **solo al cliente**.

---

# 5. Flujo principal del usuario


Splash
↓
Onboarding
↓
Login
↓
OTP Verification
↓
Seleccionar ubicación
↓
Home
↓
Seleccionar categoría
↓
Seleccionar tienda
↓
Seleccionar productos
↓
Carrito
↓
Checkout
↓
Pago
↓
Tracking
↓
Entrega


---

# 6. Navegación principal

La aplicación utiliza **Bottom Navigation**.


Home
Buscar
Pedidos
Favoritos
Perfil


---

# 7. Arquitectura recomendada

Clean Architecture


lib/

core
│
├── config
├── constants
├── theme
├── utils
│

data
│
├── models
├── repositories
├── datasources
│

domain
│
├── entities
├── usecases
├── repositories
│

presentation
│
├── screens
├── widgets
├── controllers
├── providers
│
app.dart
main.dart


Gestor de estado recomendado

Riverpod

---

# 8. Pantallas de la aplicación

Lista completa de pantallas:

1. Splash
2. Onboarding
3. Login
4. OTP Verification
5. Selección de dirección
6. Home
7. Categorías
8. Lista de tiendas
9. Detalle de tienda
10. Detalle de producto
11. Carrito
12. Checkout
13. Selección de pago
14. Confirmación de pedido
15. Tracking del pedido
16. Chat con repartidor
17. Historial de pedidos
18. Favoritos
19. Perfil
20. Métodos de pago
21. Direcciones
22. Promociones
23. Soporte
24. Configuración

---

# 9. Splash Screen

Función:

• inicializar aplicación  
• cargar configuración  
• verificar sesión  

UI

Logo centrado  
Nombre de la app  
Animación loading

---

# 10. Onboarding

Explica el valor de la app.

Pantalla 1

Pide lo que quieras.

Pantalla 2

Seguimiento en tiempo real.

Pantalla 3

Entrega rápida.

---

# 11. Login

Autenticación mediante número de teléfono.

Campos


phone_number


Botón


Continuar


---

# 12. Verificación OTP

Código de 4 o 6 dígitos.

Acciones

• verificar código  
• reenviar código  

---

# 13. Selección de ubicación

El usuario debe seleccionar la dirección de entrega.

Métodos disponibles

- mapa
- búsqueda de dirección
- ubicación actual
- direcciones guardadas

---

# 14. Home

Componentes principales:

• barra superior de dirección  
• barra de búsqueda  
• promociones  
• categorías  
• tiendas cercanas  

---

# 15. Categorías principales


Restaurantes
Supermercado
Farmacia
Mascotas
Regalos
Mensajería


---

# 16. Lista de tiendas

Información mostrada:

• imagen  
• nombre  
• rating  
• tiempo de entrega  
• costo de envío  
• promociones  

---

# 17. Detalle de tienda

Contiene:

• banner  
• información de tienda  
• menú de categorías  
• lista de productos  

---

# 18. Producto

Información del producto:


name
description
price
image
options


Acciones:


Agregar al carrito


---

# 19. Carrito

Muestra:

• productos seleccionados  
• cantidad  
• subtotal  
• envío  
• total  

Acciones:


Editar
Eliminar
Continuar al pago


---

# 20. Checkout

Resumen del pedido.

Elementos:

• dirección  
• método de pago  
• resumen  

---

# 21. Métodos de pago

Tipos soportados:


Tarjeta crédito
Tarjeta débito
Wallet
Efectivo
Apple Pay
Google Pay


---

# 22. Tracking del pedido

Mapa en tiempo real.

Estados:


Pedido recibido
Preparando
Repartidor asignado
En camino
Entregado


Funcionalidades:

• mapa en vivo  
• chat  
• llamada  

---

# 23. Historial de pedidos

Lista de pedidos anteriores.

Acciones:

• ver detalle  
• reordenar  

---

# 24. Favoritos

El usuario puede guardar:

• tiendas  
• productos  

---

# 25. Perfil del usuario

Información:


name
phone
email
photo


Opciones:


Direcciones
Métodos de pago
Promociones
Soporte
Configuración
Cerrar sesión


---

# 26. Notificaciones

Tipos de notificación:

• pedido aceptado  
• pedido en preparación  
• repartidor asignado  
• pedido en camino  
• pedido entregado  
• promociones  

---

# 27. Estados del pedido


CREATED
ACCEPTED
PREPARING
PICKED_UP
ON_THE_WAY
DELIVERED
CANCELLED


---

# 28. Componentes UI reutilizables


AppButton
AppInput
AppCard
RestaurantCard
ProductCard
MiniCart
OrderCard
CategoryItem
RatingStars
AddressSelector
PaymentSelector


---

# 29. Sistema de diseño

Colores

Primary


#FF441F


Secondary


#1E1E1E


Background


#F7F7F7


Success


#27AE60


---

# 30. Tipografía


Inter
Roboto
SF Pro


---

# 31. Animaciones

• skeleton loading  
• animación carrito  
• movimiento del repartidor  
• pull to refresh  

---

# 32. Estados de UI


Loading
Empty
Error
Offline


---

# 33. Seguridad

• autenticación OTP  
• validación de sesión  
• protección de endpoints  
• cifrado HTTPS  

---

# 34. Escalabilidad

El sistema debe permitir:

• múltiples ciudades  
• miles de comercios  
• miles de pedidos simultáneos  

---

# 35. Roadmap

Fase 1

MVP

• login  
• pedidos  
• tracking  

Fase 2

• promociones  
• favoritos  
• chat  

Fase 3

• suscripción premium  
• pedidos programados  
• cupones  

---

# 36. Resultado esperado

Este proyecto permite construir:

• MVP funcional  
• aplicación escalable  
• plataforma de delivery completa

---

# 37. Licencia

Propietario