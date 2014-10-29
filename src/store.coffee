'use strict'

sql = require 'mssql'

module.exports = (session) ->
	Store = session.Store ? session.session.Store
	
	class MSSQLStore extends Store
		table: 'sessions'
		
		###
		Initialize MSSQLStore with the given `options`.
		
		@param {Object} options
		###
		
		constructor: (options) ->
			@connection = new sql.Connection options
			@connection.connect()
		
		###
		Attempt to fetch session by the given `sid`.
		
		@param {String} sid
		@callback callback
		###
			
		get: (sid, callback) ->
			request = @connection.request()
			request.input 'sid', sid
			request.query "select session from [#{@table}] where sid = @sid", (err, recordset) ->
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
			expires = new Date(data.cookie?.expires ? (Date.now() + 86400))
			
			request = @connection.request()
			request.input 'sid', sid
			request.input 'session', JSON.stringify data
			request.input 'expires', expires
			request.query "merge into [#{@table}] with (holdlock) s using (values(@sid, @session)) as ns (sid, session) on (s.sid = ns.sid) when matched then update set s.session = @session, s.expires = @expires when not matched then insert (sid, session, expires) values (@sid, @session, @expires);", callback
		
		###
		Destroy the session associated with the given `sid`.
		
		@param {String} sid
		@callback callback
		###
		
		destroy: (sid, callback) ->
			request = @connection.request()
			request.input 'sid', sid
			request.query "delete from [#{@table}] where sid = @sid", callback
		
		###
		Fetch number of sessions.
		
		@callback callback
		###
		
		length: (callback) ->
			request = @connection.request()
			request.query "select count(sid) as length from [#{@table}]", (err, recordset) ->
				if err then return callback err
				
				callback null, recordset[0].length
		
		###
		Clear all sessions.
		
		@callback callback
		###
		
		clear: (callback) ->
			request = @connection.request()
			request.query "truncate table [#{@table}]", callback
	
	MSSQLStore