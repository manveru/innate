require 'bacon'

Bacon.summary_on_exit
# Bacon.extend(Bacon::TestUnitOutput)

innate = File.expand_path(File.join(File.dirname(__FILE__), '../innate'))
require(innate) unless defined?(Innate)

module Innate
  # minimal middleware, no exception handling
  middleware(:innate){|m| m.innate }

  # skip starting adapter
  options.started = true
end

# Shortcut to use persistent cookies via Innate::Mock::Session
#
# Usage:
#
#   describe 'something' do
#     behaves_like :session
#
#     should 'get some stuff' do
#       session do |mock|
#         mock.get('/')
#       end
#     end
#   end
shared :session do
  Innate.setup_dependencies

  def session(&block)
    Innate::Mock.session(&block)
  end
end

shared :mock do
  def get(*args) Innate::Mock.get(*args) end
  def post(*args) Innate::Mock.post(*args) end
end

shared :multipart do
  def multipart(hash)
    boundary = 'MuLtIpArT56789'
    data = []
    hash.each do |key, value|
      data << "--#{boundary}"
      data << %(Content-Disposition: form-data; name="#{key}")
      data << '' << value
    end
    data << "--#{boundary}--"
    body = data.join("\r\n")

    type = "multipart/form-data; boundary=#{boundary}"
    length = body.respond_to?(:bytesize) ? body.bytesize : body.size

    { 'CONTENT_TYPE' => type,
      'CONTENT_LENGTH' => length.to_s,
      :input => StringIO.new(body) }
  end
end
