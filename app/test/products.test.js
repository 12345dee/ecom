const request = require('supertest');
const { expect } = require('chai');
const app = require('../server');

describe('Products API', () => {
  it('GET /api/products returns list', async () => {
    const res = await request(app).get('/api/products').expect(200);
    expect(res.body).to.be.an('array');
    expect(res.body.length).to.be.greaterThan(0);
  });

  it('GET /api/products/1 returns item', async () => {
    const res = await request(app).get('/api/products/1').expect(200);
    expect(res.body).to.have.property('id', 1);
  });

  it('GET /health returns ok', async () => {
    const res = await request(app).get('/health').expect(200);
    expect(res.body).to.have.property('status', 'ok');
  });
});
