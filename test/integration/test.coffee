assert = require 'assert'

config = ->
	JSON.parse require('fs').readFileSync "#{__dirname}/../.mssql.json"

session = require 'express-session'
sql = require 'mssql'
MSSQLStore = require('../../src/store') session

SAMPLE =
	somevalue: "yes"
	somenumber: 111
	cookie: expires: new Date()

MODIFIED =
	somevalue: "no"
	somenumber: 222
	cookie: expires: new Date()

TOUCHED =
	cookie: expires: new Date(Date.now() + 1000)

describe 'connect-mssql', ->
	before (done) ->
		sql.connect config(), (err) ->
			if err then return done err
			
			req = new sql.Request
			req.query require('fs').readFileSync("#{__dirname}/../cleanup.sql", 'utf8'), (err) ->
				if err then return done err
				
				req = new sql.Request
				req.query require('fs').readFileSync("#{__dirname}/../prepare.sql", 'utf8'), (err) ->
					if err then return done err
					
					sql.close done

	describe 'basic test suite', ->
		store = null
		
		before (done) ->
			store = new MSSQLStore config()
			store.on 'connect', (err) ->
				if err then return done err
				
				store.clear done
		
		it 'should not find a session', (done) ->
			store.get 'asdf', (err, session) ->
				if err then return done err
				
				assert.ok !session
				
				done()
		
		it 'should create new session', (done) ->
			store.set 'asdf', SAMPLE, done
		
		it 'should get created session', (done) ->
			store.get 'asdf', (err, session) ->
				if err then return done err
				
				assert.strictEqual session.somevalue, SAMPLE.somevalue
				assert.strictEqual session.somenumber, SAMPLE.somenumber
				assert.equal session.cookie.expires, SAMPLE.cookie.expires.toISOString()
				
				done()
		
		it 'should modify session', (done) ->
			store.set 'asdf', MODIFIED, done
		
		it 'should get modified session', (done) ->
			store.get 'asdf', (err, session) ->
				if err then return done err
				
				assert.strictEqual session.somevalue, MODIFIED.somevalue
				assert.strictEqual session.somenumber, MODIFIED.somenumber
				assert.equal session.cookie.expires, MODIFIED.cookie.expires.toISOString()
				
				done()
		
		it 'should touch session', (done) ->
			store.set 'asdf', TOUCHED, done
		
		it 'should get touched session', (done) ->
			store.get 'asdf', (err, session) ->
				if err then return done err
				
				assert.equal session.cookie.expires, TOUCHED.cookie.expires.toISOString()
				
				done()
		
		it 'should remove created session', (done) ->
			store.destroy 'asdf', done
		
		it 'should have no session in db', (done) ->
			store.length (err, length) ->
				if err then return done err
				
				assert.equal length, 0
				
				done()

	describe 'errors', ->
		store = null

		it 'shoud wait for connection establishment', (done) ->
			store = new MSSQLStore config()
			store.get 'asdf', done

		it 'shoud report error when connection is closed', (done) ->
			store.connection.close()
			store.get 'asdf', (err) ->
				assert.ok err
				done()
	
	after (done) ->
		sql.connect config(), (err) ->
			if err then return done err
			
			req = new sql.Request
			req.query require('fs').readFileSync("#{__dirname}/../cleanup.sql", 'utf8'), (err) ->
				if err then return done err
				
				sql.close done
