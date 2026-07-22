# API Guidelines

## REST Principles

Use

GET

POST

PUT

PATCH

DELETE

---

# URL Convention

/api/v1/resource

Examples

/api/v1/residents

/api/v1/visitors

/api/v1/vehicles

---

# Authentication

JWT Bearer Token

Required for all protected APIs.

---

# Authorization

Role Based Access

Admin

Guard

Resident

Manager

---

# Standard Success Response

```json
{
  "success": true,
  "message": "Resident created successfully",
  "data": {}
}
```

---

# Standard Error Response

```json
{
  "success": false,
  "message": "Resident not found"
}
```

---

# Status Codes

200 OK

201 Created

204 No Content

400 Bad Request

401 Unauthorized

403 Forbidden

404 Not Found

409 Conflict

500 Internal Server Error

---

# Validation

Validation should be performed in

Pydantic Schemas

Business validation inside Service Layer.

---

# Pagination

Use

page

page_size

Future

cursor-based pagination

---

# Filtering

Support

status

date

resident

property

organization

---

# Sorting

sort_by

sort_order

---

# Search

Use keyword-based searching where applicable.

---

# API Documentation

Every endpoint must include

Summary

Description

Request Schema

Response Schema

Status Codes

---

# Versioning

All APIs

/api/v1/

Future

/api/v2/

---

# Exception Handling

Use custom exceptions

BadRequestException

ConflictException

NotFoundException

ForbiddenException

No HTTPException inside services.

---

# Service Rules

API

↓

Service

↓

Repository

↓

Database

No service should directly execute SQL.

---

# Definition of Done

An API is complete only if

✔ Model

✔ Schema

✔ Repository

✔ Service

✔ API

✔ Validation

✔ Logging

✔ Exception Handling

✔ Event Publishing (if required)

✔ Alembic Migration

✔ Swagger Verification