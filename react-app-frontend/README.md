# react-app-frontend

A React + Redux CRUD app for managing courses and authors, with a local Express API server.

## Requirements

- [Node.js](https://nodejs.org/en/download/) >= 20

## Install & Run

### 1. Install frontend dependencies

```bash
npm install --legacy-peer-deps
```

### 2. Install server dependencies

```bash
cd server
npm install
```

### 3. Start the API server

```bash
# in the server/ directory
npm start
```

The server runs on **http://localhost:4000**.

### 4. Start the frontend

```bash
# back in the root directory
npm start
```

The app opens at **http://localhost:3000**.

## API Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| GET | `/authors` | List all authors |
| GET | `/courses` | List all courses |
| GET | `/courses/:id` | Get a single course |
| POST | `/courses` | Create a course |
| PUT | `/courses/:id` | Update a course |
| DELETE | `/courses/:id` | Delete a course |

## Using a different API

Change the URL in `src/api/serverUrl.js` to point to your own backend.

