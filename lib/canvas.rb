require 'chunky_png'
module Canvas
  class Screen
    attr_accessor :width, :height
    def initialize width, height
      @width, @height = width, height
      @screen = height.times.map{[1]*width}
    end

    def plot x, y, c, a
      @screen[y][x] = (1-a)*@screen[y][x]+a*c if (0...width).include?(x) && (0...height).include?(y)
    end

    def draw image, x, y, w, h
      return if x > width || y > height || x+w < 0 || y+h < 0
      (x.floor...(x+w)).each{|ix|(y.floor...(y+h)).each{|iy|
        plot ix, iy, *image.get((ix-x).fdiv(w), (iy-y).fdiv(h))
      }}
    end

    def to_aa
      (height/2).times.map{|y|
        width.times.map{|x|
          Canvas.char @screen[2*y][x], @screen[2*y+1][x]
        }.join
      }
    end
  end

  class Image
    attr_accessor :width, :height, :bitmap
    def initialize file
      png = ChunkyPNG::Image.from_file file
      @width, @height = png.width, png.height
      @bitmap = height.times.map{|y|
        width.times.map{|x|
          rgb, alpha = png[x, y].divmod 0x100
          col = (((rgb>>16)&0xff)+((rgb>>8)&0xff)+(rgb&0xff))/3
          [col.fdiv(0xff), alpha.fdiv(0xff)]
        }
      }
    end
    def get x, y
      return [0, 0] if x<0 || x>=1 || y<0 || y>=1
      @bitmap[height*y][width*x]
    end
    def sub *args
      if args.size == 4
        x,y,w,h = args
        SubImage.new self, x..(x+w), y..(y+h)
      elsif args.size == 2
        SubImage.new self, *args
      else
        raise
      end
    end
  end

  class SubImage
    def initialize image, xrange, yrange
      @image = image
      @xmin, @xmax = xrange.begin, xrange.end
      @ymin, @ymax = yrange.begin, yrange.end
    end
    def get x, y
      @image.get @xmin+(@xmax-@xmin)*x, @ymin+(@ymax-@ymin)*y
    end
  end

  def self.init_chars chars
    @chars = chars.lines.reject(&:empty?).map{|s|s[1,16]}
  end
  def self.char up, down
    @chars[up*255/16][down*255/16]
  end
end

Canvas.init_chars <<CHARS
|MMMMMM###TTTTTTT|
|QQBMMNW##TTTTTV*|
|QQQBBEK@PTTTVVV*|
|QQQmdE88P9VVVV**|
|QQQmdGDU0YVV77**|
|pQQmAbk65YY?7***|
|ppgAww443vv?7***|
|pggyysxcJv??7***|
|pggyaLojrt<<+**"|
|gggaauuj{11!//""|
|gggaauui])|!/~~"|
|ggaauui]((;::~~^|
|ggaauu](;;::-~~'|
|ggauu(;;;;---~``|
|gaau;;,,,,,...``|
|gau,,,,,,,,...  |
CHARS
