#!/usr/bin/env python3
"""幻想乡 HTTPS 服务器：静态文件 + /api/ai/intent 代理（转发到手机反向隧道 18002）"""
import http.server, ssl, os, json, urllib.request

BUILD = "/root/fantasia/build"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=BUILD, **kw)

    def do_POST(self):
        if self.path == "/api/ai/intent":
            length = int(self.headers.get('Content-Length', 0) or 0)
            body = self.rfile.read(length) if length else b'{}'
            print(f"[AI请求] {body.decode('utf-8','replace')[:100]}", flush=True)
            try:
                req = urllib.request.Request(
                    "http://127.0.0.1:18002/intent", data=body, method="POST")
                with urllib.request.urlopen(req, timeout=150) as r:
                    resp = r.read()
                    print(f"[AI响应] {resp.decode('utf-8','replace')[:120]}", flush=True)
            except Exception as e:
                resp = json.dumps({"intent": "在树下发呆", "ok": False,
                                   "error": str(e)[:80]}, ensure_ascii=False).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(resp)))
            self.end_headers()
            self.wfile.write(resp)
        else:
            self.send_error(404)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, *a):
        pass

if __name__ == "__main__":
    server = http.server.ThreadingHTTPServer(("0.0.0.0", 8080), Handler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain("/root/fantasia/cert.pem", "/root/fantasia/key.pem")
    server.socket = ctx.wrap_socket(server.socket, server_side=True)
    print("HTTPS 8080 + AI 代理", flush=True)
    server.serve_forever()
