# SafeColony-AI Architecture

## Overview

SafeColony-AI is an enterprise-grade Residential Community Management Platform built using a layered architecture to ensure scalability, maintainability, and separation of concerns.

---

# Technology Stack

Backend
- Python 3.13
- FastAPI
- SQLAlchemy 2.x
- PostgreSQL
- Alembic

Authentication
- JWT
- Role Based Access Control (RBAC)

Architecture
- Repository Pattern
- Service Layer
- Dependency Injection
- Event Bus
- Pydantic DTOs

Future
- Redis
- Celery
- AI Services
- Docker
- Kubernetes

---

# Folder Structure

app/
│
├── api/
├── auth/
├── core/
├── database/
├── enums/
├── events/
├── handlers/
├── models/
├── repositories/
├── schemas/
├── services/
└── utils/

---

# Layered Architecture

Client
    │
    ▼
FastAPI Router
    │
    ▼
Service Layer
    │
    ▼
Repository Layer
    │
    ▼
SQLAlchemy
    │
    ▼
PostgreSQL

---

# Responsibilities

## API

- Request Validation
- Authentication
- Authorization
- Response Formatting

No business logic.

---

## Service

Contains

- Business Logic
- Validation
- Event Publishing
- Logging
- Exception Handling

No SQL queries.

---

## Repository

Responsible for

- CRUD
- Database Queries
- Transactions
- Pagination

No business rules.

---

## Models

Represent database tables.

---

## Schemas

Represent API request and response DTOs.

---

# Event Bus

Business events publish through EventBus.

Examples

- Visitor Approved
- Vehicle Entered
- Vacation Started
- Security Alert Raised
- Incident Created

Handlers process events asynchronously.

---

# Dependency Flow

API

↓

Service

↓

Repository

↓

Database

---

# Exception Handling

Custom Exceptions

- BadRequestException
- ConflictException
- NotFoundException
- ForbiddenException

Handled centrally.

---

# Logging

Every service should log

- Business Events
- Errors
- Warnings

---

# Future Components

- Notification Engine
- Scheduler
- AI Engine
- Analytics
- Report Generator
- Mobile API