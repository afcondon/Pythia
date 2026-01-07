# FFI stub for PureScript compiler - actual implementation is in WebSocket.js
# This module is designed for browser JavaScript only.

def browser_only(name):
    raise Exception(
        f"Web.WebSocket.{name}: This module is for browser JavaScript only. "
        f"Use Server.WebSocket for Python WebSocket server operations."
    )

create = lambda url: lambda: browser_only("create")
createWithProtocolImpl = lambda url, protocol: lambda: browser_only("createWithProtocol")
readyStateImpl = lambda ws: lambda: browser_only("readyState")
getUrl = lambda ws: lambda: browser_only("getUrl")
getProtocol = lambda ws: lambda: browser_only("getProtocol")
sendText = lambda ws: lambda msg: lambda: browser_only("sendText")
onOpen = lambda ws: lambda handler: lambda: browser_only("onOpen")
onCloseImpl = lambda ws, handler: lambda: browser_only("onClose")
onMessageImpl = lambda ws, handler: lambda: browser_only("onMessage")
onErrorImpl = lambda ws, handler: lambda: browser_only("onError")
close = lambda ws: lambda: browser_only("close")
closeWithCodeImpl = lambda ws, code, reason: lambda: browser_only("closeWithCode")
getMessageData = lambda event: browser_only("getMessageData")
