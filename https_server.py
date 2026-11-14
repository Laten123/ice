import http.server, ssl, os
os.chdir("/root/fantasia/build")
server = http.server.HTTPServer(("0.0.0.0", 8080), http.server.SimpleHTTPRequestHandler)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain("/root/fantasia/cert.pem", "/root/fantasia/key.pem")
server.socket = ctx.wrap_socket(server.socket, server_side=True)
print("HTTPS on 8080")
server.serve_forever()
