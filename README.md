# Boxen(WIP)

![cover](https://user-images.githubusercontent.com/54525741/201495303-2da20713-00a3-438f-bd2b-1a1126f2893d.png)

Port of [boxen](https://github.com/sindresorhus/boxen) library for elixir.

## Installation

```elixir
def deps do
  [
    {:boxen, "~> 0.1.0"}
  ]
end
```

Documentation: https://hexdocs.pm/boxen

## Usage

```elixir
# Most simple usage
Boxen.boxify("Hello, world")
# => {:ok, string} | {:error, string}

# with title
Boxen.boxify("Hello, world", title: "Message")

# with option
Boxen.boxify("Hello, world")
```

### Helper

## Options

As a keyword list.

### title

Adds title for the box. If width is not provided & title's width is greater than text's width, then box width will be equal to title's width.

Type: `string` | `nil`. Default: `nil`

Example:

```elixir
Boxen.boxify("hello world", title: "Something")
```

### padding

Adds padding inside the box.

Type: `map` | `integer`. Default: 0

For map, the map should contain `top`, `bottom`, `left` and `right` value as atom.

Example

```elixir
# Integer
Boxen.boxify("hello world", padding: 1)

# Map
Boxen.boxify("hello world", padding: %{top: 1, bottom: 1, left: 2, right: 2})
```

It is not necessary to pass all the options inside the map. You can just pass `%{top: 1, bottom: 1}`, and the rest will have the default value of 0.

### margin

Adds margin outside the box. Default: 0

Type: `map` | `integer`

For map, the map should contain `top`, `bottom`, `left` and `right` value as atom.

Example:

```elixir
# Integer
Boxen.boxify("hello world", margin: 1)

# Map
Boxen.boxify("hello world", margin: %{top: 1, bottom: 1, left: 2, right: 2})
```

It is not necessary to pass all the options inside the map. You can just pass `%{top: 1, bottom: 1}`, and the rest will have the default value of 0.

### text_alignment

Alignment of text inside the box.

Type: `atom`

Value: `:left`(default) | `:right` | `:center`

Example:

```elixir
Boxen.boxify("hello \nworld \nelixir is awesome", text_alignment: :center)
```

### title_alignment

Alignment of title on the top of the box.

Type: `atom`

Value: `:left`(default) | `:right` | `:center`

Example:

```elixir
Boxen.boxify("hello world", title: "Message", title_alignment: :center)
```

### box

The box type to show the text content in. Default is `:single`.

Type: `atom` | `map`

Value(taken directly from Boxen library):

- `:fallback`: Just blank space
- `:single`

  ```
  ┌───┐
  │foo│
  └───┘
  ```

- `:double`

  ```
  ╔═══╗
  ║foo║
  ╚═══╝
  ```

- `:round`

  ```
  ╭───╮
  │foo│
  ╰───╯
  ```

- `:bold`

  ```
  ┏━━━┓
  ┃foo┃
  ┗━━━┛
  ```

- `:single_double`

  ```
  ╓───╖
  ║foo║
  ╙───╜
  ```

- `:double_single`

  ```
  ╒═══╕
  │foo│
  ╘═══╛
  ```

- `:classic`

  ```
  +---+
  |foo|
  +---+
  ```

- `:arrow`

  ```
  ↘↓↓↓↙
  →foo←
  ↗↑↑↑↖
  ```

Example:

```elixir
Boxen.boxify("Hello world", box: :double)
```

You can also add your own box through this option. Pass a map containing the following data:

```
top_left,
top,
top_right,
right,
bottom_right,
bottom,
bottom_left,
left
```

It is not necessary to pass all the options inside the map. You can just pass `%{top: 1, bottom: 1}`, and the rest will have the default to blank spaces.

Example:

```elixir
Boxen.boxify("Hello world", box: %{top_left: "->", ....})
```

### width

Set width for the box.

Type: `integer`

Example:

```elixir
Boxen.boxify("hello world", width: 4)
```

If width is less than given text, then the text is hard wrapped to the given width.

### border_color

Sets the color of the border.

Type: `string`

The value should be an ANSI escape sequence for color.

Example(using [IO.ANSI](https://hexdocs.pm/elixir/IO.ANSI.html) module to generate color):

```elixir
red = IO.ANSI.red() #=> "\e[31m"
Boxen.boxify("hello world", border_color: red)
```

### text_color

Sets the color for the whole text.

Type: `string`

The value should be an ANSI escape sequence for color.

Example(using [IO.ANSI](https://hexdocs.pm/elixir/IO.ANSI.html) module to generate color):

```elixir
blue = IO.ANSI.blue() #=> "\e[34m"
Boxen.boxify("hello world", text_color: blue)
```

## Custom coloring

If you want more granular control over color, you can provide your own text with ANSI escape sequence embedded in it. Same applies for title.

Example:

```elixir
text = IO.ANSI.format([:blue, "hello, ", :cyan, "elixir"]) |> IO.chardata_to_string #=> "\e[34mhello, \e[36melixir\e[0m"

Boxen.boxify(text)
```

## Acknowledgments

Thanks to [Sindre Sorhus](https://github.com/sindresorhus) and the contributors of [boxen](https://github.com/sindresorhus/boxen) library. This library is inspired by boxen, and as such, almost all functions are re-written in elixir(with some minor changes here and there).
