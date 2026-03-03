import axios from 'axios';

// URL de base de l'API (peut être configurée via variable d'environnement)
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://backend:8000/api';

// Instance axios configurée
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Services pour les utilisateurs
export const userService = {
  getAll: () => api.get('/users/'),
  getById: (id) => api.get(`/users/${id}/`),
  create: (userData) => api.post('/users/', userData),
  update: (id, userData) => api.put(`/users/${id}/`, userData),
  delete: (id) => api.delete(`/users/${id}/`),
};

// Services pour les produits
export const productService = {
  getAll: () => api.get('/products/'),
  getById: (id) => api.get(`/products/${id}/`),
  getInStock: () => api.get('/products/in_stock/'),
  create: (productData) => api.post('/products/', productData),
  update: (id, productData) => api.put(`/products/${id}/`, productData),
  delete: (id) => api.delete(`/products/${id}/`),
  addStock: (id, quantity) => api.post(`/products/${id}/add_stock/`, { quantity }),
};

export default api;