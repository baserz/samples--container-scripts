# Kodriktlinjer för .NET (Coding Guidelines)

Detta dokument beskriver våra standarder och riktlinjer för .NET-utveckling.
Syftet är att skapa en kodbas som är underhållsbar, testbar och skalbar över
tid.

## 1. Arkitektur och kodstruktur

Vi bygger våra system med fokus på **Feature Isolation**, **Vertical Slice
Architecture** och principer från **Hexagonal Architecture**.

### 1.1 Vertical Slice Architecture & Feature Isolation

Istället för att organisera koden i tekniska lager (Controllers, Services,
Repositories) organiserar vi den utifrån **funktioner (features)**.

- **Hög kohesion:** All kod som krävs för en specifik funktion (Request,
  Response, Handler, Validering) ska ligga tillsammans.
- **Låg koppling:** En feature får inte direkt bero på en annan features
  interna logik. Behöver funktioner kommunicera görs detta via
  väldefinierade gränssnitt eller events (t.ex. Domain Events).
- **Katalogstruktur:**

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

Kärnan i vår applikation (Domain/Use Cases) ska vara helt oberoende av
yttre ramverk, databaser och UI.

- **Ports (gränssnitt):** Om affärslogiken behöver prata med omvärlden
  (t.ex. hämta data) definierar den ett gränssnitt (port).
- **Adapters (implementationer):** Infrastrukturlagret implementerar dessa
  gränssnitt (t.ex. en SQL-databas-adapter eller en REST-klient).
- **Riktning av beroenden:** Infrastrukturen beror på kärnan (Domain).
  Kärnan beror *aldrig* på infrastrukturen.

---

## 2. Moderna .NET-principer

Vi utnyttjar moderna C#- och .NET-funktioner för att skriva säker och
koncis kod.

### 2.1 C#-språkfunktioner

- **Nullable reference types:** Ska vara aktiverat
  (`<Nullable>enable</Nullable>`). Hantera null-värden explicit för att
  undvika `NullReferenceException`.
- **Records för data:** Använd `record` istället för `class` för DTOs,
  Commands, Queries och Events. Detta ger inbyggd immutabilitet och
  värdebaserad jämförelse.
- **File-scoped namespaces:** Använd filscopade namespaces
  (`namespace MyProject.Features;`) för att minska indentering.
- **Global usings:** Samla gemensamma `using`-direktiv i en
  `GlobalUsings.cs`-fil för att hålla filerna rena.

### 2.2 Asynkron programmering

- All I/O-bunden kod (databas, nätverk, filer) **måste** vara asynkron
  (`async`/`await`).
- Skicka alltid med `CancellationToken` genom hela anropskedjan för att
  kunna avbryta dyra operationer när klienten kopplar ner.
- Undvik `Task.Result` eller `.Wait()` då detta kan leda till deadlocks.
- `ConfigureAwait(false)` behövs normalt **inte** i ASP.NET Core-appar
  (ingen `SynchronizationContext` att undvika), men är relevant i delade
  klassbibliotek som även kan användas i kontext med en
  synkroniseringskontext (t.ex. WPF eller klassisk ASP.NET).

### 2.3 API-design (REPR-mönstret)

- Föredra **Minimal APIs** eller **REPR-mönstret** (Request-Endpoint-
  Response) framför massiva, överfulla Controllers.
- En endpoint = en klass. Detta minskar beroenden till enbart det som just
  den endpointen behöver.

---

## 3. Teststrategi (moderna principer)

Vår teststrategi rör sig bort från isolerade "klass-för-klass"-enhetstester
med hundratals mockade beroenden, och fokuserar istället på **beteende**
och **integrationstester**.

### 3.1 Testpyramiden vs. "Testing Trophy"

- **Integrationstester är kung:** Fokusera på att testa hela din vertical
  slice från endpoint (eller handler) ner till databasen.
- **Enhetstester:** Reservera enhetstester för ren affärslogik,
  domänmodeller och komplexa beräkningar som inte har några
  I/O-beroenden.

### 3.2 Testcontainers istället för mocking/in-memory

Vi undviker Entity Frameworks in-memory-databas eftersom den inte beter
sig som en riktig relationsdatabas (t.ex. saknas stöd för constraints och
transaktioner).

- Använd **Testcontainers** för att spinna upp riktiga databaser (t.ex.
  PostgreSQL/SQL Server), Redis eller RabbitMQ via Docker under
  testkörningen.
- Undvik att mocka repository-gränssnitt om du kan testa mot en riktig
  databas via Testcontainers.
- Mocka endast *externa* beroenden som vi inte har kontroll över (t.ex.
  tredjeparts betalnings-API:er).

### 3.3 Struktur och bibliotek

Vi använder följande stack för testning:

- **Ramverk:** `xUnit`
- **Assertions:** `FluentAssertions` för läsbarhet (t.ex.
  `result.Should().BeTrue();`).
- **Webbtestning:** `WebApplicationFactory<T>` för att snurra upp vårt API
  in-memory och anropa det via en HTTP-klient i testerna.

### 3.4 Arrange-Act-Assert (AAA)

Strukturera alltid tester enligt AAA-mönstret, separerade med tomma rader
för tydlighet.

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

    // (Valfritt: verifiera i den riktiga testdatabasen)
    var orderInDb = await _dbContext.Orders.FirstOrDefaultAsync();
    orderInDb.Should().NotBeNull();
}
```

### 3.5 Undvik test-skörhet (fragile tests)

- Testa vad koden gör, inte hur den gör det. Byt inte ut tester bara för
  att en intern privat metod byter namn.
- Hårdkoda inte id:n eller datum. Använd test-fixtures eller bibliotek som
  Bogus för att generera dynamisk testdata.