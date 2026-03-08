import axios from 'axios';

// En production (Docker Compose, Kubernetes), le frontend est servi par Nginx
// qui proxifie /api/ vers le backend. On utilise donc une URL relative.
// En développement local (npm start), on pointe directement vers le backend.
const API_BASE_URL = process.env.REACT_APP_API_URL || '/api';

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