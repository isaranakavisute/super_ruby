# Draws a CAPTCHA answer (e.g. "K7MPX") as a distorted PNG, in pure Ruby with chunky_png.
# Each character comes from a 5x7 pixel font, then is slanted, wobbled along a wave, coloured
# randomly and covered with noise dots and lines, so it's easy for people but not for simple bots.
class CaptchaImage
  WIDTH = 220
  HEIGHT = 70
  BLOCK = 5 # size of one font pixel in the image

  # 5 columns x 7 rows per character; "#" = filled
  FONT = {
    "A" => %w[ .###. #...# #...# ##### #...# #...# #...# ],
    "B" => %w[ ####. #...# #...# ####. #...# #...# ####. ],
    "C" => %w[ .###. #...# #.... #.... #.... #...# .###. ],
    "D" => %w[ ####. #...# #...# #...# #...# #...# ####. ],
    "E" => %w[ ##### #.... #.... ####. #.... #.... ##### ],
    "F" => %w[ ##### #.... #.... ####. #.... #.... #.... ],
    "G" => %w[ .###. #...# #.... #.### #...# #...# .#### ],
    "H" => %w[ #...# #...# #...# ##### #...# #...# #...# ],
    "J" => %w[ ..### ...#. ...#. ...#. ...#. #..#. .##.. ],
    "K" => %w[ #...# #..#. #.#.. ##... #.#.. #..#. #...# ],
    "L" => %w[ #.... #.... #.... #.... #.... #.... ##### ],
    "M" => %w[ #...# ##.## #.#.# #.#.# #...# #...# #...# ],
    "N" => %w[ #...# #...# ##..# #.#.# #..## #...# #...# ],
    "P" => %w[ ####. #...# #...# ####. #.... #.... #.... ],
    "Q" => %w[ .###. #...# #...# #...# #.#.# #..#. .##.# ],
    "R" => %w[ ####. #...# #...# ####. #.#.. #..#. #...# ],
    "S" => %w[ .#### #.... #.... .###. ....# ....# ####. ],
    "T" => %w[ ##### ..#.. ..#.. ..#.. ..#.. ..#.. ..#.. ],
    "U" => %w[ #...# #...# #...# #...# #...# #...# .###. ],
    "V" => %w[ #...# #...# #...# #...# #...# .#.#. ..#.. ],
    "W" => %w[ #...# #...# #...# #.#.# #.#.# #.#.# .#.#. ],
    "X" => %w[ #...# #...# .#.#. ..#.. .#.#. #...# #...# ],
    "Y" => %w[ #...# #...# .#.#. ..#.. ..#.. ..#.. ..#.. ],
    "Z" => %w[ ##### ....# ...#. ..#.. .#... #.... ##### ],
    "2" => %w[ .###. #...# ....# ...#. ..#.. .#... ##### ],
    "3" => %w[ ##### ...#. ..#.. ...#. ....# #...# .###. ],
    "4" => %w[ ...#. ..##. .#.#. #..#. ##### ...#. ...#. ],
    "5" => %w[ ##### #.... ####. ....# ....# #...# .###. ],
    "6" => %w[ ..##. .#... #.... ####. #...# #...# .###. ],
    "7" => %w[ ##### ....# ...#. ..#.. .#... .#... .#... ],
    "8" => %w[ .###. #...# #...# .###. #...# #...# .###. ],
    "9" => %w[ .###. #...# #...# .#### ....# ...#. .##.. ]
  }.freeze

  def initialize(text, random: Random.new)
    @text = text
    @random = random
  end

  def to_png
    image = ChunkyPNG::Image.new(WIDTH, HEIGHT, ChunkyPNG::Color.rgb(245, 247, 250))
    draw_noise_dots(image)
    draw_text(image)
    draw_noise_lines(image)
    image.to_blob
  end

  private
    def draw_text(image)
      wave_phase = @random.rand(0.0..Math::PI * 2)
      step = (WIDTH - 30) / @text.size

      @text.each_char.with_index do |char, index|
        color = ChunkyPNG::Color.rgb(@random.rand(20..90), @random.rand(20..90), @random.rand(60..140))
        slant = @random.rand(-0.2..0.2)
        left = 15 + index * step + @random.rand(-3..3)
        top = 15 + @random.rand(-6..6)

        FONT.fetch(char).each_with_index do |row, y|
          row.each_char.with_index do |cell, x|
            next unless cell == "#"

            px = left + x * BLOCK + (slant * (y - 3) * BLOCK).round
            py = top + y * BLOCK + (3 * Math.sin(px / 16.0 + wave_phase)).round
            # Each block is 1px bigger than the grid, so neighbouring blocks overlap and strokes stay joined
            image.rect(px, py, px + BLOCK, py + BLOCK, ChunkyPNG::Color::TRANSPARENT, color)
          end
        end
      end
    end

    def draw_noise_dots(image)
      220.times do
        shade = @random.rand(150..215)
        image[@random.rand(WIDTH), @random.rand(HEIGHT)] = ChunkyPNG::Color.rgb(shade, shade, shade + 20 > 255 ? 255 : shade + 20)
      end
    end

    def draw_noise_lines(image)
      5.times do
        color = ChunkyPNG::Color.rgba(@random.rand(40..120), @random.rand(40..120), @random.rand(40..160), 170)
        x0, y0 = 0, @random.rand(HEIGHT)
        x1, y1 = WIDTH - 1, @random.rand(HEIGHT)
        2.times { |offset| image.line(x0, y0 + offset, x1, y1 + offset, color) }
      end
    end
end
