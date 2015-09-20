'use strict'

sql = require 'mssql'

module.exports = (session) ->
	Store = session.Store ? session.session.Store
	
	class MSSQLStore extends Store
		table: '[sessions]'
		
		###
		Initialize MSSQLStore with the given `options`.
		
		@param {Object} config
		@param {Object} [options]
		###
		
		constructor: (config, options) ->
			@table = "[" + options.table + "]" if options?.table
			@table = "[" + config.schema + "].#{@table}" if config?.schema
				
			@connection = new sql.Connection config
			@connection.on 'connect', @emit.bind(@, 'connect')
			@connection.on 'error', @emit.bind(@, 'error')
			@connection.connect()
		
		###
		Attempt to fetch session by the given `sid`.
		
		@param {String} sid
		@callback callback
		###
			
		get: (sid, callback) ->
			if !this.connection.connected then return callback null, null
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
			if !this.connection.connected then return callback null, null
			expires = new Date(data.cookie?.expires ? (Date.now() + 86400*1000))
			
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
			if !this.connection.connected then return callback null, null
			expires = new Date(data.cookie?.expires ? (Date.now() + 86400*1000))
			
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
			if !this.connection.connected then return callback null, null
			request = @connection.request()
			request.input 'sid', sid
			request.query "delete from #{@table} where sid = @sid", callback
		
		###
		Fetch number of sessions.
		
		@callback callback
		###
		
		length: (callback) ->
			if !this.connection.connected then return callback null, null
			request = @connection.request()
			request.query "select count(sid) as length from #{@table}", (err, recordset) ->
				if err then return callback err
				
				callback null, recordset[0].length
		
		###
		Clear all sessions.
		
		@callback callback
		###
		
		clear: (callback) ->
			if !this.connection.connected then return callback null, null
			request = @connection.request()
			request.query "truncate table #{@table}", callback
	
	MSSQLStore
