# ada_titik-main

**Version:** 1.0.0

## Description

Auto-generated API Documentation with AI Enhancement

## Quality Score

- **Score:** 84/100 (A-)
- **Summary:** Good documentation with room for improvement in: Security.

## Servers

- **Development server:** `adatitik-development.up.railway.app`

## Reports

### GET /reports

**Summary:** Retrieve reports

Retrieves a paginated list of reportss. Supports filtering and sorting through query parameters.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved list of reportss
- **500:** Response

---

### PATCH /reports/{id}

**Summary:** Partially update reports

Partially updates an existing reports by modifying only the specified properties.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| id | path | string | Yes | Path parameter: id |

**Request Body:**

```json
{
  "name": "Sample Reports",
  "description": "This is a sample reports",
  "status": "active"
}
```

**Responses:**

- **200:** Reports updated successfully
- **400:** Response
- **404:** Response
- **500:** Response

---

## Stats

### GET /stats

**Summary:** Retrieve stats

Retrieves a paginated list of statss. Supports filtering and sorting through query parameters.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved list of statss
- **500:** Response

---

## Points

### DELETE /points/{id}

**Summary:** Delete points

Permanently deletes the specified points. This action cannot be undone.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| id | path | string | Yes | Path parameter: id |

**Responses:**

- **200:** Points deleted successfully
- **404:** Response
- **500:** Response

---

## Heatmap

### GET /heatmap

**Summary:** Retrieve heatmap

Retrieves a paginated list of heatmaps. Supports filtering and sorting through query parameters.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved list of heatmaps
- **500:** Response

---

## Register

### POST /register

**Summary:** Create register

Creates a new register with the provided data. Returns the created register with its assigned identifier.

**Request Body:**

```json
{
  "name": "Sample Register",
  "description": "This is a sample register",
  "status": "active"
}
```

**Responses:**

- **201:** Register created successfully
- **400:** Response
- **500:** Response

---

## Login

### POST /login

**Summary:** Create login

Creates a new login with the provided data. Returns the created login with its assigned identifier.

**Request Body:**

```json
{
  "name": "Sample Login",
  "description": "This is a sample login",
  "status": "active"
}
```

**Responses:**

- **201:** Login created successfully
- **400:** Response
- **500:** Response

---

## Me

### GET /me

**Summary:** Retrieve me

Retrieves a paginated list of mes. Supports filtering and sorting through query parameters.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved list of mes
- **500:** Response

---

## Point_id

### GET /{point_id}

**Summary:** Retrieve :point_id

Retrieves detailed information about a specific resource by its unique identifier.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| point_id | path | string | Yes | Path parameter: point_id |
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved resource
- **404:** Response
- **500:** Response

---

## General

### POST /

**Summary:** Create resource

Creates a new resource with the provided data. Returns the created resource with its assigned identifier.

**Request Body:**

```json
{
  "name": "Sample Resource",
  "description": "This is a sample resource",
  "status": "active"
}
```

**Responses:**

- **201:** Resource created successfully
- **400:** Response
- **500:** Response

---

### GET /

**Summary:** Retrieve resource

Retrieves a paginated list of resources. Supports filtering and sorting through query parameters.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved list of resources
- **500:** Response

---

## Nearby

### GET /nearby

**Summary:** Retrieve nearby

Retrieves a paginated list of nearbys. Supports filtering and sorting through query parameters.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved list of nearbys
- **500:** Response

---

## Id

### GET /{id}

**Summary:** Retrieve :id

Retrieves detailed information about a specific resource by its unique identifier.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| id | path | string | Yes | Path parameter: id |
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved resource
- **404:** Response
- **500:** Response

---

### PATCH /{id}

**Summary:** Partially update :id

Partially updates an existing resource by modifying only the specified properties.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| id | path | string | Yes | Path parameter: id |

**Request Body:**

```json
{
  "name": "Sample Resource",
  "description": "This is a sample resource",
  "status": "active"
}
```

**Responses:**

- **200:** Resource updated successfully
- **400:** Response
- **404:** Response
- **500:** Response

---

### PATCH /{id}/status

**Summary:** Partially update :id

Partially updates an existing status by modifying only the specified properties.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| id | path | string | Yes | Path parameter: id |

**Request Body:**

```json
{
  "name": "Sample Status",
  "description": "This is a sample status",
  "status": "active"
}
```

**Responses:**

- **200:** Status updated successfully
- **400:** Response
- **404:** Response
- **500:** Response

---

## Profile

### GET /profile

**Summary:** Retrieve profile

Retrieves a paginated list of profiles. Supports filtering and sorting through query parameters.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved list of profiles
- **500:** Response

---

### PATCH /profile

**Summary:** Partially update profile

Partially updates an existing profile by modifying only the specified properties.

**Request Body:**

```json
{
  "name": "Sample Profile",
  "description": "This is a sample profile",
  "status": "active"
}
```

**Responses:**

- **200:** Profile updated successfully
- **400:** Response
- **500:** Response

---

## Activity

### GET /activity

**Summary:** Retrieve activity

Retrieves a paginated list of activitys. Supports filtering and sorting through query parameters.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved list of activitys
- **500:** Response

---

## Api

### GET /api/notifications/nearby

**Summary:** Retrieve api

Retrieves a paginated list of nearbys. Supports filtering and sorting through query parameters.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved list of nearbys
- **500:** Response

---

## Health

### GET /health

**Summary:** Retrieve health

Retrieves a paginated list of healths. Supports filtering and sorting through query parameters.

**Parameters:**

| Name | Location | Type | Required | Description |
|------|----------|------|----------|-------------|
| page | query | integer | No | Page number for pagination |
| limit | query | integer | No | Number of items per page |

**Responses:**

- **200:** Successfully retrieved list of healths
- **500:** Response

---

