
# Hello

Welcome to our project

```
curl -XPOST http://localhost:3000/postOrder -d@- <<EOF
{ "cartId": "$(uuidgen)" }
EOF
```

this request will persist an order in our system.
