# .NET Coding Guidelines

Standards and guidelines for .NET development. Goal: a codebase that is
maintainable, testable, and scalable over time.

## 1. Architecture and Code Structure

Built around **Feature Isolation**, **Vertical Slice Architecture**, and
principles from **Hexagonal Architecture**.

### 1.1 Vertical Slice Architecture & Feature Isolation

Organize code by **feature**, not by technical layer (Controllers,
Services, Repositories).

- **High cohesion:** All code for a specific feature (Request, Response,
  Handler, Validation) lives together.
- **Low coupling:** A feature must not depend directly on another
  feature's internal logic. Cross-feature communication goes through
  well-defined interfaces or events (e.g., domain events).
- **Directory structure:**

  ```text
  📂 Features
     📂 Orders
        📂 CreateOrder
           📄 CreateOrderEndpoint.cs
           📄 CreateOrderCommand.cs
           📄 CreateOrderHandler.cs
           📄 CreateOrderValidator.cs
        📂 GetOrderById
           📄 GetOrderByIdEndpoint.cs
           ...
  ```

### 1.2 Hexagonal Architecture (Ports and Adapters)

The core (domain / use cases) must be completely independent of external
frameworks, databases, and UI.

- **Ports (interfaces):** Business logic defines an interface (port) when
  it needs to talk to the outside world (e.g., fetch data).
- **Adapters (implementations):** Infrastructure implements those
  interfaces (e.g., a SQL adapter, a REST client).
- **Dependency direction:** Infrastructure depends on the core. The core
  *never* depends on infrastructure.

---

## 2. Modern .NET Principles

### 2.1 C# Language Features

- **Nullable reference types:** Must be enabled
  (`<Nullable>enable</Nullable>`); handle null explicitly to avoid
  `NullReferenceException`.
- **Records for data:** Use `record`, not `class`, for DTOs, commands,
  queries, and events — built-in immutability and value-based equality.
- **File-scoped namespaces:** `namespace MyProject.Features;` to reduce
  indentation.
- **Global usings:** Collect common `using` directives in
  `GlobalUsings.cs`.

### 2.2 Asynchronous Programming

- All I/O-bound code (database, network, files) **must** be
  `async`/`await`.
- Pass a `CancellationToken` through the entire call chain so expensive
  operations can be cancelled on client disconnect.
- Avoid `Task.Result` / `.Wait()` — can cause deadlocks.
- `ConfigureAwait(false)` is normally **not needed** in ASP.NET Core (no
  `SynchronizationContext` to avoid), but is relevant in shared class
  libraries also used in contexts that have one (e.g., WPF, classic
  ASP.NET).

### 2.3 API Design (REPR Pattern)

- Prefer **Minimal APIs** or the **REPR pattern** (Request-Endpoint-
  Response) over large, bloated controllers.
- One endpoint = one class, so each endpoint depends only on what it
  actually needs.

---

## 3. Testing Strategy

Moves away from isolated, class-by-class unit tests with heavily mocked
dependencies, toward **behavior** and **integration tests**.

### 3.1 Testing Pyramid vs. "Testing Trophy"

- **Integration tests are king:** test the full vertical slice, endpoint
  (or handler) down to the database.
- **Unit tests:** reserved for pure business logic, domain models, and
  complex calculations with no I/O dependencies.

### 3.2 Testcontainers Instead of Mocking / In-Memory

Avoid EF's in-memory database provider — it doesn't behave like a real
relational database (no constraints, no transactions).

- Use **Testcontainers** to spin up real databases (e.g.,
  PostgreSQL/SQL Server), Redis, or RabbitMQ via Docker during tests.
- Avoid mocking repository interfaces when you can test against a real
  database via Testcontainers instead.
- Only mock *external* dependencies outside our control (e.g.,
  third-party payment APIs).

### 3.3 Structure and Libraries

- **Framework:** `xUnit`
- **Assertions:** `FluentAssertions` (e.g., `result.Should().BeTrue();`)
- **Web testing:** `WebApplicationFactory<T>` to spin up the API
  in-memory and call it via an HTTP client.

### 3.4 Arrange-Act-Assert (AAA)

Structure tests using AAA, with blank lines separating each section.

```csharp
[Fact]
public async Task CreateOrder_WithValidData_ShouldSaveToDatabase()
{
    // Arrange
    var client = _factory.CreateClient();
    var command = new CreateOrderCommand("Product1", 2);

    // Act
    var response = await client.PostAsJsonAsync("/api/orders", command);

    // Assert
    response.StatusCode.Should().Be(HttpStatusCode.Created);

    // (Optional: verify against the real test database)
    var orderInDb = await _dbContext.Orders.FirstOrDefaultAsync();
    orderInDb.Should().NotBeNull();
}
```

### 3.5 Avoid Fragile Tests

- Test what the code does, not how — don't rewrite tests just because a
  private method was renamed internally.
- Don't hardcode IDs or dates; use test fixtures or a library like Bogus
  for dynamic test data.

---

## 4. Error Handling and Validation

### 4.1 Handle Edge Cases and Expected Failure States

Apply these rules whenever code accepts external input (request bodies,
query parameters, route values, command arguments, etc.):

1. **Validate all required input.** Every required argument or request
   parameter must be validated before use, via a dedicated validator
   (e.g., `CreateOrderValidator.cs` next to its feature) — not scattered
   inline checks.
2. **Validation failures are not exceptions.** Invalid or missing data
   must produce a clear, structured error response (e.g., HTTP 400 with
   `ProblemDetails`) — never an unhandled exception or generic 500.
3. **Check data shape, not just presence.** Confirm the data matches the
   expected format/type (e.g., a GUID-shaped string, a date in range) —
   not just that a field is non-null.
4. **Reserve `throw` for truly unrecoverable states** — e.g., the
   database is unreachable, a required config value is missing at
   startup, a domain invariant was violated by a programming bug.
5. **Invalid user input is never grounds for an exception.** If the
   caller supplied the bad data, handle it as a validation error (rule
   2) regardless of how malformed or missing it is. Never use `throw` as
   a substitute for input validation.

**Rule of thumb:** caller sent something wrong → validation error. The
system itself is broken or in an impossible state → exception.
