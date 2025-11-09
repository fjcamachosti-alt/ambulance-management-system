import React, { useState, useEffect } from 'react';
import api from '../services/api';
import '../styles/SuppliersPage.css';

const SuppliersPage = () => {
  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadSuppliers();
  }, []);

  const loadSuppliers = async () => {
    setLoading(true);
    try {
      const response = await api.get('/api/suppliers');
      setSuppliers(response.data || []);
    } catch (err) {
      console.error('Error loading suppliers');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="suppliers-page">
      <div className="page-header">
        <h1>🤖 Gestión de Proveedores</h1>
        <p>Administra los proveedores</p>
      </div>
      {loading ? <div className="loading-state">Cargando...</div> : <div className="empty-state">No hay proveedores</div>}
    </div>
  );
};

export default SuppliersPage;
