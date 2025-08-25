# LPEG Cheatsheet

## Basic Usage

```lua
local lpeg = require "lpeg"

local pattern = lpeg.P("hello") *lpeg.S(" \t")^1* lpeg.P("world")
local result = lpeg.match(pattern, "hello   world")
```

## Basic Patterns

| Pattern | Description |
| ----------- | ----------- |
| lpeg.P("str") | Matches literal string "str". |
| lpeg.P(n) | Matches exactly n characters. |
| lpeg.S("set")| Matches any character in the set. |
| lpeg.R("az") | Matches any character in the range a-z. |
| lpeg.R("az", "09")|Matches any character in multiple ranges. |
| lpeg.any(1) or lpeg.P(1) | Matches any single character. |
|lpeg.P(true)|Matches the empty string, always succeeds. |
|lpeg.P(false)|Always fails.|

### Operators (Combinators)

| Operator | Description | Example |
| ----------- | ----------- |  ----------- |
| p1 *p2 | Concatenation. | lpeg.P("a")* lpeg.P("b") |
| p1 + p2 | Ordered choice. | lpeg.P("a") + lpeg.P("b") |
| p1 - p2 | Difference. Matches p1 if p2 does not match. | lpeg.any(1) - lpeg.S(" \t\n")|
| &p|Positive lookahead. |&lpeg.P("a") * lpeg.any(1) |
| !p | Negative lookahead. | !lpeg.P("a") * lpeg.any(1) |
| #p | Length prefix. Matches p and returns its length. | #lpeg.P("abc")(1) |

### Repetition

| Operator | Description |
| ----------- | ----------- |
| p^n| Matches p exactly n times. |
| p^0| Matches p zero or more times (greedy). |
| p^1| Matches p one or more times (greedy). |
| p^-1| Matches p zero or more times (non-greedy). |
| p^0| Matches p zero or more times (greedy). |

### Captures

| Capture | Description |
| ----------- | ----------- |
| lpeg.C(p) | Simple capture. Captures the matched string. |
| lpeg.C(p) | Simple capture. Captures the matched string. |
| lpeg.Ct(p) | Table capture. Collects captures from p into a table. |
| lpeg.Cg(p) | Group capture. Groups captures from p. |
| lpeg.Cp() | Position capture. Captures the current position. |
| lpeg.Cs(p) | Substitution capture. Captures p and returns its captures as a single string. |
| lpeg.Cmt(p, func) | Match-time capture. Runs func during the match. |
| lpeg.Cf(p, func) | Fold capture. Accumulates captures from p using func. |
| p / s | String capture. Replaces the match with string s. |
| p / n | Number capture. Replaces the match with its n-th capture. |
| p / t| Table capture. Replaces the match with t[match]. |
| p / f| Function capture. Replaces the match with f(match).|

### Capture Example

```lua
local lpeg = require "lpeg"
local pair = lpeg.C(lpeg.R("az")^1) *lpeg.P("=")* lpeg.C(lpeg.R("09")^1)
local key, value = lpeg.match(pair, "id=123")
-- key will be "id", value will be "123"
```

### Grammars

A grammar is a table of patterns where lpeg.V(key) refers to another rule in the grammar.

```lua
local lpeg = require "lpeg"

local grammar = {
  "S", -- Initial rule
  S = lpeg.P("(") *(lpeg.V("S") + lpeg.P(1))^0* lpeg.P(")"),
}

local balanced_paren = lpeg.P(grammar)
lpeg.match(balanced_paren, "((a)b(c))") -- Succeeds
```

### Pre-defined Patterns

| Pattern | Equivalent |
| ----------- | ----------- |
|lpeg.patterns.alnum | lpeg.R("AZ", "az", "09")|
|lpeg.patterns.alpha | lpeg.R("AZ", "az") |
|lpeg.patterns.cntrl | lpeg.R("\0\31") |
| lpeg.patterns.digit | lpeg.R("09") |
| lpeg.patterns.graph | lpeg.R("\33\126") |
| lpeg.patterns.lower | lpeg.R("az") |
| lpeg.patterns.print |  lpeg.R("\32\126") |
| lpeg.patterns.punct|lpeg.patterns.graph - lpeg.patterns.alnum |
|lpeg.patterns.space|lpeg.S(" \t\n\r\f\v")|
|lpeg.patterns.upper|lpeg.R("AZ")|
|lpeg.patterns.xdigit|lpeg.R("09", "af", "AF")|
|lpeg.patterns.eof|lpeg.P(-1)|

```lua

