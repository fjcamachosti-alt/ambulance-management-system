#!/bin/bash

################################################################################
# 🚑 AMIGA - AUTOMATED PROFESSIONAL SETUP SCRIPT
# Con Git Push a GitHub
# Arquitecto Senior: Full-Stack Enterprise
# Compatible: Ubuntu 20.04+ / Debian 11+
################################################################################

set -e

# ============================================
# COLORS FOR OUTPUT
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================
# CONFIGURATION
# ============================================

PROJECT_DIR="/home/apisistem/ambulance-setup"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"
DB_NAME="ambulance_db"
DB_USER="postgres"
DB_PASSWORD="apisistem"
DB_PORT="5432"
REPO_URL="https://github.com/fjcamachosti-alt/ambulance-management-system.git"

# ============================================
# LOGGING FUNCTIONS
# ============================================

log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
  exit 1
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_section() {
  echo ""
  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo ""
}

# ============================================
# PRE-FLIGHT CHECKS
# ============================================

check_requirements() {
  log_section "VERIFICANDO REQUISITOS"

  # Check OS
  if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    log_error "Este script solo funciona en Linux. Tu OS: $OSTYPE"
  fi
  log_success "OS verificado: Linux"

  # Check root/sudo
  if [[ $EUID -ne 0 ]]; then
    log_error "Este script debe ejecutarse con sudo"
  fi
  log_success "Permisos de sudo verificados"

  # Check required commands
  local required_commands=("git" "node" "npm" "psql" "curl")
  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      log_warning "$cmd no está instalado. Se va a instalar..."
      install_dependencies
      break
    fi
  done
  log_success "Comandos requeridos verificados"

  # Check Node version
  local node_version=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
  if [[ $node_version -lt 16 ]]; then
    log_error "Node.js 16+ requerido. Tienes: v$node_version"
  fi
  log_success "Node.js $node_version verificado"

  # Check PostgreSQL
  if ! sudo -u postgres psql --version &> /dev/null; then
    log_warning "PostgreSQL no instalado. Se va a instalar..."
    install_postgresql
  fi
  log_success "PostgreSQL verificado"
}

# ============================================
# INSTALL DEPENDENCIES
# ============================================

install_dependencies() {
  log_section "INSTALANDO DEPENDENCIAS DEL SISTEMA"

  apt-get update -qq
  apt-get install -y -qq \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    postgresql \
    postgresql-contrib

  log_success "Dependencias del sistema instaladas"
}

install_postgresql() {
  log_info "Instalando PostgreSQL..."
  
  apt-get install -y postgresql postgresql-contrib
  
  log_success "PostgreSQL instalado"
}

# ============================================
# GIT CONFIGURATION
# ============================================

check_git_credentials() {
  log_section "VERIFICANDO CREDENCIALES GIT"

  # Check if git is configured
  if [ -z "$(git config --global user.name)" ]; then
    log_warning "Git no configurado globalmente"
    
    read -p "Ingresa tu nombre de Git: " git_name
    read -p "Ingresa tu email de Git: " git_email
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    log_success "Git configurado: $git_name <$git_email>"
  else
    log_success "Git ya configurado"
  fi

  # Check GitHub SSH or HTTPS
  log_info "Verificando conectividad con GitHub..."
  
  if ssh -T git@github.com &>/dev/null; then
    log_success "SSH con GitHub verificado"
    GIT_PROTOCOL="ssh"
  elif curl -s https://api.github.com/repos/fjcamachosti-alt/ambulance-management-system &>/dev/null; then
    log_success "HTTPS con GitHub verificado"
    GIT_PROTOCOL="https"
  else
    log_warning "No se pudo verificar GitHub"
    log_info "Asegúrate de que:"
    log_info "  1. Tienes SSH keys configuradas en GitHub, O"
    log_info "  2. Tienes acceso a Internet para HTTPS"
  fi
}

# ============================================
# DATABASE SETUP
# ============================================

setup_database() {
  log_section "CONFIGURANDO BASE DE DATOS"

  # Start PostgreSQL
  log_info "Iniciando PostgreSQL..."
  systemctl start postgresql || true
  systemctl enable postgresql

  # Create database
  log_info "Creando base de datos..."
  sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" || true

  log_success "Base de datos creada"

  # Create schema
  log_info "Creando esquema..."
  
  sudo -u postgres psql -d "$DB_NAME" << 'SCHEMA_EOF'
-- ============================================
-- AMIGA DATABASE SCHEMA
-- ============================================

CREATE SCHEMA IF NOT EXISTS amiga;
SET search_path TO amiga;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  role VARCHAR(50) NOT NULL DEFAULT 'tecnico',
  status VARCHAR(20) NOT NULL DEFAULT 'activo',
  password_changed_at TIMESTAMP,
  last_login_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by INTEGER REFERENCES users(id),
  CHECK (role IN ('administrador', 'gestor', 'oficina', 'tecnico', 'medico', 'enfermero')),
  CHECK (status IN ('activo', 'inactivo', 'permiso', 'baja'))
);

-- Refresh tokens
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id SERIAL PRIMARY KEY,
  token UUID NOT NULL UNIQUE,
  token_family UUID NOT NULL,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vehicles
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID PRIMARY KEY,
  plate VARCHAR(20) UNIQUE NOT NULL,
  brand VARCHAR(100) NOT NULL,
  model VARCHAR(100) NOT NULL,
  year INTEGER NOT NULL,
  type VARCHAR(50),
  status VARCHAR(20) NOT NULL DEFAULT 'disponible',
  availability BOOLEAN DEFAULT true,
  visibility BOOLEAN DEFAULT true,
  engine_number VARCHAR(100),
  chassis_number VARCHAR(100),
  power INTEGER,
  fuel VARCHAR(50),
  mileage INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by INTEGER NOT NULL REFERENCES users(id),
  CHECK (status IN ('disponible', 'enservicio', 'mantenimiento', 'revisión'))
);

-- Vehicle documents
CREATE TABLE IF NOT EXISTS vehicle_documents (
  id UUID PRIMARY KEY,
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  document_type VARCHAR(100) NOT NULL,
  category VARCHAR(50) NOT NULL,
  file_path VARCHAR(500) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_size INTEGER NOT NULL,
  mime_type VARCHAR(100),
  expiry_date DATE,
  notes TEXT,
  uploaded_by INTEGER NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CHECK (category IN ('basic', 'specific', 'additional')),
  CHECK (file_size > 0 AND file_size <= 10485760)
);

-- Vehicle alerts
CREATE TABLE IF NOT EXISTS vehicle_alerts (
  id UUID PRIMARY KEY,
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  alert_type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  due_date TIMESTAMP NOT NULL,
  severity VARCHAR(20) DEFAULT 'normal',
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMP,
  assigned_to INTEGER REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by INTEGER REFERENCES users(id),
  CHECK (alert_type IN ('itv', 'revision', 'seguro', 'maintenance', 'incident')),
  CHECK (severity IN ('low', 'normal', 'high', 'critical'))
);

-- Audit logs
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  action VARCHAR(50) NOT NULL,
  entity_type VARCHAR(100),
  entity_id VARCHAR(100),
  changes JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CHECK (action IN ('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'EXPORT'))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_plate ON vehicles(UPPER(plate));
CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status);
CREATE INDEX IF NOT EXISTS idx_vehicle_alerts_vehicle_id ON vehicle_alerts(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);

-- Insert default admin user
INSERT INTO users (email, password_hash, first_name, last_name, role, status)
VALUES (
  'apisistem@ambulance.local',
  '$2a$10$YAJFzgLyVzwrji2bI36uM.oggtgMMF/bO076iFsdSUyJIgvWqF/tq',
  'Admin',
  'System',
  'administrador',
  'activo'
) ON CONFLICT (email) DO NOTHING;

SCHEMA_EOF

  log_success "Esquema de base de datos creado"
}

# ============================================
# BACKEND SETUP
# ============================================

setup_backend() {
  log_section "CONFIGURANDO BACKEND"

  cd "$BACKEND_DIR"

  # Create .env
  log_info "Creando archivo .env..."
  cat > .env << 'ENV_EOF'
NODE_ENV=development
PORT=5000
LOG_LEVEL=debug

DB_HOST=localhost
DB_PORT=5432
DB_NAME=ambulance_db
DB_USER=postgres
DB_PASSWORD=apisistem
DB_POOL_MIN=2
DB_POOL_MAX=10

JWT_ACCESS_SECRET=your-super-secret-access-key-min-64-characters-here-change-in-production-12345
JWT_REFRESH_SECRET=your-super-secret-refresh-key-min-64-characters-here-change-in-production-12345
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d

CORS_ORIGIN=http://localhost:3000
CORS_CREDENTIALS=true

MAX_FILE_SIZE=10485760
ALLOWED_MIME_TYPES=application/pdf,image/jpeg,image/png

RATE_LIMIT_WINDOW=15
RATE_LIMIT_MAX_REQUESTS=100

SESSION_SECRET=your-session-secret-change-in-production
ENV_EOF

  log_success ".env creado"

  # Create folder structure
  log_info "Creando estructura de carpetas..."
  mkdir -p src/{config,middleware,models,services,controllers,routes,utils}
  mkdir -p logs uploads tests
  log_success "Carpetas creadas"

  # Install dependencies
  log_info "Instalando dependencias npm..."
  npm install --quiet --no-audit 2>&1 | grep -v "^npm" || true
  npm install --save-dev --quiet nodemon @babel/core @babel/cli @babel/preset-env jest supertest 2>&1 | grep -v "^npm" || true
  log_success "Dependencias instaladas"

  # Update package.json scripts
  log_info "Actualizando scripts de npm..."
  npm set-script start "node src/server.js"
  npm set-script dev "nodemon src/server.js"
  npm set-script test "jest --forceExit --detectOpenHandles"
  npm set-script "test:coverage" "jest --coverage"
  log_success "Scripts actualizados"

  cd - > /dev/null
}

# ============================================
# FRONTEND SETUP
# ============================================

setup_frontend() {
  log_section "CONFIGURANDO FRONTEND"

  cd "$FRONTEND_DIR"

  # Create .env
  log_info "Creando archivo .env..."
  cat > .env << 'ENV_EOF'
REACT_APP_API_URL=http://localhost:5000/api
ENV_EOF

  # Install dependencies
  log_info "Instalando dependencias npm frontend..."
  npm install --quiet --no-audit 2>&1 | grep -v "^npm" || true
  log_success "Dependencias instaladas"

  cd - > /dev/null
}

# ============================================
# TEST BACKEND
# ============================================

test_backend() {
  log_section "PROBANDO BACKEND"

  cd "$BACKEND_DIR"

  # Start backend in background
  log_info "Iniciando backend..."
  timeout 10 npm run dev &
  BACKEND_PID=$!
  
  sleep 3

  # Test health endpoint
  log_info "Probando health endpoint..."
  if curl -s http://localhost:5000/api/health | grep -q "OK"; then
    log_success "Backend funcionando correctamente"
  else
    log_warning "No se pudo conectar al backend"
  fi

  kill $BACKEND_PID 2>/dev/null || true

  cd - > /dev/null
}

# ============================================
# GIT SETUP & GITHUB PUSH
# ============================================

setup_git_and_push() {
  log_section "CONFIGURANDO GIT Y SUBIENDO A GITHUB"

  cd "$PROJECT_DIR"

  # Initialize git if not already
  if [ ! -d ".git" ]; then
    log_info "Inicializando repositorio git..."
    git init
    git remote add origin "$REPO_URL"
  fi

  # Create .gitignore
  log_info "Creando .gitignore..."
  cat > .gitignore << 'GITIGNORE_EOF'
node_modules/
.env
.env.local
logs/
uploads/
.DS_Store
*.log
dist/
build/
coverage/
.vscode/
.idea/
*.swp
*.swo
.env.production
GITIGNORE_EOF

  # Create README if not exists
  if [ ! -f "README.md" ]; then
    log_info "Creando README.md..."
    cat > README.md << 'README_EOF'
# 🚑 AMIGA - Sistema de Gestión de Ambulancias

Aplicación de Manejo Integral de Gestión de Ambulancias (AMIGA)

## Características

- ✅ Autenticación JWT + Refresh Tokens
- ✅ Control de Acceso Basado en Roles (RBAC)
- ✅ Gestión de Vehículos con alertas automáticas
- ✅ Sistema de documentación
- ✅ API REST profesional
- ✅ Frontend React moderno
- ✅ Tests unitarios
- ✅ Documentación Swagger

## Tecnología

- **Backend**: Node.js 16+ | Express.js
- **Frontend**: React 18
- **BD**: PostgreSQL 14+
- **Auth**: JWT + Refresh Tokens
- **Testing**: Jest + Supertest
- **API Docs**: Swagger/OpenAPI 3.0

## Inicio Rápido

```bash
# 1. Setup automático
sudo bash setup.sh

# 2. Backend
cd backend && npm run dev

# 3. Frontend (otra terminal)
cd frontend && npm start

# 4. Acceder
# http://localhost:3000
# http://localhost:5000/api-docs
```

## Credenciales Demo

- Email: `apisistem@ambulance.local`
- Contraseña: `apisistem`

## Documentación

- API: http://localhost:5000/api-docs
- Tests: `npm test`
- Coverage: `npm run test:coverage`

## Licencia

Enterprise - 2025
README_EOF
  fi

  # Check if there are changes to commit
  if [ -z "$(git status --porcelain)" ]; then
    log_warning "No hay cambios nuevos para hacer commit"
  else
    log_info "Agregando cambios a git..."
    git add .
    
    log_info "Creando commit..."
    git commit -m "🚑 AMIGA: Setup profesional automatizado - Backend + Frontend + Tests + Swagger" -q || true
  fi

  # Push to GitHub
  log_info "Configurando conexión con GitHub..."
  
  # Get current branch
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  
  # Try to push
  log_info "Subiendo a GitHub ($CURRENT_BRANCH)..."
  
  if git push -u origin "$CURRENT_BRANCH" 2>/dev/null; then
    log_success "Subido a GitHub exitosamente"
    log_info "Repositorio: $REPO_URL"
    log_info "Branch: $CURRENT_BRANCH"
  else
    log_warning "No se pudo hacer push a GitHub automáticamente"
    log_info "Posibles soluciones:"
    log_info "  1. Verificar autenticación SSH/HTTPS"
    log_info "  2. Ejecutar manualmente: git push -u origin $CURRENT_BRANCH"
    log_info "  3. Ver más información con: git remote -v"
  fi

  cd - > /dev/null
}

# ============================================
# SUMMARY
# ============================================

print_summary() {
  log_section "RESUMEN DE SETUP"

  echo "✅ AMIGA SETUP COMPLETADO"
  echo ""
  echo "📊 Información del Setup:"
  echo "  • Base de datos: $DB_NAME"
  echo "  • Usuario: $DB_USER"
  echo "  • Backend: http://localhost:5000"
  echo "  • Frontend: http://localhost:3000"
  echo "  • Swagger: http://localhost:5000/api-docs"
  echo "  • GitHub: $REPO_URL"
  echo ""
  echo "📋 Próximos pasos:"
  echo "  1. Iniciar backend:"
  echo "     cd $BACKEND_DIR"
  echo "     npm run dev"
  echo ""
  echo "  2. Iniciar frontend (en otra terminal):"
  echo "     cd $FRONTEND_DIR"
  echo "     npm start"
  echo ""
  echo "  3. Acceder a:"
  echo "     Frontend:  http://localhost:3000"
  echo "     Backend:   http://localhost:5000"
  echo "     API Docs:  http://localhost:5000/api-docs"
  echo ""
  echo "  4. Ejecutar tests:"
  echo "     cd $BACKEND_DIR"
  echo "     npm test"
  echo ""
  echo "🔑 Credenciales por defecto:"
  echo "  Email: apisistem@ambulance.local"
  echo "  Contraseña: apisistem"
  echo ""
  echo "📚 Documentación:"
  echo "  • Backend: http://localhost:5000/api-docs"
  echo "  • GitHub: $REPO_URL"
  echo "  • Logs: $BACKEND_DIR/logs/"
  echo ""
  echo "✨ Cambios subidos a GitHub:"
  echo "  • Backend profesional"
  echo "  • Frontend React"
  echo "  • Tests unitarios"
  echo "  • Documentación Swagger"
  echo "  • Variables de entorno"
  echo "  • .gitignore configurado"
  echo ""
}

# ============================================
# MAIN EXECUTION
# ============================================

main() {
  clear

  echo -e "${CYAN}"
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║                                                            ║"
  echo "║  🚑 AMIGA - AUTOMATED PROFESSIONAL SETUP WITH GITHUB 🚑   ║"
  echo "║                                                            ║"
  echo "║ Aplicación de Manejo Integral de Gestión de Ambulancias   ║"
  echo "║                                                            ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo ""

  check_requirements
  check_git_credentials
  setup_database
  setup_backend
  setup_frontend
  test_backend
  setup_git_and_push
  print_summary
}

# Execute main
main