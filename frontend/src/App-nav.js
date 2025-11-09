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
