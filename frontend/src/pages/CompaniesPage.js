import React, { useState, useEffect } from 'react';
import api from '../services/api';
import '../styles/CompaniesPage.css';

const CompaniesPage = () => {
  const [companies, setCompanies] = useState([]);
  const [filteredCompanies, setFilteredCompanies] = useState([]);
  const [loading, setLoading] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [currentTab, setCurrentTab] = useState('general');
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('activa');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  const [formData, setFormData] = useState({
    name: '',
    cif: '',
    legalForm: '',
    address: '',
    city: '',
    province: '',
    postalCode: '',
    phone: '',
    email: '',
    website: '',
    status: 'activa',
    documents: {},
    banking: {},
    tax: {},
    insurance: {},
    legal: {}
  });

  const [successMessage, setSuccessMessage] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    loadCompanies();
  }, []);

  const loadCompanies = async () => {
    setLoading(true);
    try {
      const response = await api.get('/api/companies');
      setCompanies(response.data || []);
    } catch (err) {
      setErrorMessage('Error al cargar empresas');
    } finally {
      setLoading(false);
    }
  };

  const filterCompanies = () => {
    let filtered = companies;
    if (searchTerm) {
      filtered = filtered.filter(c =>
        c.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.cif?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }
    if (filterStatus !== 'todas') {
      filtered = filtered.filter(c => c.status === filterStatus);
    }
    setFilteredCompanies(filtered);
  };

  useEffect(() => {
    filterCompanies();
  }, [companies, searchTerm, filterStatus]);

  const handleSave = async () => {
    try {
      if (editingId) {
        await api.put(`/api/companies/${editingId}`, formData);
        setSuccessMessage('Empresa actualizada');
      } else {
        await api.post('/api/companies', formData);
        setSuccessMessage('Empresa creada');
      }
      setShowModal(false);
      loadCompanies();
    } catch (err) {
      setErrorMessage('Error al guardar');
    }
  };

  return (
    <div className="companies-page">
      <div className="page-header">
        <h1>🏢 Gestión de Empresas</h1>
        <p>Administra la información de las empresas</p>
      </div>

      {successMessage && <div className="alert alert-success">{successMessage}</div>}
      {errorMessage && <div className="alert alert-error">{errorMessage}</div>}

      <div className="page-toolbar">
        <div className="search-filter-group">
          <input
            type="text"
            placeholder="Buscar empresa..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="search-input"
          />
        </div>
        <button onClick={() => setShowModal(true)} className="btn btn-primary">
          ➕ Nueva Empresa
        </button>
      </div>

      {loading ? <div className="loading-state">Cargando...</div> : <div className="empty-state">No hay empresas</div>}
    </div>
  );
};

export default CompaniesPage;
