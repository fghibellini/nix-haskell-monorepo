
# Hello

Welcome to our project

```
curl -f -XPOST http://localhost:3000/postOrder -H 'Content-type: application/json' -d@- <<EOF
{ "cartId": "$(uuidgen)" }
EOF
```

this request will persist an order in our system.
