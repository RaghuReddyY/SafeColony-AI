# SafeColony-AI Database Schema

## Database

PostgreSQL

---

# Standards

Primary Key

id INTEGER

Audit Columns

created_at

updated_at

Foreign Keys

Proper constraints

Indexes

Frequently searched columns must be indexed.

Enums

Database stores VARCHAR.

Python uses Enum.

---

# Relationships

Organization

↓

Property

↓

Section

↓

Unit

↓

Resident

↓

Visitor

↓

Vehicle

↓

Vacation

↓

Notifications

---

# Tables

## User

Purpose

Stores application users.

Relationships

Resident

Role

Authentication

---

## Organization

Relationships

Property

---

## Property

Relationships

Organization

Section

---

## Section

Relationships

Property

Unit

---

## Unit

Relationships

Section

Resident

---

## Resident

Relationships

Unit

Visitor

Vehicle

Vacation

Notification

---

## Visitor

Relationships

Resident

Vehicle

Guard

---

## Vehicle

Relationships

Resident

Guard

---

## Delivery

Relationships

Resident

Guard

---

## Vacation

Relationships

Resident

Notification

---

## Notification

Relationships

Resident

---

## Security Alert

Relationships

Resident

Guard

---

# Migration Rules

Every schema change must include

- Alembic Migration
- Upgrade
- Downgrade

No manual database modifications.

---

# Index Strategy

Create indexes on

resident_id

property_id

unit_id

visitor_id

vehicle_number

status

created_at

---

# Future

- ER Diagram
- Soft Delete
- Audit Tables