# Security Policy

SwiftPacket reads data that exploiters control, so security reports are taken
seriously.

## Supported versions

Only the latest release receives security fixes.

| Version | Supported |
| --- | --- |
| 0.1.x (latest) | Yes |
| Older | No |

## Reporting a vulnerability

Please do not open a public issue, pull request or discussion for a
vulnerability. Email **mail@skaterstudios.com** instead.

Include as much of the following as you can:

- The SwiftPacket version you tested.
- What an attacker can do, and whether it needs a modified client.
- Steps or a place file that reproduces it, such as the buffer a client sends.
- Any fix or mitigation you have in mind.

You will get a reply confirming the report was received. Once the issue is
confirmed, a fix is prepared and released, and you are credited in the
changelog unless you ask not to be.

## Scope

Reports are most useful when they show a client can:

- Crash, freeze or noticeably slow down a server.
- Get a message past the byte budget, a rate limit or a validator.
- Make the server read values its types should reject, such as NaN or an
  out of range index.
- Cause a request or response to reach the wrong handler or the wrong player.

Bugs in your own handlers, such as trusting a value a client sent, are outside
the scope of this policy.
