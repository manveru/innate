require 'hpricot'
require 'open-uri'

class FeedConvert
  def self.parse(doc)
    h = Hpricot(doc, :xml => true)

    if feed = h.at('/feed[@xmlns="http://www.w3.org/2005/Atom"]')
      AtomFeed.new.parse(feed)
    elsif rss = h.at('/rss[@version=2.0]')
      RSS2Feed.new.parse(rss)
    else
      raise "Unknown Feed format"
    end
  end

  class Item < Struct.new(:id, :link, :title, :author, :content)
  end unless defined?(FeedConvert::Item)

  class AtomFeed
    attr_accessor :id, :link, :title, :updated, :items

    def parse(root)
      parse_feed(root)
      return self
    end

    private

    def parse_feed(root)
      self.id      = root.at(:id).inner_text
      self.link    = root.at('link[@rel=alternate]')[:href]
      self.title   = root.at(:title).inner_text
      self.items   = parse_items(root)
      self.updated = Time.parse(root.at(:updated).inner_text)
    end

    def parse_items(root)
      (root/:entry).map do |e|
        item = Item.new

        item.id      = e.at(:id).inner_text
        item.link    = e.at('link[@rel=alternate]')[:href]
        item.title   = e.at(:title).inner_text
        item.author  = e.at('author/name').inner_text
        item.content = e.at(:content).inner_text
        item
      end
    end
  end

  class RSS2Feed
    attr_accessor :title, :link, :description, :language, :items

    def parse(root)
      channel = root.at(:channel)
      parse_channel(channel)
      return self
    end

    private

    def parse_channel(root)
      self.link        = root.at(:link).inner_text
      self.title       = root.at(:title).inner_text
      self.items       = parse_items(root)
      self.language    = root.at(:language).inner_text
      self.description = root.at(:description).inner_text
    end

    def parse_items(root)
      (root/:item).map do |i|
        item = Item.new

        item.id      = i.at(:guid).inner_text
        item.link    = i.at(:link).inner_text
        item.title   = i.at(:title).inner_text
        item.author  = i.at(:author).inner_text.strip.gsub(/\s+/, ' ')
        item.content = Time.parse(i.at(:pubDate).inner_text)
        item
      end
    end
  end
end

# puts "Atom"
# atom = FeedConvert.parse(open('master'))
# pp :id => atom.id, :link => atom.link, :title => atom.title, :updated => atom.updated
# pp atom.items

# puts "RSS"
# rss = FeedConvert.parse(open('rss_v2_0_msgs.xml'))
# pp :link => rss.link, :title => rss.title, :language => rss.language, :description => rss.description
# pp rss.items
