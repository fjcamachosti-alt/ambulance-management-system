const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authMiddleware, roleMiddleware } = require('../middleware/auth');
const { body, validationResult } = require('express-validator');

router.get('/', authMiddleware, async (req, res) => {
  const { search, status } = req.query;
  try {
    let query = 'SELECT * FROM vehicles WHERE visible = true';
    const params = [];
    if (search) {
      query += ` AND (plate ILIKE $${params.length + 1} OR brand ILIKE $${params.length + 2} OR model ILIKE $${params.length + 3})`;
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    if (status) {
      query += ` AND status = $${params.length + 1}`;
      params.push(status);
    }
    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener vehículos' });
  }
});

router.post('/', authMiddleware, roleMiddleware(['administrador', 'gestor']), async (req, res) => {
  const { plate, brand, model, year, status = 'disponible' } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO vehicles (plate, brand, model, year, status) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [plate, brand, model, year, status]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al crear vehículo' });
  }
});

router.put('/:id', authMiddleware, roleMiddleware(['administrador', 'gestor']), async (req, res) => {
  const { plate, brand, model, year, status, visible } = req.body;
  try {
    const result = await pool.query(
      'UPDATE vehicles SET plate = COALESCE($1, plate), brand = COALESCE($2, brand), model = COALESCE($3, model), year = COALESCE($4, year), status = COALESCE($5, status), visible = COALESCE($6, visible), updated_at = CURRENT_TIMESTAMP WHERE id = $7 RETURNING *',
      [plate, brand, model, year, status, visible, req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Vehículo no encontrado' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al actualizar vehículo' });
  }
});

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM vehicles WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Vehículo no encontrado' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener vehículo' });
  }
});

module.exports = router;
