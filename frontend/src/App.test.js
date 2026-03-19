import { render, screen, waitFor } from '@testing-library/react';
import App from './App';
import { productService, userService } from './services/api';

jest.mock('./services/api', () => ({
  userService: {
    getAll: jest.fn(),
  },
  productService: {
    getAll: jest.fn(),
  },
}));

beforeEach(() => {
  userService.getAll.mockResolvedValue({ data: [] });
  productService.getAll.mockResolvedValue({ data: [] });
});

test('renders dashboard and loads user/product lists', async () => {
  render(<App />);

  expect(
    screen.getByRole('heading', { name: /Bienvenue sur le Système Réparti/i })
  ).toBeInTheDocument();

  await waitFor(() => {
    expect(userService.getAll).toHaveBeenCalledTimes(1);
    expect(productService.getAll).toHaveBeenCalledTimes(1);
  });

  expect(await screen.findByText(/Aucun utilisateur trouvé/i)).toBeInTheDocument();
  expect(await screen.findByText(/Aucun produit trouvé/i)).toBeInTheDocument();
});
