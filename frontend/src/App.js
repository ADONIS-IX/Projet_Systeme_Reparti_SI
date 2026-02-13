import React from 'react';
import logo from './logo.svg';
import './App.css';
import 'bootstrap/dist/css/bootstrap.min.css';
import Navbar from './components/Navbar';
import UserList from './components/UserList';
import ProductList from './components/ProductList';

function App() {
  return (
    <div className="App">
      <Navbar />

      <div className="container my-5">
        {/* En-tête */}
        <div className="text-center mb-5">
          <h1 className="display-4">Bienvenue sur le Système Réparti</h1>
          <p className="lead text-muted">
            Explorez les utilisateurs et les produits de notre système réparti.
            Projet de déploiement avec Docker, Kubernetes, Ansible et Jenkins.
          </p>
          <hr className="my-4" />
        </div>

        {/* Informations sur l'architecture */}
        <div className="row mb-5">
          <div className="col-md-4">
            <div className="card text-center">
              <div className="card-body">
                <h5 className="card-title">Frontend</h5>
                <p className="card-text">React 18</p>
              </div>
            </div>
          </div>
          <div className="col-md-4">
            <div className="card text-center">
              <div className="card-body">
                <h5 className="card-title">Backend</h5>
                <p className="card-text">Django REST Framework</p>
              </div>
            </div>
          </div>  
          <div className="col-md-4">
            <div className="card text-center">
              <div className="card-body">
                <h5 className="card-title">Base de données</h5>
                <p className="card-text">PostgreSQL 17</p>
              </div>
            </div>
          </div>
        </div>

        {/* Listes des utilisateurs*/}  
        <div className="mb-5">
        <UserList />
        </div>
        
        {/* Listes des produits*/} 
        <div className="mb-5">
        <ProductList />
        </div>

        {/* Pied de page */}
        <footer className="text-center text-muted py-4">
          <p className="mb-0">
            &copy; 2026 Système Réparti propulsé par Adrien Diong GOMIS. Tous droits réservés.
          </p>
        </footer>
      </div>
    </div>
  );
}

export default App;