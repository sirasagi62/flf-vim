# 🔍 flf-vim

> [!NOTE]
> This project is in the early stages of development, and its performance and behavior may change.


`flf-vim` is a Vim/Neovim plugin that integrates the **Fluent Finder (flf)** command to provide a **Fuzzy Finder-like UI** for **vector search** of code using an **embedding model**.

It enables developers to efficiently locate highly relevant code snippets within their projects based on vague keywords or conceptual queries.

> [!NOTE]
> You need install [flf](https://github.com/sirasagi62/flf).

-----

### 🚀 Prerequisites

To use this plugin, the following environment and packages are required, in addition to Vim/Neovim:

  * **Node.js**:
      * Required to execute the `flf` package. You cannot use Bun as the runtime.
  * **`@sirasagi62/flf`**:
      * The core `flf` command. It must be installed globally or locally using npm.

Install `flf` using the following command:

```bash
npm install -g @sirasagi62/flf
```

-----

### 💾 Installation

Please use your preferred Vim plugin manager for installation.

#### **Using Vim-Plug**

Add the following line to your `.vimrc` or `init.vim`, and then run `PlugInstall` from within Vim (`:`).

```vim
Plug 'your-github-username/flf-vim' " Replace 'your-github-username' with your actual GitHub username
```

-----

### 🔎 Usage

`flf-vim` provides commands corresponding to the two main search modes of the `flf` tool.

#### **1. Search the Entire Project: `:FlfDir`**

Executes a vector search across the entire root directory of your project and displays the results in a Fuzzy Finder-style window.

```vim
:FlfDir
```

<dir align="center">
<img src="./assets/flfdir.gif" />
</dir>

> [!TIP]
> **Use Case:** Best for finding **where a specific feature or concept is implemented** across the entire project.

#### **2. Search the Current Buffer: `:FlfBuf`**

Executes a vector search only within the content of the currently open buffer.

```vim
:FlfBuf
```

<dir align="center">
<img src="./assets/flfbuf.gif" />
</dir>

> [!TIP]
> **Use Case:** Useful for examining **the context in which a specific variable or helper function is used** within the file you are currently editing.

-----

### 📜 License

This project is licensed under the **MIT License**.

See the `LICENSE` file for more details.

-----

### 🤝 Contributing

Bug reports and feature suggestions are welcome on GitHub Issues. Pull requests are also encouraged.
