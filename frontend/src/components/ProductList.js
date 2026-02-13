import React, { useState, useEffect } from 'react';
import { productService } from '../services/api';

const ProductList = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      const response = await productService.getAll();
      setProducts(response.data);
      setError(null);
    } catch (err) {
      setError('Erreur lors du chargement des produits');
      console.error('Erreur:', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="text-center my-5">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Chargement...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="alert alert-danger" role="alert">
        {error}
      </div>
    );
  }

  return (
    <div className="card">
      <div className="card-header bg-success text-white">
        <h5 className="mb-0">📦 Liste des Produits</h5>
      </div>
      <div className="card-body">
        {products.length === 0 ? (
          <p className="text-muted">Aucun produit trouvé</p>
        ) : (
          <div className="row">
            {products.map((product) => (
              <div key={product.id} className="col-md-4 mb-3">
                <div className="card h-100">
                  <div className="card-body">
                    <h5 className="card-title">{product.name}</h5>
                    <p className="card-text text-muted">{product.description}</p>
                    <div className="d-flex justify-content-between align-items-center">
                      <span className="badge bg-success fs-6">
                        {product.price} €
                      </span>
                      <span className={`badge ${product.stock > 0 ? 'bg-info' : 'bg-danger'}`}>
                        Stock: {product.stock}
                      </span>
                    </div>
                  </div>
                  <div className="card-footer text-muted small">
                    Ajouté le {new Date(product.created_at).toLocaleDateString('fr-FR')}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default ProductList;