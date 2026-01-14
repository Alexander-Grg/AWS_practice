// frontend-react-js/src/tests/App.test.js

import { render, screen } from '@testing-library/react';
import App from '../App'; // Now it is just one level up

test('renders without crashing', () => {
  render(<App />);
});