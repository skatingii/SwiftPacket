---
layout: home

hero:
  name: SwiftPacket
  text: Typed, batched networking for Roblox
  tagline: Define a packet in one line. Fire it like a function.
  actions:
    - theme: brand
      text: Crash course
      link: /tut/crash-course/1-introduction
    - theme: alt
      text: API reference
      link: /api/swiftpacket

features:
  - title: Fully typed
    details: Argument and response types are inferred from the definition, with no casts anywhere.
  - title: Small on the wire
    details: Values are written into buffers with exact sizes and sent once per frame.
  - title: Safe by default
    details: Every batch from a client is bounds checked and budgeted before a handler runs.
---
