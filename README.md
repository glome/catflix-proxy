# catflix-proxy

## Usage

Change config.json to your taste.

```
> npm install -g coffee-script
> npm install
> coffee proxy
```
## Explanation

Proxy enables browser request with cors restrictions.
This proxy replaces Cookie/Set-Cookie with token and token-exp headers.

It also adds Glome appId and uid so it doesn't have to stored in client app.