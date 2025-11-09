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
