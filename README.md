# connect-mssql

SQL Server session store for Connect/Express based on [![Github Stars][mssql-image] node-mssql][mssql-url].

[![NPM Version][npm-image]][npm-url] [![NPM Downloads][downloads-image]][downloads-url] [![Appveyor CI][appveyor-image]][appveyor-url]

## Installation

    npm install connect-mssql

## Prerequisites

Before you can use session store, you must create a table. Recomended table name is `sessions` but you can change it via options.

```sql
CREATE TABLE [dbo].[sessions](
    [sid] [varchar](255) NOT NULL PRIMARY KEY,
    [session] [varchar](max) NOT NULL,
    [expires] [datetime] NOT NULL
)
```

## Usage

```javascript
var session = require('express-session');
var MSSQLStore = require('connect-mssql')(session);

var config = {
    user: '...',
    password: '...',
    server: 'localhost', // You can use 'localhost\\instance' to connect to named instance
    database: '...',
    
    options: {
        encrypt: true // Use this if you're on Windows Azure
    }
}

app.use(session({
    store: new MSSQLStore(config, options), // options are optional
    secret: 'supersecret'
}));
```

### Options

- **options.table** - Table to use as session store. Default: `[sessions]`
- **options.ttl** - (Time To Live) Determines the expiration date. Default: `1000 * 60 * 60 * 24` (24 hours)
- **options.autoRemove** - Determines if expired sessions should be autoremoved or not. If value is `interval` then a new function, `destroyExpired()`, will autodelete expired sessions on a set interval. Default: `never`
- **options.autoRemoveInterval** - Sets the timer interval for each call to `destroyExpired()`. Default: `1000 * 60 * 10` (10 min)
- **options.autoRemoveCallback** - Is the callback function for `destroyExpired()`. Default: `undefined`

### Advanced usage

```javascript
var store = new MSSQLStore(config, options);

store.on('connect', function() {
	// ... connection established
});

store.on('error', function() {
	// ... connection error
});

app.use(session({
    store: store
    secret: 'supersecret'
}));
```

## Configuration

To see all options please visit [node-mssql docs](https://github.com/patriksimek/node-mssql#cfg-basic).

<a name="license" />
## License

Copyright (c) 2014-2016 Patrik Simek

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[npm-image]: https://img.shields.io/npm/v/connect-mssql.svg?style=flat-square
[npm-url]: https://www.npmjs.com/package/connect-mssql
[downloads-image]: https://img.shields.io/npm/dm/connect-mssql.svg?style=flat-square
[downloads-url]: https://www.npmjs.com/package/connect-mssql
[david-image]: https://img.shields.io/david/patriksimek/connect-mssql.svg?style=flat-square
[david-url]: https://david-dm.org/patriksimek/connect-mssql
[appveyor-image]: https://img.shields.io/appveyor/ci/patriksimek/connect-mssql/master.svg?style=flat-square&label=tests
[appveyor-url]: https://ci.appveyor.com/project/patriksimek/connect-mssql

[mssql-url]: https://github.com/patriksimek/node-mssql
[mssql-image]: https://img.shields.io/github/stars/patriksimek/node-mssql.svg?style=flat-square&label=%E2%98%85
