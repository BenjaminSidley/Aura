Given("an album {string} by {string} exists") do |title, artist|
  Album.create!(title: title, artist: artist, year: 2000)
end

When("I visit the album page for {string}") do |title|
  album = Album.find_by(title: title)
  visit album_path(album)
end
