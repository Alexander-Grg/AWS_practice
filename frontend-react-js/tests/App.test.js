import { render, screen } from '@testing-library/react';
import App from '../src/App';

test('renders without crashing', () => {
  render(<App />);
});