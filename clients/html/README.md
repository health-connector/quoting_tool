# Quoting Tool

A web-based application for generating insurance quotes, built with Angular. This tool allows users to upload employee rosters, filter and compare plans, and generate quote documents. A mock API server is included for local development and testing.

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

### 1. Start the Mock API Server (for local development)

In a separate terminal:

```bash
cd mock-server
npm start
```

The mock server runs at http://localhost:3002.

### 2. Start the Angular Development Server

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
2. The app fetches plan data from the mock API server.
3. Filter, compare, and select plans.
4. Download quote documents as needed.

## Further Help

- Angular CLI docs: https://angular.io/cli
- For mock server endpoints, see `mock-server/README.md`

---

_Last updated: April 23, 2025_
