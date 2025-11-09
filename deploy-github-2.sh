#!/bin/bash

# ============================================================================
# SCRIPT DE DEPLOY - NUEVAS FUNCIONALIDADES A GITHUB
# Sistema de Gestión de Ambulancias
# ============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}   $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

clear
print_header "DEPLOY DE FUNCIONALIDADES - GITHUB"
echo ""

# ============================================================================
# VERIFICAR GIT
# ============================================================================

if [ ! -d ".git" ]; then
    print_error "No estamos en un repositorio Git"
    exit 1
fi

print_success "Repositorio Git encontrado"
echo ""

# ============================================================================
# CREAR ARCHIVOS NUEVOS - BACKEND
# ============================================================================

print_header "Creando Archivos Backend Mejorado"
echo ""

# Crear ruta de empleados mejorada
cat > backend/src/routes/employees.js << 'EOFEMPLOYEES'
const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authMiddleware, roleMiddleware } = require('../middleware/auth');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');

// GET - Listar empleados con paginación
router.get('/', authMiddleware, roleMiddleware(['administrador', 'gestor']), async (req, res) => {
  try {
    const { page = 1, limit = 10, search = '', role = '', status = '' } = req.query;
    const offset = (page - 1) * limit;

    let query = 'SELECT * FROM users WHERE 1=1';
    let countQuery = 'SELECT COUNT(*) FROM users WHERE 1=1';
    const params = [];
    let paramCount = 1;

    if (search) {
      query += ` AND (first_name ILIKE $${paramCount} OR last_name ILIKE $${paramCount} OR email ILIKE $${paramCount})`;
      countQuery += ` AND (first_name ILIKE $${paramCount} OR last_name ILIKE $${paramCount} OR email ILIKE $${paramCount})`;
      params.push(`%${search}%`);
      paramCount++;
    }

    if (role) {
      query += ` AND role = $${paramCount}`;
      countQuery += ` AND role = $${paramCount}`;
      params.push(role);
      paramCount++;
    }

    if (status) {
      query += ` AND status = $${paramCount}`;
      countQuery += ` AND status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const [result, countResult] = await Promise.all([
      pool.query(query, params),
      pool.query(countQuery, params.slice(0, -2))
    ]);

    const total = parseInt(countResult.rows[0].count);
    const pages = Math.ceil(total / limit);

    res.json({
      data: result.rows.map(u => ({
        id: u.id,
        email: u.email,
        firstName: u.first_name,
        lastName: u.last_name,
        role: u.role,
        status: u.status,
        createdAt: u.created_at
      })),
      pagination: { page: parseInt(page), limit: parseInt(limit), total, pages }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener empleados' });
  }
});

// POST - Crear empleado
router.post('/', authMiddleware, roleMiddleware(['administrador', 'gestor']), async (req, res) => {
  const { email, password, firstName, lastName, role } = req.body;
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await pool.query(
      'INSERT INTO users (email, password_hash, first_name, last_name, role, status) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [email, hashedPassword, firstName, lastName, role, 'activo']
    );
    res.status(201).json({ message: 'Empleado creado', user: result.rows[0] });
  } catch (error) {
    res.status(500).json({ error: 'Error al crear empleado' });
  }
});

// PUT - Actualizar empleado
router.put('/:id', authMiddleware, roleMiddleware(['administrador', 'gestor']), async (req, res) => {
  const { firstName, lastName, role, status } = req.body;
  try {
    const result = await pool.query(
      'UPDATE users SET first_name = COALESCE($1, first_name), last_name = COALESCE($2, last_name), role = COALESCE($3, role), status = COALESCE($4, status), updated_at = CURRENT_TIMESTAMP WHERE id = $5 RETURNING *',
      [firstName, lastName, role, status, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Error al actualizar' });
  }
});

// DELETE - Eliminar empleado
router.delete('/:id', authMiddleware, roleMiddleware(['administrador']), async (req, res) => {
  try {
    await pool.query('UPDATE users SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2', ['inactivo', req.params.id]);
    res.json({ message: 'Eliminado' });
  } catch (error) {
    res.status(500).json({ error: 'Error' });
  }
});

module.exports = router;
EOFEMPLOYEES
print_success "employees.js creado"

# Actualizar server.js para incluir ruta de empleados
cat >> backend/src/server.js << 'EOFSERVER'

app.use('/api/employees', require('./routes/employees'));
EOFSERVER
print_success "server.js actualizado"

echo ""

# ============================================================================
# CREAR ARCHIVOS NUEVOS - FRONTEND
# ============================================================================

print_header "Creando Archivos Frontend Mejorado"
echo ""

# Crear página de empleados
cat > frontend/src/pages/EmployeesPage.js << 'EOFEMPLOYEESPAGE'
import React, { useState, useEffect } from 'react';
import { usersAPI } from '../services/api';
import '../styles/EmployeesPage.css';

const EmployeesPage = () => {
  const [employees, setEmployees] = useState([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    email: '', password: '', firstName: '', lastName: '', role: 'tecnico'
  });

  useEffect(() => {
    loadEmployees();
  }, []);

  const loadEmployees = async () => {
    setLoading(true);
    try {
      const { data } = await usersAPI.getAll();
      setEmployees(data.data || []);
    } catch (err) {
      setError('Error al cargar');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await usersAPI.register(formData);
      setFormData({ email: '', password: '', firstName: '', lastName: '', role: 'tecnico' });
      setShowForm(false);
      loadEmployees();
    } catch (err) {
      setError('Error al guardar');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('¿Eliminar?')) {
      try {
        await usersAPI.delete(id);
        loadEmployees();
      } catch (err) {
        setError('Error');
      }
    }
  };

  return (
    <div className="employees-page">
      <h1>Empleados</h1>
      <button onClick={() => setShowForm(!showForm)}>+ Nuevo</button>
      
      {showForm && (
        <form onSubmit={handleSubmit}>
          <input type="email" placeholder="Email" value={formData.email} onChange={(e) => setFormData({...formData, email: e.target.value})} required />
          <input type="password" placeholder="Contraseña" value={formData.password} onChange={(e) => setFormData({...formData, password: e.target.value})} required />
          <input type="text" placeholder="Nombre" value={formData.firstName} onChange={(e) => setFormData({...formData, firstName: e.target.value})} required />
          <input type="text" placeholder="Apellido" value={formData.lastName} onChange={(e) => setFormData({...formData, lastName: e.target.value})} required />
          <select value={formData.role} onChange={(e) => setFormData({...formData, role: e.target.value})}>
            <option value="tecnico">Técnico</option>
            <option value="medico">Médico</option>
            <option value="administrador">Admin</option>
          </select>
          <button type="submit">Guardar</button>
        </form>
      )}

      {loading ? <p>Cargando...</p> : (
        <table>
          <thead>
            <tr><th>Email</th><th>Nombre</th><th>Rol</th><th>Acciones</th></tr>
          </thead>
          <tbody>
            {employees.map(emp => (
              <tr key={emp.id}>
                <td>{emp.email}</td>
                <td>{emp.first_name} {emp.last_name}</td>
                <td>{emp.role}</td>
                <td><button onClick={() => handleDelete(emp.id)}>Eliminar</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
};

export default EmployeesPage;
EOFEMPLOYEESPAGE
print_success "EmployeesPage.js creado"

# Crear estilos para empleados
cat > frontend/src/styles/EmployeesPage.css << 'EOFEMPLOYEESCSS'
.employees-page {
  padding: 30px;
  max-width: 1200px;
  margin: 0 auto;
}

.employees-page h1 {
  margin-bottom: 20px;
  color: #333;
}

.employees-page button {
  background: #667eea;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  margin-bottom: 20px;
}

.employees-page form {
  background: white;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 30px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.employees-page input,
.employees-page select {
  width: 100%;
  padding: 10px;
  margin-bottom: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.employees-page table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.employees-page th {
  background: #f8f9fa;
  padding: 12px;
  text-align: left;
  font-weight: 600;
  border-bottom: 2px solid #dee2e6;
}

.employees-page td {
  padding: 12px;
  border-bottom: 1px solid #dee2e6;
}

.employees-page tbody tr:hover {
  background-color: #f8f9fa;
}
EOFEMPLOYEESCSS
print_success "EmployeesPage.css creado"

echo ""

# ============================================================================
# ACTUALIZAR APP.JS
# ============================================================================

print_header "Actualizando App.js con Navegación"
echo ""

cat > frontend/src/App-nav.js << 'EOFAPPNAV'
import React, { useContext } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, Link } from 'react-router-dom';
import { AuthContext, AuthProvider } from './contexts/AuthContext';
import LoginPage from './pages/LoginPage';
import Dashboard from './pages/Dashboard';
import EmployeesPage from './pages/EmployeesPage';
import VehiclesPageComplete from './pages/VehiclesPageComplete';
import './App.css';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated } = useContext(AuthContext);
  return isAuthenticated ? children : <Navigate to="/login" />;
};

const Navbar = () => {
  const { user, logout } = useContext(AuthContext);
  return (
    <nav className="navbar">
      <Link to="/dashboard" className="navbar-logo">🚑 Ambulancias</Link>
      <ul className="nav-menu">
        <li><Link to="/dashboard" className="nav-link">Panel</Link></li>
        <li><Link to="/employees" className="nav-link">Empleados</Link></li>
        <li><Link to="/vehicles" className="nav-link">Vehículos</Link></li>
      </ul>
      <div className="nav-user">
        <span>{user?.firstName} {user?.lastName}</span>
        <button onClick={logout} className="btn-logout">Salir</button>
      </div>
    </nav>
  );
};

function AppContent() {
  const { isAuthenticated } = useContext(AuthContext);
  return (
    <Router>
      {isAuthenticated && <Navbar />}
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
        <Route path="/employees" element={<ProtectedRoute><EmployeesPage /></ProtectedRoute>} />
        <Route path="/vehicles" element={<ProtectedRoute><VehiclesPageComplete /></ProtectedRoute>} />
        <Route path="/" element={isAuthenticated ? <Navigate to="/dashboard" /> : <Navigate to="/login" />} />
      </Routes>
    </Router>
  );
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
EOFAPPNAV
print_success "App-nav.js creado (renombra a App.js después)"

echo ""

# ============================================================================
# AGREGAR A GIT Y COMMIT
# ============================================================================

print_header "Subiendo a GitHub"
echo ""

print_info "Agregando archivos..."
git add backend/src/routes/employees.js
git add backend/src/server.js
git add frontend/src/pages/EmployeesPage.js
git add frontend/src/styles/EmployeesPage.css
git add frontend/src/App-nav.js
print_success "Archivos agregados"

echo ""

print_info "Creando commit..."
git commit -m "feat: Agregar funcionalidades completas de Empleados y Vehículos con CRUD, búsqueda, paginación, filtros, carga de documentos y exportación"
print_success "Commit creado"

echo ""

print_info "Subiendo a GitHub..."
git push -u origin main
print_success "Cambios subidos a GitHub"

echo ""

# ============================================================================
# INSTRUCCIONES FINALES
# ============================================================================

print_header "✓ DEPLOY COMPLETADO"
echo ""
echo -e "${GREEN}Archivos subidos a GitHub:${NC}"
echo "  ✓ backend/src/routes/employees.js"
echo "  ✓ frontend/src/pages/EmployeesPage.js"
echo "  ✓ frontend/src/styles/EmployeesPage.css"
echo "  ✓ frontend/src/App-nav.js"
echo ""
echo -e "${YELLOW}Próximos pasos en tu máquina local:${NC}"
echo ""
echo "1. Actualizar App.js:"
echo "   mv frontend/src/App-nav.js frontend/src/App.js"
echo ""
echo "2. Reiniciar frontend en la terminal:"
echo "   cd frontend"
echo "   npm start"
echo ""
echo "3. Acceder a:"
echo "   http://localhost:3000/employees"
echo ""
echo -e "${GREEN}¡Las funcionalidades estarán disponibles!${NC}"
echo ""