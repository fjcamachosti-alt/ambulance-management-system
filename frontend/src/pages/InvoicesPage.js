import React, { useState, useEffect } from 'react';
import api from '../services/api';
import '../styles/InvoicesPage.css';

const InvoicesPage = () => {
  const [invoices, setInvoices] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadInvoices();
  }, []);

  const loadInvoices = async () => {
    setLoading(true);
    try {
      const response = await api.get('/api/invoices');
      setInvoices(response.data || []);
    } catch (err) {
      console.error('Error loading invoices');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="invoices-page">
      <div className="page-header">
        <h1>📄 Gestión de Facturas</h1>
        <p>Administra facturas emitidas y recibidas</p>
      </div>
      {loading ? <div className="loading-state">Cargando...</div> : <div className="empty-state">No hay facturas</div>}
    </div>
  );
};

export default InvoicesPage;
