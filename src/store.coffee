'use strict'

sql = require 'mssql'

module.exports = (session) ->
	Store = session.Store ? session.session.Store
	
	class MSSQLStore extends Store
		table: '[sessions]'
		ttl: 1000 * 60 * 60 * 24
		autoRemove: 'never'
		autoRemoveInterval: 1000 * 60 * 10
		autoRemoveCallback: undefined
		useUTC: true
		
		###
		Initialize MSSQLStore with the given `options`.
		
		@param {Object} config
		@param {Object} [options]
		###

		constructor: (config, options) ->
			if options
				if options.table
					{name, schema, database} = sql.Table.parseName options.table
					@table = "#{if database then "[#{database}]." else ""}#{if schema then "[#{schema}]." else ""}[#{name}]"
				
				@ttl = options.ttl if options.ttl
				@autoRemove = options.autoRemove if options.autoRemove
				@autoRemoveInterval = options.autoRemoveInterval if options.autoRemoveInterval
				@autoRemoveCallback = options.autoRemoveCallback if options.autoRemoveCallback
			
			@useUTC = config.options.useUTC if config.options?.useUTC?

			@connection = new sql.Connection config
			@connection.on 'connect', @emit.bind(@, 'connect')
			@connection.on 'error', @emit.bind(@, 'error')
			@connection.connect().then =>
				if @autoRemove is 'interval'
					@destroyExpired()
					setInterval @destroyExpired.bind(@), @autoRemoveInterval
		
		_ready: (callback) ->
			if @connection.connected then return callback.call @
			if @connection.connecting then return @connection.once 'connect', callback.bind @
			callback.call @, new Error "Connection is closed."
		
		###
		Attempt to fetch session by the given `sid`.
		
		@param {String} sid
		@callback callback
		###
		
		get: (sid, callback) ->
			@_ready (err) ->
				if err then return callback err
				
				request = @connection.request()
				request.input 'sid', sid
				request.query "select session from #{@table} where sid = @sid", (err, recordset) ->
					if err then return callback err
					
					if recordset.length
						return callback null, JSON.parse recordset[0].session
					
					callback null, null
		
		###
		Commit the given `sess` object associated with the given `sid`.
		
		@param {String} sid
		@param {Object} data
		@callback callback
		###
		
		set: (sid, data, callback) ->
			@_ready (err) ->
				if err then return callback err
				
				expires = new Date(data.cookie?.expires ? (Date.now() + @ttl))
				
				request = @connection.request()
				request.input 'sid', sid
				request.input 'session', JSON.stringify data
				request.input 'expires', expires
				
				if @connection.config.options.tdsVersion in ['7_1', '7_2']
					# support for sql server 2005, 2000
					request.query "update #{@table} set session = @session, expires = @expires where sid = @sid;if @@rowcount = 0 begin insert into #{@table} (sid, session, expires) values (@sid, @session, @expires) end;", callback
				
				else
					request.query "merge into #{@table} with (holdlock) s using (values(@sid, @session)) as ns (sid, session) on (s.sid = ns.sid) when matched then update set s.session = @session, s.expires = @expires when not matched then insert (sid, session, expires) values (@sid, @session, @expires);", callback
		
		###
		Update expiration date of the given `sid`.
		
		@param {String} sid
		@param {Object} data
		@callback callback
		###
		
		touch: (sid, data, callback) ->
			@_ready (err) ->
				if err then return callback err
				
				expires = new Date(data.cookie?.expires ? (Date.now() + @ttl))
				
				request = @connection.request()
				request.input 'sid', sid
				request.input 'expires', expires
				request.query "update #{@table} set expires = @expires where sid = @sid", callback

		###
		Destroy the session associated with the given `sid`.
		
		@param {String} sid
		@callback callback
		###
		
		destroy: (sid, callback) ->
			@_ready (err) ->
				if err then return callback err
				
				request = @connection.request()
				request.input 'sid', sid
				request.query "delete from #{@table} where sid = @sid", callback

		###
		Destroy expired sessions.
		###
		
		destroyExpired: (callback) ->
			@_ready (err) ->
				if err then return (callback ? @autoRemoveCallback)? err
				
				request = @connection.request()
				request.query "delete from #{@table} where expires <= get#{if @useUTC then "utc" else ""}date()", callback ? @autoRemoveCallback

		###
		Fetch number of sessions.
		
		@callback callback
		###
		
		length: (callback) ->
			@_ready (err) ->
				if err then return callback err
				
				request = @connection.request()
				request.query "select count(sid) as length from #{@table}", (err, recordset) ->
					if err then return callback err
					
					callback null, recordset[0].length
		
		###
		Clear all sessions.
		
		@callback callback
		###
		
		clear: (callback) ->
			@_ready (err) ->
				if err then return callback err
				
				request = @connection.request()
				request.query "truncate table #{@table}", callback
	
	MSSQLStore
