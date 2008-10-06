params = {
  'browser[chrome][engine][name]' => 'V8',
  'browser[chrome][engine][version]' => '1.0',
  'browser[firefox][engine][name]' => 'spidermonkey',
  'browser[firefox][engine][version]' => '1.7.0',
  'emacs[map][goto-line]' => 'M-g g',
  'emacs[version]' => '22.3.1',
  'Paste[Name]' => 'hello world',
  'paste[syntax]' => 'ruby',
  'name' => 'manveru',
  'age' => '42',
}

result = {}

params.each do |key, value|
  if key =~ /^(.*)(\[.*\])/
    prim, nested = $~.captures
    ref = result

    splat = key.scan(/(^[^\[]+)|\[([^\]]+)\]/).flatten.compact
    head, last = splat[0..-2], splat[-1]
    head.inject(ref){|s,v| s[v] ||= {} }[last] = value
  else
    result[key] = value
  end
end

pp result
