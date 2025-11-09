import React, { useState, useEffect } from 'react';
import api from '../services/api';
import '../styles/ClientsPage.css';

const ClientsPage = () => {
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadClients();
  }, []);

  const loadClients = async () => {
    setLoading(true);
    try {
      const response = await api.get('/api/clients');
      setClients(response.data || []);
    } catch (err) {
      console.error('Error loading clients');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="clients-page">
      <div className="page-header">
        <h1>🤝 Gestión de Clientes</h1>
        <p>Administra los clientes</p>
      </div>
      {loading ? <div className="loading-state">Cargando...</div> : <div className="empty-state">No hay clientes</div>}
    </div>
  );
};

export default ClientsPage;
