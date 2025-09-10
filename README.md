# cov.nvim

A lightweight Neovim plugin to visualize **Jest/Istanbul coverage** directly in your sign column.  
It reads `./coverage/coverage-final.json` and shows a colored **vertical bar** (`█`) next to every executed line:

- 🟥 **Red** → line never executed  
- 🟨 **Yellow** → executed once  
- 🟩 **Green** → executed more than once  

Perfect for quickly spotting untested or rarely tested code while working in Neovim.

---

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ 'David-Kunz/cov.nvim',
  config = function()
    require("cov").setup()
  end
}
```



## Usage

Run your tests with coverage enabled:

```bash
jest --coverage
```


This generates coverage/coverage-final.json.

Open the file you want to inspect in Neovim.
The plugin will automatically place colored bars in the sign column.

You can refresh manually:

```
:CoverageRefresh
```
