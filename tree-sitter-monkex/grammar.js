module.exports = grammar({
  name: 'monkex',

  extras: $ => [
    /\s/, // whitespace
  ],

  rules: {
    source_file: $ => repeat($._statement),

    _statement: $ => seq(choice(
      $.let_statement,
      $.return_statement,
      $.expression_statement,
    ), optional(';')), // optional semicolon

    expression_statement: $ => $._expression,

    _expression: $ => choice(
      $.if_expression,
      $.function_call,
      $.function_definition,
      $.literal,
      $.array,
      $.object,
      $.identifier,
      $.infix_expression,
      $.prefix_expression,
      $.index_expression,
      $.grouped_expression,
      // Add more as needed
    )
    ,

    grouped_expression: $ => seq(
      '(',
      $._expression,
      ')'
    ),

    infix_expression: $ => choice(
      prec.left(2, seq($._expression, choice("*", "/"), $._expression)),
      prec.left(1, seq($._expression, choice("+", "-"), $._expression)),
      // Assuming comparison operators are left associative as well
      prec.left(0, seq($._expression, choice("==", "!=", ">", "<"), $._expression))
    ),

    index_expression: $ => prec.left(4, seq(
      $._expression,
      '[',
      $._expression,
      ']'
    )),

    prefix_expression: $ => prec.left(3, seq(choice('-', '!'), $._expression)),
    let_statement: $ => seq(
      'let',
      field('name', $.identifier),
      '=',
      $._expression,
    ),

    if_expression: $ => seq(
      'if',
      '(',
      $._expression,
      ')',
      '{',
      repeat($._statement),
      '}',
      optional(seq('else', '{', repeat($._statement), '}'))
    ),

    function_definition: $ => seq(
      'fn',
      '(',
      field('parameters', optional(sepBy(',', $.identifier))),
      ')',
      '{',
      repeat($._statement),
      '}'
    ),

    function_call: $ => prec.left(5, seq(
      $._expression,
      '(',
      field('arguments', optional(sepBy(',', $._expression))),
      ')'
    )),

    return_statement: $ => seq(
      'return',
      $._expression,
    ),

    literal: $ => choice(
      $.number,
      $.string,
      $.boolean,
      // Add other literals as needed
    ),

    array: $ => seq(
      '[',
      optional(sepBy(',', $._expression)),
      ']'
    ),

    object: $ => seq(
      '{',
      optional(sepBy(',', $.key_value_pair)),
      '}'
    ),

    key_value_pair: $ => seq(
      field('key', $._expression),
      ':',
      field('value', $._expression)
    ),

    number: $ => /\d+/,

    string: $ => /"[^"]*"/,

    boolean: $ => choice(
      'true',
      'false'
    ),

    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,
  },
});

function sepBy(sep, rule) {
  return optional(seq(rule, repeat(seq(sep, rule))));
}
