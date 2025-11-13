const express = require('express');
const products = require('./routes/products');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use('/api/products', products);
app.use(express.static(path.join(__dirname, 'public')));

app.get('/health', (req, res) => res.json({status: 'ok', time: new Date().toISOString()}));

if (require.main === module) {
  app.listen(PORT, () => console.log(`E-com sample listening on ${PORT}`));
}

module.exports = app;
