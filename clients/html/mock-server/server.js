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

// Add mock plans data
const mockPlans = [
  {
    id: 'plan1',
    name: 'Gold Plan',
    provider_name: 'MockCarrier A',
    product_type: 'HMO',
    metal_level: 'Gold',
    network: 'National PPO',
    deductible: 1000,
    group_deductible: '$2000',
    out_of_pocket_in_network: '$5000',
    group_size_factors: { max_group_size: 50, factors: { '1-50': 1.0 } },
    participation_factors: { '75-100': 1.0 },
    sic_code_factor: 1.0,
    rates: {
      min_age: 20,
      max_age: 65,
      entries: { 20: 300, 30: 350, 40: 400, 50: 500, 60: 600 },
    },
    available_packages: ['health'],
    integrated_drug_deductible: false,
    hsa_eligible: true,
    hospital_stay: 500,
    emergency_stay: 1000,
    pcp_office_visit: 25,
    rx: 15,
    basic_dental_services: 'Not Covered',
    major_dental_services: 'Not Covered',
    preventive_dental_services: 'Covered',
    group_tier_factors: [
      { name: 'employee_only', factor: 1.0 },
      { name: 'employee_and_spouse', factor: 2.0 },
      { name: 'family', factor: 3.0 },
    ],
  },
  {
    id: 'plan2',
    name: 'Silver Plan',
    provider_name: 'MockCarrier B',
    product_type: 'PPO',
    metal_level: 'Silver',
    network: 'Regional HMO',
    deductible: 2000,
    group_deductible: '$4000',
    out_of_pocket_in_network: '$8000',
    group_size_factors: { max_group_size: 100, factors: { '1-50': 1.1, '51-100': 1.0 } },
    participation_factors: { '75-100': 1.05 },
    sic_code_factor: 1.0,
    rates: {
      min_age: 18,
      max_age: 70,
      entries: { 20: 250, 30: 300, 40: 350, 50: 450, 60: 550 },
    },
    available_packages: ['health', 'dental'],
    integrated_drug_deductible: true,
    hsa_eligible: false,
    hospital_stay: 750,
    emergency_stay: 1500,
    pcp_office_visit: 35,
    rx: 25,
    basic_dental_services: '50%',
    major_dental_services: '25%',
    preventive_dental_services: '100%',
    group_tier_factors: [
      { name: 'employee_only', factor: 1.0 },
      { name: 'employee_and_spouse', factor: 1.9 },
      { name: 'family', factor: 2.8 },
    ],
  },
  // Add more detailed mock plans as needed
];

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
