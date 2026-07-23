class AnalyticsService
  def initialize(user = nil)
    @user = user
    @lastfm_client = LastfmClient.new(user)
  end

  def lastfm_top_artists(limit: 5, lookback: 100)
    return [] unless @user&.lastfm_connected

    tracks = @lastfm_client.recent_tracks(limit: lookback)
    counts = Hash.new(0)
    tracks.each { |t| counts[t[:artists]] += 1 if t[:artists].present? }
    counts.sort_by { |_, v| -v }.first(limit).map { |artist, plays| { artist: artist, plays: plays } }
  end

  def lastfm_top_tracks(limit: 5, lookback: 100)
    return [] unless @user&.lastfm_connected

    tracks = @lastfm_client.recent_tracks(limit: lookback)
    counts = Hash.new(0)
    tracks.each do |t|
      key = "#{t[:name]} — #{t[:artists]}"
      counts[key] += 1 if t[:name].present?
    end
    counts.sort_by { |_, v| -v }.first(limit).map do |k, plays|
      name, artist = k.split(' — ', 2)
      { track: name, artist: artist, plays: plays }
    end
  end

  def aura_top_rated_songs(limit: 5)
    Rails.cache.fetch("analytics:aura_top_rated_songs:#{limit}", expires_in: 1.hour) do
      Song.joins(:reviews)
          .select('songs.*, AVG(reviews.rating) AS avg_rating')
          .group('songs.id')
          .order('avg_rating DESC')
          .limit(limit)
          .to_a
    end
  end

  def user_top_rated_songs(limit: 5)
    return [] unless @user
    Song.joins(:reviews)
        .where(reviews: { user_id: @user.id })
        .select('songs.*, AVG(reviews.rating) AS avg_rating')
        .group('songs.id')
        .order('avg_rating DESC')
        .limit(limit)
  end

  def recommendations_for_user(limit: 5)
    return [] unless @user

    cache_key = "analytics:recommendations:user:#{@user.id}:limit:#{limit}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      # 1) Prefer similar songs to the user's 5 most recent reviewed songs
      reviewed_songs = @user.reviews.order(created_at: :desc).limit(5).includes(:song).map(&:song).compact
      reviewed_song_ids = @user.reviews.pluck(:song_id)

      suggestions = []

      if reviewed_songs.any?
        # Collect similar tracks for all reviewed songs
        similar_tracks = reviewed_songs.flat_map do |s|
          @lastfm_client.track_similar(s.artist, s.title, limit: 10)
        end.compact

        # Batch-find any matching Song records and build a mapping from normalized pair -> Song
        song_map = batch_find_songs_map(similar_tracks, reviewed_song_ids)

        # Iterate in original order: prefer Last.fm entries (name/artist) first in the UI.
        similar_tracks.uniq! { |t| [t[:name].to_s.downcase, t[:artist].to_s.downcase] }
        similar_tracks.each do |t|
          break if suggestions.size >= limit
          key = [t[:name].to_s.strip.downcase, t[:artist].to_s.strip.downcase]
          if song_map[key]
            song = song_map[key]
            next if reviewed_song_ids.include?(song.id) || suggestions.any? { |s| s.is_a?(Song) && s.id == song.id }
            suggestions << song
          else
            # push a lightweight Last.fm entry when no local match exists
            suggestions << { name: t[:name], artist: t[:artist], url: t[:url], source: 'lastfm' }
          end
        end
      end

      # 2) If no reviewed songs or no suggestions, use the user's recent Last.fm listens
      if suggestions.size < limit && @user.lastfm_connected?
        begin
          recent = @lastfm_client.recent_tracks(limit: 10)
          Rails.logger.debug("[AnalyticsService] Recent tracks count: #{recent.size}")
          
          recent_similar = recent.flat_map do |r|
            artist = r[:artists] || r[:artist]
            name = r[:name]
            next unless artist.present? && name.present?
            
            similar = @lastfm_client.track_similar(artist, name, limit: 10)
            Rails.logger.debug("[AnalyticsService] Similar tracks for #{name} by #{artist}: #{similar.size}")
            similar
          end.compact

          # Batch-find mapped songs for recent_similar and append entries to fill remaining slots.
          recent_map = batch_find_songs_map(recent_similar, reviewed_song_ids + suggestions.select { |s| s.is_a?(Song) }.map(&:id))

          recent_similar.uniq! { |t| [t[:name].to_s.downcase, t[:artist].to_s.downcase] }
          recent_similar.each do |t|
            break if suggestions.size >= limit
            key = [t[:name].to_s.strip.downcase, t[:artist].to_s.strip.downcase]
            if recent_map[key]
              song = recent_map[key]
              next if reviewed_song_ids.include?(song.id) || suggestions.any? { |s| s.is_a?(Song) && s.id == song.id }
              suggestions << song
            else
              suggestions << { name: t[:name], artist: t[:artist], url: t[:url], source: 'lastfm' }
            end
          end
        rescue StandardError => e
          Rails.logger.error("[AnalyticsService] Error fetching Last.fm recommendations: #{e.message}")
        end
      end

      # 3) Final fallback: most recently reviewed songs on the platform
      if suggestions.empty?
        suggestions = most_recently_reviewed_songs(limit: limit).to_a
      end

      suggestions.compact.uniq.first(limit)
    end
  end

  def recommendations_for_song(song, user = nil, limit: 5)
    return [] unless song

    recs = Song.where(artist: song.artist).where.not(id: song.id)
               .joins('LEFT JOIN reviews ON reviews.song_id = songs.id')
               .select('songs.*, AVG(reviews.rating) AS avg_rating')
               .group('songs.id')
               .order('avg_rating DESC NULLS LAST')
               .limit(limit)

    if recs.blank? && user
      recs = AnalyticsService.new(user).recommendations_for_user(limit: limit)
    end

    recs
  end

  private

  def aura_fallback_recommendations(limit)
    # By default, recommend the most recently reviewed songs on the platform
    Rails.cache.fetch("analytics:most_recently_reviewed_songs:#{limit}", expires_in: 1.hour) do
      most_recently_reviewed_songs(limit: limit).to_a
    end
  end

  def most_recently_reviewed_songs(limit: 5)
  Song.joins(:reviews)
    .select('songs.*, MAX(reviews.created_at) AS last_reviewed_at')
    .group('songs.id')
    .order('last_reviewed_at DESC')
    .limit(limit)
  end

  # Given an array of similar tracks (hashes with :name and :artist), perform a single DB query
  # to find matching Song records. This avoids the N+1 pattern of querying per-similar-track.
  def batch_find_songs_from_similar(similar_tracks, excluded_ids = [], limit = 5)
    return [] if similar_tracks.blank? || limit <= 0

    conn = ActiveRecord::Base.connection
    pairs = similar_tracks.map { |t| [t[:name].to_s.strip.downcase, t[:artist].to_s.strip.downcase] }
                         .uniq

    exact_clauses = []
    fuzzy_clauses = []

    pairs.each do |name, artist|
      next if name.blank?
      q_name = conn.quote(name)
      if artist.present?
        q_artist = conn.quote(artist)
        exact_clauses << "(LOWER(songs.title) = #{q_name} AND LOWER(songs.artist) = #{q_artist})"
        fuzzy_clauses << "(LOWER(songs.title) = #{q_name} AND LOWER(songs.artist) LIKE #{conn.quote("%#{artist}%")})"
      else
        exact_clauses << "(LOWER(songs.title) = #{q_name})"
      end
    end

    where_sql = ([exact_clauses, fuzzy_clauses].flatten.reject(&:blank?).join(' OR '))
    return [] if where_sql.blank?

    excluded_ids = Array(excluded_ids).compact

    results = Song.where.not(id: excluded_ids)
                  .where(where_sql)
                  .joins('LEFT JOIN reviews ON reviews.song_id = songs.id')
                  .select('songs.*, AVG(reviews.rating) AS avg_rating')
                  .group('songs.id')
                  .order('avg_rating DESC NULLS LAST')
                  .limit(limit)
                  .to_a

    # If the strict/exact+title-fuzzy matching produced nothing, try a looser ILIKE-based
    # batch query: title ILIKE '%name%' AND artist ILIKE '%artist%'. This helps match
    # tracks where punctuation, parentheses, or small variations prevent exact equality.
    if results.blank?
      loose_clauses = pairs.map do |name, artist|
        next if name.blank?
        q_name = conn.quote("%#{name}%")
        if artist.present?
          q_artist = conn.quote("%#{artist}%")
          "(LOWER(songs.title) LIKE #{q_name} AND LOWER(songs.artist) LIKE #{q_artist})"
        else
          "(LOWER(songs.title) LIKE #{q_name})"
        end
      end.compact

      loose_where = loose_clauses.join(' OR ')
      if loose_where.present?
        results = Song.where.not(id: excluded_ids)
                      .where(loose_where)
                      .joins('LEFT JOIN reviews ON reviews.song_id = songs.id')
                      .select('songs.*, AVG(reviews.rating) AS avg_rating')
                      .group('songs.id')
                      .order('avg_rating DESC NULLS LAST')
                      .limit(limit)
                      .to_a
      end
    end

    results
  end

  # Returns a Hash mapping normalized [title, artist] => Song for the provided similar_tracks.
  # This is used to quickly map Last.fm entries back to local Song records without per-track queries.
  def batch_find_songs_map(similar_tracks, excluded_ids = [])
    return {} if similar_tracks.blank?

    conn = ActiveRecord::Base.connection
    pairs = similar_tracks.map { |t| [t[:name].to_s.strip.downcase, t[:artist].to_s.strip.downcase] }
                         .uniq

    clauses = []
    pairs.each do |name, artist|
      next if name.blank?
      q_name = conn.quote(name)
      if artist.present?
        q_artist = conn.quote(artist)
        clauses << "(LOWER(songs.title) = #{q_name} AND LOWER(songs.artist) = #{q_artist})"
      else
        clauses << "(LOWER(songs.title) = #{q_name})"
      end
    end

    where_sql = clauses.reject(&:blank?).join(' OR ')
    return {} if where_sql.blank?

    excluded_ids = Array(excluded_ids).compact

    found = Song.where.not(id: excluded_ids)
                .where(where_sql)
                .joins('LEFT JOIN reviews ON reviews.song_id = songs.id')
                .select('songs.*')
                .group('songs.id')
                .to_a

    map = {}
    found.each do |s|
      key = [s.title.to_s.strip.downcase, s.artist.to_s.strip.downcase]
      map[key] ||= s
    end

    map
  end
end
