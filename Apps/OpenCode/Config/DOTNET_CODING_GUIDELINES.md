# .NET Coding Guidelines

This document describes our standards and guidelines for .NET development.
The goal is a codebase that is maintainable, testable, and scalable over
time.

## 1. Architecture and Code Structure

We build our systems around **Feature Isolation**, **Vertical Slice
Architecture**, and principles from **Hexagonal Architecture**.

### 1.1 Vertical Slice Architecture & Feature Isolation

Instead of organizing code into technical layers (Controllers, Services,
Repositories), organize it by **feature**.

- **High cohesion:** All code required for a specific feature (Request,
  Response, Handler, Validation) should live together.
- **Low coupling:** A feature must not depend directly on another
  feature's internal logic. If features need to communicate, do it
  through well-defined interfaces or events (e.g., domain events).
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

The core of the application (domain / use cases) must be completely
independent of external frameworks, databases, and UI.

- **Ports (interfaces):** If business logic needs to talk to the outside
  world (e.g., fetch data), it defines an interface (a port).
- **Adapters (implementations):** The infrastructure layer implements
  these interfaces (e.g., a SQL database adapter or a REST client).
- **Dependency direction:** Infrastructure depends on the core (domain).
  The core must *never* depend on infrastructure.

---

## 2. Modern .NET Principles

We use modern C# and .NET features to write safe, concise code.

### 2.1 C# Language Features

- **Nullable reference types:** Must be enabled
  (`<Nullable>enable</Nullable>`). Handle null values explicitly to avoid
  `NullReferenceException`.
- **Records for data:** Use `record` instead of `class` for DTOs,
  commands, queries, and events. This gives built-in immutability and
  value-based equality.
- **File-scoped namespaces:** Use file-scoped namespaces
  (`namespace MyProject.Features;`) to reduce indentation.
- **Global usings:** Collect common `using` directives in a
  `GlobalUsings.cs` file to keep individual files clean.

### 2.2 Asynchronous Programming

- All I/O-bound code (database, network, files) **must** be asynchronous
  (`async`/`await`).
- Always pass a `CancellationToken` through the entire call chain so
  expensive operations can be cancelled when the client disconnects.
- Avoid `Task.Result` or `.Wait()`, since these can cause deadlocks.
- `ConfigureAwait(false)` is normally **not needed** in ASP.NET Core apps
  (there is no `SynchronizationContext` to avoid), but it is relevant in
  shared class libraries that may also be used in contexts with a
  synchronization context (e.g., WPF or classic ASP.NET).

### 2.3 API Design (REPR Pattern)

- Prefer **Minimal APIs** or the **REPR pattern** (Request-Endpoint-
  Response) over large, bloated controllers.
- One endpoint = one class. This limits dependencies to only what that
  specific endpoint needs.

---

## 3. Testing Strategy

Our testing strategy moves away from isolated, class-by-class unit tests
with hundreds of mocked dependencies, and instead focuses on **behavior**
and **integration tests**.

### 3.1 Testing Pyramid vs. "Testing Trophy"

- **Integration tests are king:** Focus on testing the entire vertical
  slice, from the endpoint (or handler) down to the database.
- **Unit tests:** Reserve unit tests for pure business logic, domain
  models, and complex calculations that have no I/O dependencies.

### 3.2 Testcontainers Instead of Mocking / In-Memory

We avoid Entity Framework's in-memory database provider because it does
not behave like a real relational database (e.g., it lacks support for
constraints and transactions).

- Use **Testcontainers** to spin up real databases (e.g., PostgreSQL/SQL
  Server), Redis, or RabbitMQ via Docker during test runs.
- Avoid mocking repository interfaces when you can instead test against a
  real database via Testcontainers.
- Only mock *external* dependencies that we don't control (e.g.,
  third-party payment APIs).

### 3.3 Structure and Libraries

Our testing stack:

- **Framework:** `xUnit`
- **Assertions:** `FluentAssertions` for readability (e.g.,
  `result.Should().BeTrue();`).
- **Web testing:** `WebApplicationFactory<T>` to spin up our API
  in-memory and call it via an HTTP client in tests.

### 3.4 Arrange-Act-Assert (AAA)

Always structure tests using the AAA pattern, with blank lines separating
each section for readability.

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

- Test what the code does, not how it does it. Don't rewrite tests just
  because a private method was renamed internally.
- Don't hardcode IDs or dates. Use test fixtures or a library like Bogus
  to generate dynamic test data.

---

## 4. Error Handling and Validation

### 4.1 Handle Edge Cases and Expected Failure States

Follow these rules whenever you write or generate code that accepts
external input (request bodies, query parameters, route values, command
arguments, etc.):

1. **Validate all required input.** Every argument or request parameter
   that is required must be validated before it is used. Use a
   dedicated validator (e.g., `CreateOrderValidator.cs` next to the
   feature it belongs to), not scattered inline checks.
2. **Validation failures are not exceptions.** A request with invalid or
   missing data must produce a clear, structured error response (e.g.,
   HTTP 400 with a `ProblemDetails` body) — never an unhandled exception
   or a generic 500 error.
3. **Check data shape, not just presence.** Validation must confirm the
   received data matches the expected format/type (e.g., a string that
   should be a GUID, a date in the expected range), not only that a
   field is non-null.
4. **Reserve `throw` for truly unrecoverable states.** Only throw an
   exception when the application has reached a state it cannot recover
   from or reasonably continue past (e.g., the database is unreachable,
   a required configuration value is missing at startup, an invariant
   inside the domain model has been violated by a programming bug).
5. **Invalid user input is never grounds for an exception.** If the
   failure is caused by data the caller supplied, handle it as a
   validation error (see rule 2), even if the input is malformed,
   unexpected, or missing entirely. Do not use `throw` as a substitute
   for input validation.

**Rule of thumb:** if the cause of the failure is "the caller sent
something wrong," return a validation error. If the cause is "the
system itself is broken or in an impossible state," throw an exception.
