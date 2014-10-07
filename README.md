# connect-mssql [![Dependency Status](https://david-dm.org/patriksimek/connect-mssql.png)](https://david-dm.org/patriksimek/connect-mssql) [![NPM version](https://badge.fury.io/js/connect-mssql.png)](http://badge.fury.io/js/connect-mssql)

SQL Server session store for Connect based on [node-mssql](https://github.com/patriksimek/node-mssql).

## Installation

    npm install connect-mssql

## Prerequisites

Before you can use session store, you must create a table named `sessions`.

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
    store: new MSSQLStore(config),
    secret: 'supersecret'
}));
```

## Configuration

To see all options please visit [node-mssql docs](https://github.com/patriksimek/node-mssql#cfg-basic).

<a name="license" />
## License

Copyright (c) 2014 Patrik Simek

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
