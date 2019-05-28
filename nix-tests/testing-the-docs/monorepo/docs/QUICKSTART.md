
# Hello

Welcome to our project

```
curl -XPOST http://localhost:3000/postOrder -d@- <<EOF
{ "cartId": "$(uuidgen)" }
EOF
```

and that's how you do it.
