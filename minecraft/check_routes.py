#!/usr/bin/env python3
"""Check Minecraft status/pong responses without logging in or modifying a world."""
import argparse, io, json, socket, struct

ROUTES = {"np.hanasand.com": 774, "name-pending.hanasand.com": 774, "67.hanasand.com": 767, "cobbleverse.hanasand.com": 767}

def varint(value):
    data = bytearray()
    while value > 127:
        data.append((value & 127) | 128)
        value >>= 7
    return bytes(data + bytes([value]))

def read_varint(stream):
    result = 0
    for shift in range(0, 35, 7):
        b = stream.read(1)
        if not b:
            raise EOFError("Connection closed before packet completed")
        result |= (b[0] & 127) << shift
        if not b[0] & 128:
            return result
    raise ValueError("Invalid VarInt")

def query(connect, port, hostname, protocol, forge=False):
    name = (hostname + ("\0FML3\0" if forge else "")).encode()
    handshake = b'\0' + varint(protocol) + varint(len(name)) + name + struct.pack('>H', port) + b'\1'
    with socket.create_connection((connect, port), 10) as sock:
        sock.settimeout(15)
        sock.sendall(varint(len(handshake)) + handshake + b'\1\0')
        stream = sock.makefile('rb')
        length = read_varint(stream)
        if length > 2**20:
            raise ValueError('Oversized status response')
        payload = io.BytesIO(stream.read(length))
        assert read_varint(payload) == 0
        response = json.loads(payload.read(read_varint(payload)))
        sock.sendall(b'\x09\x01' + struct.pack('>q', 443))
        assert read_varint(stream) == 9 and stream.read(9) == b'\x01' + struct.pack('>q', 443)
        return response

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--connect', help='Override connection address; keep each route hostname in the handshake')
    parser.add_argument('--port', type=int, default=443)
    parser.add_argument('--forge', action='store_true', help='Include the NeoForge handshake marker for 67')
    args = parser.parse_args()
    for name, protocol in ROUTES.items():
        result = query(args.connect or name, args.port, name, protocol, args.forge and name.startswith('67.'))
        assert result['version']['protocol'] == protocol, (name, result['version'])
        print(name, json.dumps({k: result[k] for k in ['version','description','players']}), flush=True)
