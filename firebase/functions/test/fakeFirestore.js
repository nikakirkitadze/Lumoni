/**
 * A small in-memory stand-in for the Admin SDK Firestore surface that
 * accountDeletion.js uses. Documents live in a flat Map keyed by path, and
 * every read and write is appended to `db.log` so tests can assert ordering.
 * Every change to a path bumps a per-path version, which is what
 * `runTransaction` uses to detect a concurrent write and retry.
 */

const DELETE = Symbol("FieldValue.delete");
const SERVER_TIMESTAMP = Symbol("FieldValue.serverTimestamp");

class FakeTimestamp {
  constructor(millis) {
    this._millis = millis;
  }

  static fromMillis(millis) {
    return new FakeTimestamp(millis);
  }

  static now() {
    return new FakeTimestamp(Date.now());
  }

  toMillis() {
    return this._millis;
  }

  valueOf() {
    return this._millis;
  }
}

const FakeFieldValue = {
  delete: () => DELETE,
  serverTimestamp: () => SERVER_TIMESTAMP,
};

function clone(value) {
  if (Array.isArray(value)) return value.map(clone);
  if (value && typeof value === "object" && Object.getPrototypeOf(value) === Object.prototype) {
    const out = {};
    for (const [key, inner] of Object.entries(value)) out[key] = clone(inner);
    return out;
  }
  return value;
}

function comparable(value) {
  if (value instanceof Date) return value.getTime();
  return value && typeof value.toMillis === "function" ? value.toMillis() : value;
}

/// Mirrors the Admin SDK's gRPC-coded errors (5 NOT_FOUND, 6 ALREADY_EXISTS).
function grpcError(code, status, path) {
  return Object.assign(new Error(`${code} ${status}: ${path}`), { code });
}

class DocumentSnapshot {
  constructor(ref, data, version) {
    this.ref = ref;
    this.id = ref.id;
    this.exists = data !== undefined;
    this._data = data;
    this._version = version;
  }

  data() {
    return this._data === undefined ? undefined : clone(this._data);
  }
}

class QuerySnapshot {
  constructor(docs) {
    this.docs = docs;
    this.size = docs.length;
    this.empty = docs.length === 0;
  }
}

class DocumentReference {
  constructor(db, path) {
    this._db = db;
    this.path = path;
    this.id = path.split("/").pop();
  }

  collection(name) {
    return new CollectionReference(this._db, `${this.path}/${name}`);
  }

  async get() {
    this._db.log.push({ op: "get", path: this.path });
    return new DocumentSnapshot(this, this._db._docs.get(this.path), this._db._version(this.path));
  }

  async create(data) {
    this._db._apply({ op: "create", ref: this, data });
  }

  async set(data, options) {
    this._db._apply({ op: "set", ref: this, data, options });
  }

  async update(data) {
    this._db._apply({ op: "update", ref: this, data });
  }

  async delete() {
    this._db._apply({ op: "delete", ref: this });
  }
}

class Query {
  constructor(db, path, spec = {}) {
    this._db = db;
    this.path = path;
    this._filters = spec.filters || [];
    this._limit = spec.limit === undefined ? null : spec.limit;
    this._orderBy = spec.orderBy || [];
    this._startAfter = spec.startAfter || null;
  }

  _with(changes) {
    return new Query(this._db, this.path, {
      filters: this._filters,
      limit: this._limit,
      orderBy: this._orderBy,
      startAfter: this._startAfter,
      ...changes,
    });
  }

  where(field, op, value) {
    return this._with({ filters: [...this._filters, { field, op, value }] });
  }

  orderBy(field, direction = "asc") {
    return this._with({ orderBy: [...this._orderBy, { field, direction }] });
  }

  limit(count) {
    return this._with({ limit: count });
  }

  startAfter(cursor) {
    if (!(cursor instanceof DocumentSnapshot)) {
      throw new Error("Fake Firestore startAfter only supports a DocumentSnapshot cursor");
    }
    return this._with({ startAfter: cursor });
  }

  async get() {
    this._db.log.push({
      op: "query",
      path: this.path,
      filters: this._filters.map(({ field, op }) => `${field} ${op}`),
      orderBy: this._orderBy.map(({ field, direction }) => `${field} ${direction}`),
      limit: this._limit,
    });

    // Like Firestore, a range filter or orderBy on a field excludes documents
    // that don't have that field.
    const inequalityFields = this._filters
      .filter(({ op }) => ["<", "<=", ">", ">="].includes(op))
      .map(({ field }) => field);
    for (const field of new Set(inequalityFields)) {
      if (!this._orderBy.length || this._orderBy[0].field === field) continue;
      throw new Error(`Fake Firestore: first orderBy must be on inequality field ${field}`);
    }

    const depth = this.path.split("/").length + 1;
    let rows = [];
    for (const [path, data] of this._db._docs.entries()) {
      if (!path.startsWith(`${this.path}/`) || path.split("/").length !== depth) continue;
      if (!this._filters.every((filter) => matches(data, filter))) continue;
      if (!this._orderBy.every(({ field }) => data[field] !== undefined)) continue;
      rows.push({ path, data });
    }

    const compareRows = (a, b) => {
      for (const { field, direction } of this._orderBy) {
        const x = comparable(a.data[field]);
        const y = comparable(b.data[field]);
        if (x < y) return direction === "desc" ? 1 : -1;
        if (x > y) return direction === "desc" ? -1 : 1;
      }
      return a.path.localeCompare(b.path);
    };
    rows.sort(compareRows);

    if (this._startAfter) {
      const cursor = { path: this._startAfter.ref.path, data: this._startAfter._data || {} };
      rows = rows.filter((row) => compareRows(row, cursor) > 0);
    }
    if (this._limit !== null) rows = rows.slice(0, this._limit);

    return new QuerySnapshot(
      rows.map(({ path, data }) => new DocumentSnapshot(new DocumentReference(this._db, path), data)),
    );
  }
}

function matches(data, { field, op, value }) {
  const actual = data[field];
  switch (op) {
    case "==":
      return comparable(actual) === comparable(value);
    case "array-contains":
      return Array.isArray(actual) && actual.includes(value);
    case ">=":
      return actual !== undefined && comparable(actual) >= comparable(value);
    case ">":
      return actual !== undefined && comparable(actual) > comparable(value);
    case "<=":
      return actual !== undefined && comparable(actual) <= comparable(value);
    case "<":
      return actual !== undefined && comparable(actual) < comparable(value);
    default:
      throw new Error(`Fake Firestore does not support operator ${op}`);
  }
}

class CollectionReference extends Query {
  constructor(db, path) {
    super(db, path);
    this.id = path.split("/").pop();
  }

  doc(id) {
    const docId = id || `auto_${++this._db._autoId}`;
    return new DocumentReference(this._db, `${this.path}/${docId}`);
  }
}

class WriteBatch {
  constructor(db) {
    this._db = db;
    this._ops = [];
    this._committed = false;
  }

  _add(op) {
    if (this._committed) throw new Error("Cannot modify a WriteBatch that has been committed.");
    this._ops.push(op);
    if (this._ops.length > 500) throw new Error("A batch may contain at most 500 operations.");
    return this;
  }

  set(ref, data, options) {
    return this._add({ op: "set", ref, data, options });
  }

  update(ref, data) {
    return this._add({ op: "update", ref, data });
  }

  delete(ref) {
    return this._add({ op: "delete", ref });
  }

  async commit() {
    if (this._committed) throw new Error("Cannot commit a WriteBatch that has been committed.");
    this._committed = true;
    this._db.batchSizes.push(this._ops.length);
    for (const op of this._ops) {
      if (op.op === "update" && !this._db._docs.has(op.ref.path)) {
        throw grpcError(5, "NOT_FOUND", op.ref.path);
      }
    }
    for (const op of this._ops) this._db._apply(op);
  }
}

/// The document store. Any set or delete — including a test mutating `_docs`
/// directly from a hook — bumps that path's version.
class VersionedDocs extends Map {
  constructor(versions) {
    super();
    this._versions = versions;
  }

  set(path, data) {
    this._versions.set(path, (this._versions.get(path) || 0) + 1);
    return super.set(path, data);
  }

  delete(path) {
    if (!this.has(path)) return false;
    this._versions.set(path, (this._versions.get(path) || 0) + 1);
    return super.delete(path);
  }
}

/// Optimistic concurrency: reads record the version they saw, and commit
/// fails (so the callback re-runs) if any of them changed in the meantime.
class Transaction {
  constructor(db) {
    this._db = db;
    this._reads = new Map();
    this._ops = [];
  }

  async get(ref) {
    if (!(ref instanceof DocumentReference)) {
      throw new Error("Fake Firestore transactions only support document reads");
    }
    if (this._ops.length) {
      throw new Error("Firestore transactions require all reads to be executed before all writes.");
    }
    const snap = await ref.get();
    if (!this._reads.has(ref.path)) this._reads.set(ref.path, snap._version);
    return snap;
  }

  set(ref, data, options) {
    this._ops.push({ op: "set", ref, data, options });
    return this;
  }

  update(ref, data) {
    this._ops.push({ op: "update", ref, data });
    return this;
  }

  delete(ref) {
    this._ops.push({ op: "delete", ref });
    return this;
  }

  /// Synchronous, so nothing can interleave between validation and apply.
  /// Returns false on a conflict.
  _commit() {
    const db = this._db;
    // Hooks run first: one may simulate a writer landing just before commit.
    if (db.beforeWrite) {
      for (const { op, ref, data } of this._ops) db.beforeWrite({ op, path: ref.path, data });
    }
    for (const [path, version] of this._reads) {
      if (db._version(path) !== version) return false;
    }
    for (const op of this._ops) {
      if (op.op === "update" && !db._docs.has(op.ref.path)) {
        throw grpcError(5, "NOT_FOUND", op.ref.path);
      }
    }
    for (const op of this._ops) db._apply(op, { hooks: false });
    return true;
  }
}

class FakeFirestore {
  constructor({ clock = () => Date.now() } = {}) {
    this._versions = new Map();
    this._docs = new VersionedDocs(this._versions);
    this._autoId = 0;
    this._clock = clock;
    this.log = [];
    this.batchSizes = [];
    this.transactionRetries = 0;
    // Hooks run before a single-document write lands; a hook can throw to
    // simulate a failure or mutate the store to simulate a concurrent writer.
    this.beforeWrite = null;
  }

  collection(name) {
    return new CollectionReference(this, name);
  }

  doc(path) {
    return new DocumentReference(this, path);
  }

  batch() {
    return new WriteBatch(this);
  }

  /// Like the Admin SDK: re-runs `fn` when the commit conflicts, up to
  /// `maxAttempts` (default 5), then fails with ABORTED. An error thrown by
  /// `fn` or by the commit is not retried.
  async runTransaction(fn, { maxAttempts = 5 } = {}) {
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      const transaction = new Transaction(this);
      const result = await fn(transaction);
      if (transaction._commit()) return result;
      this.transactionRetries++;
    }
    throw grpcError(10, "ABORTED", "transaction");
  }

  async recursiveDelete(ref) {
    this.log.push({ op: "recursiveDelete", path: ref.path });
    for (const path of [...this._docs.keys()]) {
      if (path === ref.path || path.startsWith(`${ref.path}/`)) {
        this._docs.delete(path);
        this.log.push({ op: "delete", path });
      }
    }
  }

  // ── Test conveniences ──

  seed(path, data) {
    this._docs.set(path, clone(data));
  }

  read(path) {
    const data = this._docs.get(path);
    return data === undefined ? undefined : clone(data);
  }

  has(path) {
    return this._docs.has(path);
  }

  paths() {
    return [...this._docs.keys()].sort();
  }

  writesTo(path) {
    return this.log.filter((entry) => entry.path === path && ["set", "update", "delete"].includes(entry.op));
  }

  _resolve(value) {
    if (value === SERVER_TIMESTAMP) return new FakeTimestamp(this._clock());
    return clone(value);
  }

  _version(path) {
    return this._versions.get(path) || 0;
  }

  _apply({ op, ref, data, options }, { hooks = true } = {}) {
    if (hooks && this.beforeWrite) this.beforeWrite({ op, path: ref.path, data });
    this.log.push({ op, path: ref.path });
    const existing = this._docs.get(ref.path);

    if (op === "delete") {
      this._docs.delete(ref.path);
      return;
    }

    if (op === "update" && existing === undefined) {
      throw grpcError(5, "NOT_FOUND", ref.path);
    }

    if (op === "create" && existing !== undefined) {
      throw grpcError(6, "ALREADY_EXISTS", ref.path);
    }

    const base = op === "update" || (options && options.merge) ? { ...(existing || {}) } : {};
    for (const [key, value] of Object.entries(data)) {
      if (value === DELETE) {
        delete base[key];
      } else {
        base[key] = this._resolve(value);
      }
    }
    this._docs.set(ref.path, base);
  }
}

module.exports = {
  FakeFirestore,
  FakeFieldValue,
  FakeTimestamp,
};
