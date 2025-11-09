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
