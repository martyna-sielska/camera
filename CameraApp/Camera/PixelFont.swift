import UIKit

struct PixelFont {
  static let glyphWidth = 5
  static let glyphHeight = 7

  static let glyphs: [Character: [String]] = [
    "0": [
      "01110",
      "10001",
      "10011",
      "10101",
      "11001",
      "10001",
      "01110"
    ],
    "1": [
      "00100",
      "01100",
      "00100",
      "00100",
      "00100",
      "00100",
      "01110"
    ],
    "2": [
      "01110",
      "10001",
      "00001",
      "00010",
      "00100",
      "01000",
      "11111"
    ],
    "3": [
      "11110",
      "00001",
      "00001",
      "01110",
      "00001",
      "00001",
      "11110"
    ],
    "4": [
      "00010",
      "00110",
      "01010",
      "10010",
      "11111",
      "00010",
      "00010"
    ],
    "5": [
      "11111",
      "10000",
      "11110",
      "00001",
      "00001",
      "10001",
      "01110"
    ],
    "6": [
      "00110",
      "01000",
      "10000",
      "11110",
      "10001",
      "10001",
      "01110"
    ],
    "7": [
      "11111",
      "00001",
      "00010",
      "00100",
      "01000",
      "01000",
      "01000"
    ],
    "8": [
      "01110",
      "10001",
      "10001",
      "01110",
      "10001",
      "10001",
      "01110"
    ],
    "9": [
      "01110",
      "10001",
      "10001",
      "01111",
      "00001",
      "00010",
      "11100"
    ],
    "-": [
      "00000",
      "00000",
      "00000",
      "11111",
      "00000",
      "00000",
      "00000"
    ],
    ".": [
      "00000",
      "00000",
      "00000",
      "00000",
      "00000",
      "00100",
      "00100"
    ],
    ":": [
      "00000",
      "00100",
      "00100",
      "00000",
      "00100",
      "00100",
      "00000"
    ],
    " ": [
      "00000",
      "00000",
      "00000",
      "00000",
      "00000",
      "00000",
      "00000"
    ]
  ]

  static func textSize(_ text: String, pixelSize: CGFloat, spacing: CGFloat) -> CGSize {
    let count = text.count
    let width = CGFloat(count * glyphWidth) * pixelSize + CGFloat(max(0, count - 1)) * spacing
    let height = CGFloat(glyphHeight) * pixelSize
    return CGSize(width: width, height: height)
  }

  static func draw(
    text: String,
    in context: CGContext,
    origin: CGPoint,
    pixelSize: CGFloat,
    spacing: CGFloat,
    color: UIColor
  ) {
    context.saveGState()
    context.setFillColor(color.cgColor)

    var x = origin.x
    for char in text {
      let glyph = glyphs[char] ?? glyphs[" "]!
      drawGlyph(glyph, in: context, origin: CGPoint(x: x, y: origin.y), pixelSize: pixelSize)
      x += CGFloat(glyphWidth) * pixelSize + spacing
    }

    context.restoreGState()
  }

  private static func drawGlyph(
    _ glyph: [String],
    in context: CGContext,
    origin: CGPoint,
    pixelSize: CGFloat
  ) {
    for (rowIndex, row) in glyph.enumerated() {
      for (colIndex, char) in row.enumerated() where char == "1" {
        let rect = CGRect(
          x: origin.x + CGFloat(colIndex) * pixelSize,
          y: origin.y + CGFloat(rowIndex) * pixelSize,
          width: pixelSize,
          height: pixelSize
        )
        context.fill(rect)
      }
    }
  }
}
