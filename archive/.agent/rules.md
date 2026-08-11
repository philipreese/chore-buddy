# Project Coding Rules

## C# Style Guidelines

Follow standard C# / .NET conventions for all generated code:

### Naming
- **No underscore prefix** for private member variables (use `camelCase`, e.g. `myField` not `_myField`)
- Private fields: `camelCase` (e.g. `myField`)
- Properties and public members: `PascalCase`
- Local variables and parameters: `camelCase`
- Interfaces: prefix with `I` (e.g. `IChoreService`)
- Async methods: suffix with `Async` (e.g. `GetChoresAsync`)

### Braces / Brackets
- **Always use braces `{}` for control flow blocks**, even single-line bodies:
  ```csharp
  // Correct
  if (condition)
  {
      DoSomething();
  }

  // Incorrect — never do this
  if (condition) DoSomething();
  ```
- Opening brace goes on a **new line** (Allman style)
- Apply to: `if`, `else`, `for`, `foreach`, `while`, `do`, `using`, `lock`, `try/catch/finally`

### General
- Prefer `var` only for non-obvious types, like return from LINQ that is IEnumberable<T>
- Use expression-bodied members only for truly trivial one-liners (e.g. simple property getters)
- Use `string.IsNullOrWhiteSpace` over `== null || == ""`
- Prefer `is null` / `is not null` over `== null` / `!= null`
- Use `nameof()` instead of hard-coded string names for member references
- Prefer collection expressions (`[item1, item2]`) and `List<T>` initializers over repeated `.Add()` calls where appropriate
- Mark fields `readonly` wherever possible

### Access Modifiers
- Always explicitly specify access modifiers (do not rely on defaults)

### Comments
- Use XML doc comments (`/// <summary>`) on public APIs
- Avoid commented-out code; delete it instead
