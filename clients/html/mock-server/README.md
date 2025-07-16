# Mock API Server

This server provides mock data for the Angular frontend application.

## Setup

1.  Navigate to the `mock-server` directory in your terminal:
    ```bash
    cd mock-server
    ```
2.  Install the dependencies:
    ```bash
    npm install
    ```

## Running the Server

1.  Start the server:
    ```bash
    npm start
    ```

This will start the mock API server on `http://localhost:3002`.

The server provides the following endpoints:

- `GET /api/v1.0/employees/start_on_dates.json`: Returns a list of mock start dates.
- `GET /api/v1.0/samples`: Returns a mock sample message.
- `POST /api/v1.0/employees/upload.json`: Accepts a POST request (expects a JSON body) and returns a success message.
