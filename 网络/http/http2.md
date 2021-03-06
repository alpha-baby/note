## 参考

[HTTP/2 协议详解](https://github.com/jiajunhuang/http2-illustrated)

[http 详解](https://blog.wangriyu.wang/2018/05-HTTP2.html)

## 协议格式

[rfc7540](https://tools.ietf.org/html/rfc7540)

```txt
   The lifecycle of a stream is shown in Figure 2.

                                +--------+
                        send PP |        | recv PP
                       ,--------|  idle  |--------.
                      /         |        |         \
                     v          +--------+          v
              +----------+          |           +----------+
              |          |          | send H /  |          |
       ,------| reserved |          | recv H    | reserved |------.
       |      | (local)  |          |           | (remote) |      |
       |      +----------+          v           +----------+      |
       |          |             +--------+             |          |
       |          |     recv ES |        | send ES     |          |
       |   send H |     ,-------|  open  |-------.     | recv H   |
       |          |    /        |        |        \    |          |
       |          v   v         +--------+         v   v          |
       |      +----------+          |           +----------+      |
       |      |   half   |          |           |   half   |      |
       |      |  closed  |          | send R /  |  closed  |      |
       |      | (remote) |          | recv R    | (local)  |      |
       |      +----------+          |           +----------+      |
       |           |                |                 |           |
       |           | send ES /      |       recv ES / |           |
       |           | send R /       v        send R / |           |
       |           | recv R     +--------+   recv R   |           |
       | send R /  `----------->|        |<-----------'  send R / |
       | recv R                 | closed |               recv R   |
       `----------------------->|        |<----------------------'
                                +--------+

          send:   endpoint sends this frame
          recv:   endpoint receives this frame

          H:  HEADERS frame (with implied CONTINUATIONs)
          PP: PUSH_PROMISE frame (with implied CONTINUATIONs)
          ES: END_STREAM flag
          R:  RST_STREAM frame

                          Figure 2: Stream States
```


```txt
 All frames begin with a fixed 9-octet header followed by a variable-
   length payload.

    +-----------------------------------------------+
    |                 Length (24)                   |
    +---------------+---------------+---------------+
    |   Type (8)    |   Flags (8)   |
    +-+-------------+---------------+-------------------------------+
    |R|                 Stream Identifier (31)                      |
    +=+=============================================================+
    |                   Frame Payload (0...)                      ...
    +---------------------------------------------------------------+

                          Figure 1: Frame Layout

   The fields of the frame header are defined as:

   Length:  The length of the frame payload expressed as an unsigned
      24-bit integer.  Values greater than 2^14 (16,384) MUST NOT be
      sent unless the receiver has set a larger value for
      SETTINGS_MAX_FRAME_SIZE.

      The 9 octets of the frame header are not included in this value.





Belshe, et al.               Standards Track                   [Page 12]
 
RFC 7540                         HTTP/2                         May 2015


   Type:  The 8-bit type of the frame.  The frame type determines the
      format and semantics of the frame.  Implementations MUST ignore
      and discard any frame that has a type that is unknown.

   Flags:  An 8-bit field reserved for boolean flags specific to the
      frame type.

      Flags are assigned semantics specific to the indicated frame type.
      Flags that have no defined semantics for a particular frame type
      MUST be ignored and MUST be left unset (0x0) when sending.

   R: A reserved 1-bit field.  The semantics of this bit are undefined,
      and the bit MUST remain unset (0x0) when sending and MUST be
      ignored when receiving.

   Stream Identifier:  A stream identifier (see Section 5.1.1) expressed
      as an unsigned 31-bit integer.  The value 0x0 is reserved for
      frames that are associated with the connection as a whole as
      opposed to an individual stream.

   The structure and content of the frame payload is dependent entirely
   on the frame type.
```

一个请求流程的分析

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gho3pikp9gj31sk0rkgtk.jpg)

## 自己的理解

为了兼容 HTTP1.X 在对于客户端来说，使用逻辑上还是 request response的模式，

- 在HTTP1.0中，一组 request response 会新开一个tcp链接来发送
- 在HTTP1.1中，一组 request response 会复用一组tcp连接来发送
- 在HTTP2  中，一组 request response 会使用一个TCP连接上抽象出来一个Stream来发送(Straem Identifier 号码为同一个，如果是客户端主动发起的请求，那么StreamID为基数)，这一组请求结束后就会直接关闭这个Stream，下一组请求会自增StreamID+=2，

**http2的主要思想**：因为增加了一层二进制帧层，可以起到压缩数据，切分数据等手段，来达到加速传输数据的目的，但是这样就会增加解析数据的复杂程度

http2 的同一个Stream也会分方向，类似TCP协议，可以分为client -> server, server -> client 两个方向。例如：client可以给server发送`HEADERS`帧，server也可以给client发送`HEADERS`帧。

在正常情况下，如果client给server发送的数据完成，client则会发送`Flag(END STREAM)`给server，server给client 发送数据完成，那么server也会给client发送`Flag(END STREAM)`,这里就会发生HTTP2状态机的状态转换，关闭某个Stream。