# 🚑 AMIGA - Aplicación de Manejo Integral de Gestión de Ambulancias

## Descripción
AMIGA es una aplicación web profesional para la gestión completa de empresas de ambulancias, desarrollada con React, Node.js y PostgreSQL.

## Módulos Disponibles

### 📊 Dashboard
- Estadísticas en tiempo real
- Alertas recientes
- Acciones rápidas

### 🚑 Gestión de Vehículos
- CRUD completo
- Búsqueda y filtros
- 4 pestañas de información
- Exportación a CSV

### 👥 Gestión de Empleados
- CRUD completo
- Gestión de documentos
- 5 pestañas de información
- Exportación a CSV

### 🏢 Gestión de Empresas
- CRUD completo
- Documentación empresarial
- Información bancaria y fiscal
- 5 pestañas

### 🤝 Gestión de Clientes
- CRUD completo
- Gestión de servicios
- Información de facturación
- 5 pestañas

### 🤖 Gestión de Proveedores
- CRUD completo
- Gestión de servicios y productos
- Información de precios
- 5 pestañas

### 📄 Gestión de Facturas
- CRUD completo (emitidas y recibidas)
- Generador de líneas de factura
- Cálculos automáticos
- Exportación CSV y PDF

## Tecnologías

**Frontend:**
- React 18
- React Router
- Axios
- CSS3 Moderno

**Backend:**
- Node.js 16+
- Express.js
- PostgreSQL 14+
- JWT Authentication

## Instalación

### Requisitos
- Node.js 16+
- PostgreSQL 14+
- npm o yarn

### Pasos

1. Clonar repositorio
```bash
git clone https://github.com/fjcamachosti-alt/ambulance-management-system.git
cd ambulance-management-system
```

2. Instalar dependencias
```bash
npm install --prefix backend
npm install --prefix frontend
```

3. Configurar base de datos
```bash
psql -U postgres -f database/init.sql
```

4. Iniciar backend
```bash
cd backend
npm run dev
```

5. Iniciar frontend
```bash
cd frontend
npm start
```

6. Acceder a http://localhost:3000

## Credenciales por Defecto
- **Email:** apisistem@ambulance.local
- **Contraseña:** apisistem

## Estructura del Proyecto

```
ambulance-management-system/
├── frontend/
│   ├── src/
│   │   ├── pages/
│   │   │   ├── LoginPage.js
│   │   │   ├── Dashboard.js
│   │   │   ├── VehiclesPage.js
│   │   │   ├── EmployeesPage.js
│   │   │   ├── CompaniesPage.js
│   │   │   ├── ClientsPage.js
│   │   │   ├── SuppliersPage.js
│   │   │   └── InvoicesPage.js
│   │   ├── styles/
│   │   ├── services/
│   │   ├── contexts/
│   │   └── App.js
│   └── package.json
├── backend/
│   ├── src/
│   │   ├── routes/
│   │   ├── middleware/
│   │   ├── config/
│   │   └── server.js
│   └── package.json
├── database/
│   └── init.sql
└── README.md
```

## Características

✅ Autenticación JWT
✅ CRUD en todos los módulos
✅ Búsqueda y filtros avanzados
✅ Paginación
✅ Exportación a CSV
✅ Interfaz responsive
✅ Diseño moderno y profesional
✅ Validación de datos
✅ Base de datos relacional

## Licencia
MIT

## Autor
Desarrollado para gestión de ambulancias

## Soporte
Para soporte, contactar al equipo de desarrollo.
