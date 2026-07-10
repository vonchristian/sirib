Rails.application.config.after_initialize do
  # Set a 5-second lock wait timeout to prevent queue buildup
  # This applies to all connections checked out from the pool.
  ActiveRecord::Base.connection_pool.with_connection do |conn|
    conn.execute("SET lock_timeout = '5s'")
  end

  # Also set on new connections via Rails connection callback
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.set_callback(:checkout, :after) do |conn|
    conn.execute("SET lock_timeout = '5s'")
  end
rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad
  # Swallow errors during asset precompile / rake tasks where DB may not exist
end
