# 《幻想乡》后端骨架 v0.1
# FastAPI + SQLite：世界状态 / 角色 / 消息
# 部署：阿里云 47.97.177.2:8000

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import sqlite3, json, time, os

DB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fantasia.db")
app = FastAPI(title="幻想乡 API", version="0.1")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

def db():
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = db()
    conn.executescript("""
    CREATE TABLE IF NOT EXISTS worlds (
        id TEXT PRIMARY KEY, name TEXT, data TEXT, updated_at REAL
    );
    CREATE TABLE IF NOT EXISTS agents (
        id TEXT PRIMARY KEY, world_id TEXT, name TEXT, kind TEXT, data TEXT, updated_at REAL
    );
    CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT, world_id TEXT, sender TEXT, text TEXT, ts REAL
    );
    """)
    conn.commit(); conn.close()

init_db()

# ---------- 数据模型 ----------
class WorldIn(BaseModel):
    id: str = "default"
    name: str = "幻想乡"
    data: dict = {}

class AgentIn(BaseModel):
    id: str
    name: str
    kind: str = "npc"   # npc | player | ai
    data: dict = {}

class MessageIn(BaseModel):
    sender: str
    text: str
    world_id: str = "default"

# ---------- 接口 ----------
@app.get("/api/health")
def health():
    return {"ok": True, "service": "fantasia", "ts": time.time()}

@app.get("/api/world")
def get_world(world_id: str = "default"):
    conn = db()
    r = conn.execute("SELECT * FROM worlds WHERE id=?", (world_id,)).fetchone()
    conn.close()
    if not r:
        return {"id": world_id, "name": "幻想乡", "data": {}, "updated_at": 0}
    return {"id": r["id"], "name": r["name"], "data": json.loads(r["data"]), "updated_at": r["updated_at"]}

@app.post("/api/world")
def save_world(w: WorldIn):
    conn = db()
    conn.execute("INSERT INTO worlds(id,name,data,updated_at) VALUES(?,?,?,?) "
                 "ON CONFLICT(id) DO UPDATE SET name=excluded.name, data=excluded.data, updated_at=excluded.updated_at",
                 (w.id, w.name, json.dumps(w.data, ensure_ascii=False), time.time()))
    conn.commit(); conn.close()
    return {"ok": True}

@app.get("/api/agents")
def list_agents(world_id: str = "default"):
    conn = db()
    rows = conn.execute("SELECT * FROM agents WHERE world_id=?", (world_id,)).fetchall()
    conn.close()
    return {"agents": [{"id": r["id"], "name": r["name"], "kind": r["kind"],
                        "data": json.loads(r["data"])} for r in rows]}

@app.post("/api/agents")
def upsert_agent(a: AgentIn, world_id: str = "default"):
    conn = db()
    conn.execute("INSERT INTO agents(id,world_id,name,kind,data,updated_at) VALUES(?,?,?,?,?,?) "
                 "ON CONFLICT(id) DO UPDATE SET name=excluded.name, kind=excluded.kind, data=excluded.data, updated_at=excluded.updated_at",
                 (a.id, world_id, a.name, a.kind, json.dumps(a.data, ensure_ascii=False), time.time()))
    conn.commit(); conn.close()
    return {"ok": True}

@app.get("/api/messages")
def get_messages(world_id: str = "default", limit: int = 50):
    conn = db()
    rows = conn.execute("SELECT * FROM messages WHERE world_id=? ORDER BY id DESC LIMIT ?", (world_id, limit)).fetchall()
    conn.close()
    return {"messages": [{"sender": r["sender"], "text": r["text"], "ts": r["ts"]} for r in reversed(rows)]}

@app.post("/api/messages")
def post_message(m: MessageIn):
    if not m.text.strip():
        raise HTTPException(400, "empty text")
    conn = db()
    conn.execute("INSERT INTO messages(world_id,sender,text,ts) VALUES(?,?,?,?)",
                 (m.world_id, m.sender, m.text.strip()[:500], time.time()))
    conn.commit(); conn.close()
    return {"ok": True}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
