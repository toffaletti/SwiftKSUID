# SwiftKSUID

KSUID implementation for Swift.

```
import SwiftKSUID

let k = KSUID()
print(k)
```

> 25rmV7rssGHN3Bi9zpeqyZZASrC

```
import SwiftKSUID

let k = try KSUID("25rmV7rssGHN3Bi9zpeqyZZASrC")
print(k.timestamp)
print(k.payload.base64EncodedString())
```

> 2022-03-03 07:46:39 +0000

> 8HIkaqwzf22H9wm8/B1z0g==
