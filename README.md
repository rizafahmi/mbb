# 🤖 Mbb - Model Bahasa Besar

[![Elixir](https://img.shields.io/badge/Elixir-1.18+-4B275F?logo=elixir&logoColor=white)](https://elixir-lang.org/)
[![Claude API](https://img.shields.io/badge/Claude-Haiku%204.5-D97757?logo=anthropic&logoColor=white)](https://www.anthropic.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Mbb** stands for *Model Bahasa Besar* 🇮🇩 — Indonesian for "Large Language Model"

An oversimplified coding assistant CLI built in Elixir. Ask questions, read files, and write code — all from your terminal.

## ✨ Features

- 💬 **Natural Language Interface** — Ask questions in plain English
- 📡 **Real-time Streaming** — See responses as they're generated
- 📖 **File Reading** — Let the assistant read and analyze your code
- ✏️ **File Writing** — Generate and save code directly to disk
- 🔄 **Agentic Loop** — Multi-turn tool use for complex tasks

## 📋 Prerequisites

- [Elixir](https://elixir-lang.org/install.html) 1.18 or later
- [Anthropic API key](https://console.anthropic.com/)

## 🚀 Quick Start

### 1. Clone and build

```bash
git clone https://github.com/rizafahmi/mbb.git
cd mbb
mix deps.get
mix escript.build
```

### 2. Set your API key

```bash
export API_KEY="your-anthropic-api-key"
```

### 3. Run it

```bash
./mbb "What is pattern matching in Elixir?"
```

## 📖 Usage

```bash
# Ask a question
./mbb "Explain GenServer in one paragraph"

# Read and analyze a file
./mbb "Read mix.exs and explain the dependencies"

# Generate code
./mbb "Create a simple GenServer in lib/counter.ex"

# Multi-step tasks
./mbb "What time is it? Write it to timestamp.txt"
```

## 🛠️ Available Tools

| Tool | Description |
|------|-------------|
| `get_current_time` | Returns the current date and time |
| `read_file` | Reads content from a file path |
| `write_file` | Writes content to a file path |

## 🧪 Running Tests

```bash
mix test
```

## 📚 Tutorial

See [TUTORIAL.md](TUTORIAL.md) for a step-by-step guide on how this project was built.

## 🏗️ Architecture

```
User Query → Claude API → SSE Stream → Tool Execution → Response
                              ↑              │
                              └──────────────┘
                              (Agentic Loop)
```

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT
