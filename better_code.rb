
require 'json'

class DefaultPrinter
  def initialize(person)
    @person = person
  end

  def print(color_code)
    puts @person.inspect
  end

  private

  def title_from_attr_name(attr)
    title = attr.to_s.gsub(/_/, " ")
    letters = title.split("")
    first_letter = letters.shift.upcase
    first_letter + letters.join("")
  end
end

class TextPrinter < DefaultPrinter
  TAB_SIZE = 8

  def print(color_code)
    puts text_border
    print_attributes_as_text(color_code)
    puts text_border
  end

  private

  def text_border
    "=" * (longest_attribute_size + TAB_SIZE * 2)
  end

  def print_attributes_as_text(color_code)
    @person.to_hash.each do |key, value|

      puts "\e[#{color_code}m#{title_from_attr_name(key)}:\e[0m\t#{value}"
    end
  end

  def longest_attribute_size
    @person.to_hash.values.max{|a, b| a.size <=> b.size }.size
  end
end

class JSONPrinter < DefaultPrinter
  def print(color_code)
    puts(@person.to_hash.to_json)
  end
end

class HTMLPrinter < DefaultPrinter
  AVAILABLE_STYLES = {
    30 => %^style="color: black"^,
    31 => %^style="color: red"^,
    32 => %^style="color: green"^,
    33 => %^style="color: yellow"^,
    34 => %^style="color: blue"^,
    35 => %^style="color: magenta"^,
    36 => %^style="color: cyan"^,
    37 => %^style="color: white"^
  }.freeze

  def print(color_code)
    style = style_from_color_code(color_code)
    html = create_html_with_style(style)
    puts sanitize_html(html)
  end

  private

  def style_from_color_code(color_code)
    AVAILABLE_STYLES[color_code]
  end

  def create_html_with_style(style)
    %^
      <table>
        <th><td #{style}>Attribute</td><td>Value</td></th>
        #{table_body(style)}
      </table>
    ^
  end

  def table_body(style)
    @person.to_hash.map do |key, value|
      "<tr><td #{style}>#{title_from_attr_name(key)}</td><td>#{value}</td></tr>"
    end.join("\n")
  end

  def sanitize_html(html)
    html.gsub(/\s{3,}/,"\n")
  end

end

class PersonPrinter
  PRINTERS = {
    text: TextPrinter,
    json: JSONPrinter,
    html: HTMLPrinter,
    default: DefaultPrinter
  }.freeze

  def self.create(person, *formats)
    printer_instances = []
    formats.each do |format|
      if PRINTERS.has_key?(format)
        printer_instances << PRINTERS[format].new(person)
      else
        printer_instances << PRINTERS[:default].new(person)
      end
    end

    self.new(*printer_instances)
  end

  def initialize(*printers)
    @printers = printers
  end

  def print(color_code)
    @printers.each do |printer|
      printer.print(color_code)
    end
  end
end

class Person

  def initialize(attributes)
    @attributes = attributes
    @attributes.each do |key, value|
      instance_variable_set(:"@#{key}", value)
    end
  end

  def to_hash
    @attributes
  end

end

john = Person.new({
  title: "Mr",
  country: "UK",
  first_name: "John",
  last_name: "Deer",
  house_number: "1",
  street: "Baker street",
  town: "London",
  postcode: "W1U 8ED"
})
printer = PersonPrinter.create(john, :text, :json, :html, :xml)
printer.print(32)

p john.to_hash
