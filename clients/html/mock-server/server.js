const express = require('express');
const cors = require('cors');

const app = express();
const port = 3002;

// Enable CORS for all origins
app.use(cors());

// Middleware to parse JSON bodies
app.use(express.json());

const API_BASE_PATH = '/api/v1';

// --- Mock Data ---
const mockStartDates = [
  '2024-01-01',
  '2024-02-01',
  '2024-03-01',
  '2024-04-01',
  '2024-05-01',
  '2024-06-01',
  '2024-07-01',
  '2024-08-01',
  '2024-09-01',
  '2024-10-01',
  '2024-11-01',
  '2024-12-01',
];

const mockSampleMessage = {
  message: 'Hello from the mock API!',
};

// --- API Endpoints ---

// GET /api/v1/employees/start_on_dates.json
app.get(`${API_BASE_PATH}/employees/start_on_dates.json`, (req, res) => {
  console.log(`GET ${req.path} received`);
  // Send response in the expected object format
  res.json({
    dates: mockStartDates,
    is_late_rate: false, // Defaulting to false for mock data
  });
});

// GET /api/v1/samples
app.get(`${API_BASE_PATH}/samples`, (req, res) => {
  console.log(`GET ${req.path} received`);
  res.json(mockSampleMessage);
});

// POST /api/v1/employees/upload.json
app.post(`${API_BASE_PATH}/employees/upload.json`, (req, res) => {
  console.log(`POST ${req.path} received with body:`, req.body);
  // Simulate successful upload
  // In a real scenario, you might validate req.body here
  res.status(200).json({ status: 'success', message: 'Employee data received.' });
});

// --- Start Server ---
app.listen(port, () => {
  console.log(`Mock API server listening at http://localhost:${port}`);
});
