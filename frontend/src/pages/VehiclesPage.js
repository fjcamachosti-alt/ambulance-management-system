import React, { useState, useEffect } from 'react';
import { vehiclesAPI } from '../services/api';
import '../styles/VehiclesPage.css';

const VehiclesPage = () => {
  const [vehicles, setVehicles] = useState([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    plate: '',
    brand: '',
    model: '',
    year: new Date().getFullYear(),
  });

  useEffect(() => {
    loadVehicles();
  }, [search]);

  const loadVehicles = async () => {
    setLoading(true);
    setError(null);
    try {
      const { data } = await vehiclesAPI.getAll(search);
      setVehicles(data);
    } catch (err) {
      setError('Error al cargar vehículos');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await vehiclesAPI.create(formData);
      setFormData({ plate: '', brand: '', model: '', year: new Date().getFullYear() });
      setShowForm(false);
      loadVehicles();
    } catch (err) {
      setError('Error al crear vehículo');
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'year' ? parseInt(value) : value,
    }));
  };

  return (
    <div className="vehicles-page">
      <h1>Gestión de Vehículos</h1>
      <div className="controls">
        <input type="text" placeholder="Buscar..." value={search} onChange={(e) => setSearch(e.target.value)} />
        <button onClick={() => setShowForm(!showForm)}>{showForm ? 'Cancelar' : 'Nuevo Vehículo'}</button>
      </div>
      {showForm && (
        <form onSubmit={handleSubmit}>
          <input type="text" name="plate" placeholder="Matrícula" value={formData.plate} onChange={handleChange} required />
          <input type="text" name="brand" placeholder="Marca" value={formData.brand} onChange={handleChange} required />
          <input type="text" name="model" placeholder="Modelo" value={formData.model} onChange={handleChange} required />
          <input type="number" name="year" placeholder="Año" value={formData.year} onChange={handleChange} required />
          <button type="submit">Crear Vehículo</button>
        </form>
      )}
      {error && <div className="error-message">{error}</div>}
      {loading ? (
        <p>Cargando...</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Matrícula</th>
              <th>Marca</th>
              <th>Modelo</th>
              <th>Año</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            {vehicles.map(v => (
              <tr key={v.id}>
                <td>{v.plate}</td>
                <td>{v.brand}</td>
                <td>{v.model}</td>
                <td>{v.year}</td>
                <td>{v.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
};

export default VehiclesPage;
