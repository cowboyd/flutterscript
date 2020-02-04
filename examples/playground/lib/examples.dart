const examples = const {
  "Empty": "()",

  "Hello World": """(Text "Hello World")""",

  "StyleText": """(Text "Hello World"
    style: (TextStyle 
      color: (color "red")
      fontSize: 24.0)
  )""",

  "FlatButton": """(FlatButton (Text "Hello World"))"""
};