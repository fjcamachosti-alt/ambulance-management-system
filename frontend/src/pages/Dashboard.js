import React, { useState, useEffect, useContext } from 'react';
import { AuthContext } from '../contexts/AuthContext';
import '../styles/Dashboard.css';

const Dashboard = () => {
  const { user, logout } = useContext(AuthContext);
  const [stats] = useState({
    totalVehicles: 12,
    totalUsers: 24,
    pendingAlerts: 3,
  });

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <h1>Panel de Control</h1>
        <div className="user-info">
          <span>{user?.firstName} {user?.lastName}</span>
          <button onClick={logout} className="logout-button">Cerrar Sesión</button>
        </div>
      </header>
      <main className="dashboard-main">
        <section className="widgets">
          <div className="widget">
            <h3>Vehículos</h3>
            <p className="stat-number">{stats.totalVehicles}</p>
          </div>
          <div className="widget">
            <h3>Trabajadores</h3>
            <p className="stat-number">{stats.totalUsers}</p>
          </div>
          <div className="widget alert-widget">
            <h3>Alertas Pendientes</h3>
            <p className="stat-number">{stats.pendingAlerts}</p>
          </div>
        </section>
        <section className="quick-actions">
          <h2>Acciones Rápidas</h2>
          <div className="action-buttons">
            <button className="action-btn">Nuevo Vehículo</button>
            <button className="action-btn">Nuevo Empleado</button>
            <button className="action-btn">Ver Alertas</button>
            <button className="action-btn">Reportes</button>
          </div>
        </section>
      </main>
    </div>
  );
};

export default Dashboard;
