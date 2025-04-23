# Quoting Tool

A web-based application for generating insurance quotes, built with Angular. This tool allows users to upload employee rosters, filter and compare plans, and generate quote documents.

> **Important:** This Angular application is located in the `clients/html` folder inside your Ruby on Rails application. For the quoting tool to work correctly, you must have the Ruby on Rails server running on port 3000. The Angular app communicates with the Rails backend for core functionality.

## Features

- Upload employee rosters (template provided)
- Filter and compare insurance plans
- Generate and download quote documents
- Responsive UI with Bootstrap
- Mock API server for development

## Prerequisites

- Node.js (v18 or later recommended)
- npm (v9 or later)
- macOS, Windows, or Linux

## Installation

1. Clone this repository.
2. Install dependencies:
   ```bash
   npm install
   ```
3. (Optional) Install mock server dependencies:
   ```bash
   cd mock-server
   npm install
   cd ..
   ```

## Running the Application

### 1. Start the Ruby on Rails Server (required)

The application relies on the Rails backend to retrieve data. Make sure your Rails server is running on port 3000 before starting the Angular app.

### 2. (Optional) Start the Mock API Server (secondary backup)

The mock-server is provided as a secondary backup for development and testing purposes only. It is not intended for production use. If you do not have the Rails backend available, you can use the mock-server to simulate API responses.

In a separate terminal:

```bash
cd mock-server
npm start
```

The mock server runs at http://localhost:3002.

### 3. Start the Angular Development Server

In the project root:

```bash
npm start
```

Visit http://localhost:4200 in your browser.

## Building for Production

```bash
npm run build:prod
```

The production build will be in the `dist/` directory.

## Testing

- Unit tests: `npm test`
- End-to-end tests: `npm run e2e`

## Roster Upload Template

A sample Excel template for employee roster uploads is provided at:

```
src/assets/roster_upload_template.xlsx
```

## Project Structure

- `src/app/` - Main Angular application code
- `src/assets/` - Static assets (images, templates)
- `mock-server/` - Mock API server for development
- `e2e/` - End-to-end test setup

## How It Works

1. Upload an employee roster using the provided template.
2. The app fetches plan data from the Rails backend (or the mock API server as a backup).
3. Filter, compare, and select plans.
4. Download quote documents as needed.

## Further Help

- Angular CLI docs: https://angular.io/cli
- For mock server endpoints, see `mock-server/README.md` (for backup/testing only)

---

_Last updated: April 23, 2025_
