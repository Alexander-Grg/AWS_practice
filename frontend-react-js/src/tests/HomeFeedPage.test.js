import { render, screen, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import HomeFeedPage from '../HomeFeedPage';
import { get } from '../../lib/Requests';
import { checkAuth } from '../../lib/CheckAuth';

// 1. Mock your custom libraries
jest.mock('../../lib/Requests');
jest.mock('../../lib/CheckAuth');

// 2. Mock child components to simplify the test
// We only care that the Page passes data to the Feed, not how the Feed renders it.
jest.mock('../../components/ActivityFeed', () => {
  return function DummyFeed({ activities }) {
    return (
      <div data-testid="activity-feed-mock">
        {activities.map(a => <div key={a.uuid}>{a.message}</div>)}
      </div>
    );
  };
});

// Mock other children to avoid errors
jest.mock('../../components/DesktopNavigation', () => () => <div>Nav</div>);
jest.mock('../../components/DesktopSidebar', () => () => <div>Sidebar</div>);
jest.mock('../../components/ActivityForm', () => () => <div>Form</div>);
jest.mock('../../components/ReplyForm', () => () => <div>Reply</div>);

describe('HomeFeedPage', () => {
  beforeEach(() => {
    // Reset mocks before each test
    jest.clearAllMocks();
  });

  test('fetches data and renders activities', async () => {
    // Setup Mock Data
    const mockActivities = [
        { uuid: '1', message: 'Hello World' },
        { uuid: '2', message: 'Second Post' }
    ];

    // Mock the 'get' function implementation
    // Your code uses callbacks: get(url, { success: fn })
    get.mockImplementation((url, options) => {
      if (options.success) {
        options.success(mockActivities);
      }
    });

    render(
      <BrowserRouter>
        <HomeFeedPage />
      </BrowserRouter>
    );

    // Wait for the data to be rendered (using the mocked Feed)
    await waitFor(() => {
        expect(screen.getByText('Hello World')).toBeInTheDocument();
        expect(screen.getByText('Second Post')).toBeInTheDocument();
    });

    // Verify the API was called
    expect(get).toHaveBeenCalledTimes(1);
    expect(get).toHaveBeenCalledWith(
        expect.stringContaining('/api/activities/home'),
        expect.objectContaining({ auth: true })
    );
  });
});