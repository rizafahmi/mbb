# 🤝 Contributing to Mbb

Thank you for your interest in contributing to Mbb! This document provides guidelines for contributing.

## 🚀 Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/mbb.git
   cd mbb
   ```
3. **Install dependencies**:
   ```bash
   mix deps.get
   ```
4. **Run tests** to ensure everything works:
   ```bash
   mix test
   ```

## 📝 Making Changes

1. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and write tests if applicable

3. **Run tests** before committing:
   ```bash
   mix test
   ```

4. **Format your code**:
   ```bash
   mix format
   ```

5. **Commit your changes** with a clear message:
   ```bash
   git commit -m "feat: add new tool for X"
   ```

## 📋 Commit Message Format

We use conventional commits:

- `feat:` — New feature
- `fix:` — Bug fix
- `docs:` — Documentation changes
- `refactor:` — Code refactoring
- `test:` — Adding or updating tests

## 🔧 Adding New Tools

When adding a new tool for the assistant:

1. Add the tool definition to `@tools` in `lib/mbb.ex`
2. Implement `execute_tool/2` clause for your tool
3. Add tests in `test/mbb_test.exs`
4. Update the README with the new tool

## 🐛 Reporting Issues

When reporting issues, please include:

- Elixir version (`elixir --version`)
- Steps to reproduce
- Expected vs actual behavior
- Error messages if any

## 💡 Feature Requests

Feature requests are welcome! Please open an issue describing:

- The problem you're trying to solve
- Your proposed solution
- Any alternatives you've considered

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.
