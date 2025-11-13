const express = require('express');
const router = express.Router();

const PRODUCTS = [
  { id: 1, name: 'T-shirt', price: 19.99 },
  { id: 2, name: 'Mug', price: 9.99 },
  { id: 3, name: 'Sticker', price: 2.5 }
];

router.get('/', (req, res) => res.json(PRODUCTS));
router.get('/:id', (req, res) => {
  const p = PRODUCTS.find(x => x.id === Number(req.params.id));
  if (!p) return res.status(404).json({error: 'Not found'});
  res.json(p);
});

module.exports = router;
