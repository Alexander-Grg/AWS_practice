import { render, screen, fireEvent, waitFor, act } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import SigninPage from '../pages/SigninPage';
import { Auth } from 'aws-amplify';

// 1. Mock AWS Amplify
jest.mock('aws-amplify');

// 2. Mock localStorage
const localStorageMock = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn(),
};
Object.defineProperty(window, 'localStorage', { value: localStorageMock });

// 3. Mock window.location
const mockLocation = {
  href: '',
  assign: jest.fn(),
  replace: jest.fn(),
  reload: jest.fn(),
};
delete window.location;
window.location = mockLocation;

// Helper to render with router
const renderWithRouter = (ui) => {
  return render(<BrowserRouter>{ui}</BrowserRouter>);
};

describe('SigninPage', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();
    window.location.href = '';
    localStorageMock.setItem.mockClear();
  });

  test('renders the sign in form', () => {
    renderWithRouter(<SigninPage />);
    expect(screen.getByText(/Sign into your Webapp account/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Password/i)).toBeInTheDocument();
  });

  test('calls Auth.signIn when form is submitted', async () => {
    // Setup the mock to resolve successfully
    Auth.signIn.mockResolvedValue({
      signInUserSession: {
        accessToken: { jwtToken: 'fake-jwt-token' }
      }
    });

    renderWithRouter(<SigninPage />);

    // Fill in the form using test IDs (more reliable)
    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');
    const submitBtn = screen.getByRole('button', { name: /Sign In/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });

    // Click submit
    fireEvent.click(submitBtn);

    // Assert
    await waitFor(() => {
      expect(Auth.signIn).toHaveBeenCalledWith('test@example.com', 'password123');
      expect(localStorageMock.setItem).toHaveBeenCalledWith(
        'access_token',
        'fake-jwt-token'
      );
    });
  });

  test('displays error message on failed login', async () => {
    Auth.signIn.mockRejectedValue(new Error('Incorrect username or password.'));

    renderWithRouter(<SigninPage />);
    
    // Fill and submit using test IDs
    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');
    const submitBtn = screen.getByRole('button', { name: /Sign In/i });
    
    fireEvent.change(emailInput, { target: { value: 'wrong@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'wrongpass' } });
    fireEvent.click(submitBtn);

    // Wait for error to appear
    await waitFor(() => {
      expect(screen.getByText(/Incorrect username or password/i)).toBeInTheDocument();
    });
  });

  test('redirects to confirm page when user is not confirmed', async () => {
    const error = new Error('User not confirmed');
    error.code = 'UserNotConfirmedException';
    Auth.signIn.mockRejectedValue(error);

    renderWithRouter(<SigninPage />);
    
    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');
    const submitBtn = screen.getByRole('button', { name: /Sign In/i });
    
    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(submitBtn);

    await waitFor(() => {
      expect(window.location.href).toBe('/confirm');
    });
  });

  test('disables button when loading', async () => {
    // Mock a slow response
    Auth.signIn.mockImplementation(() => new Promise(resolve => setTimeout(resolve, 100)));

    renderWithRouter(<SigninPage />);
    
    const submitBtn = screen.getByRole('button', { name: /Sign In/i });
    
    // Initially not disabled
    expect(submitBtn).not.toBeDisabled();
    
    // Submit form
    fireEvent.change(screen.getByTestId('email-input'), { target: { value: 'test@example.com' } });
    fireEvent.change(screen.getByTestId('password-input'), { target: { value: 'password123' } });
    fireEvent.click(submitBtn);

    // Button should be disabled while loading
    await waitFor(() => {
      expect(submitBtn).toBeDisabled();
      expect(submitBtn).toHaveTextContent('Signing In...');
    });
  });
});