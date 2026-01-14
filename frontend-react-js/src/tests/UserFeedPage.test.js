import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom'; // Use MemoryRouter for params
import UserFeedPage from '../pages/UserFeedPage';
import { checkAuth } from '../lib/CheckAuth';

// Mock Fetch specifically for this file
global.fetch = jest.fn();
jest.mock('../lib/CheckAuth');

// Mock children
jest.mock('../components/DesktopNavigation', () => () => <div>Nav</div>);
jest.mock('../components/DesktopSidebar', () => () => <div>Sidebar</div>);
jest.mock('../components/ActivityForm', () => () => <div>Form</div>);
jest.mock('../components/ProfileForm', () => () => <div>ProfileForm</div>);

// Important: Mock ProfileHeading so we can see if data reached it
jest.mock('../components/ProfileHeading', () => ({ profile }) => (
    <div>Profile: {profile.display_name}</div>
));

describe('UserFeedPage', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('loads user profile based on URL parameter', async () => {
        // 1. Setup Mock API Response
        const mockProfile = { display_name: 'Coco The Cat', handle: 'coco' };
        const mockActivities = [];
        
        global.fetch.mockResolvedValue({
            status: 200,
            json: async () => ({
                profile: mockProfile,
                activities: mockActivities
            })
        });

        // 2. Render with MemoryRouter to simulate a specific URL
        render(
            <MemoryRouter initialEntries={['/@coco']}>
                <Routes>
                    <Route path="/:handle" element={<UserFeedPage />} />
                </Routes>
            </MemoryRouter>
        );

        // 3. Assert fetch was called with correct handle
        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith(
                expect.stringContaining('/api/activities/@coco'),
                expect.objectContaining({ method: 'GET' })
            );
        });

        // 4. Assert Data Rendered
        expect(await screen.findByText('Profile: Coco The Cat')).toBeInTheDocument();
    });
});