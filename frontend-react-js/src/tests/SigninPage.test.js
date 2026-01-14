import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import SigninPage from '../pages/SigninPage';
import { Auth } from 'aws-amplify';

// 1. Mock AWS Amplify
jest.mock('aws-amplify');

// 2. Mock React Router (Link component)
// We use BrowserRouter in the render, so strictly speaking we don't need to mock the whole lib,
// but we need to ensure the Link doesn't crash.
const renderWithRouter = (ui) => {
  return render(<BrowserRouter>{ui}</BrowserRouter>);
};

describe('SigninPage', () => {
  test('renders the sign in form', () => {
    renderWithRouter(<SigninPage />);
    expect(screen.getByText(/Sign into your Webapp account/i)).toBeInTheDocument();
  });

  test('calls Auth.signIn when form is submitted', async () => {
    // Setup the mock to resolve successfully
    Auth.signIn.mockResolvedValue({
      signInUserSession: {
        accessToken: { jwtToken: 'fake-jwt-token' }
      }
    });

    // Mock window.location because the component assigns to it
    // This is a hack because JSDOM doesn't implement window.location perfectly
    delete window.location;
    window.location = { href: '' };

    renderWithRouter(<SigninPage />);

    // Fill in the form
    const emailInput = screen.getByLabelText(/Email/i);
    const passwordInput = screen.getByLabelText(/Password/i);
    const submitBtn = screen.getByRole('button', { name: /Sign In/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });

    // Click submit
    fireEvent.click(submitBtn);

    // Assert
    await waitFor(() => {
      expect(Auth.signIn).toHaveBeenCalledWith('test@example.com', 'password123');
    });
  });

  test('displays error message on failed login', async () => {
    Auth.signIn.mockRejectedValue(new Error('Incorrect username or password.'));

    renderWithRouter(<SigninPage />);
    
    // Fill and submit
    fireEvent.change(screen.getByLabelText(/Email/i), { target: { value: 'wrong@example.com' } });
    fireEvent.change(screen.getByLabelText(/Password/i), { target: { value: 'wrongpass' } });
    fireEvent.click(screen.getByRole('button', { name: /Sign In/i }));

    // Assert error appears
    const errorMsg = await screen.findByText('Incorrect username or password.');
    expect(errorMsg).toBeInTheDocument();
  });
});