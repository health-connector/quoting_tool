const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3002;

// Enable CORS for all origins
app.use(cors());

// Middleware to parse JSON bodies
app.use(express.json());

const API_BASE_PATH = '/api/v1';

// --- Mock Data ---
// Import mock plans data from JSON file
let mockPlans = [];
try {
  const plansFilePath = path.join(__dirname, 'data', 'plans.json');
  const plansData = JSON.parse(fs.readFileSync(plansFilePath, 'utf8'));
  mockPlans = plansData.plans;
  console.log(`Loaded ${mockPlans.length} mock plans from ${plansFilePath}`);
} catch (error) {
  console.error('Error loading mock plans data:', error);
}

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

// GET /api/v1/products/plans.json
app.get(`${API_BASE_PATH}/products/plans.json`, (req, res) => {
  console.log(`GET ${req.path} received with query:`, req.query);
  // TODO: Optionally filter mockPlans based on req.query parameters
  // For now, just return all mock plans
  res.json({ plans: mockPlans });
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
