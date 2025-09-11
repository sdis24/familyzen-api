import express from "express";
import cors from "cors";

const app = express();
const PORT = process.env.PORT || 3000;

// CORS (autorise tout par défaut, ou une origin précise via CORS_ORIGIN)
const origin = process.env.CORS_ORIGIN || "*";
app.use(cors({ origin: origin === "*" ? true : origin, credentials: true }));

app.use(express.json({ limit: "1mb" }));

// Santé
app.get("/health", (_req, res) => res.status(200).send("ok"));

// Exemple d'endpoint attendu par l'app (renvoie du JSON)
app.post("/families/:id/assistant/suggest-plan", (req, res) => {
  const { id } = req.params;
  const input = req.body ?? {};
  // TODO: remplace par ta vraie logique métier
  res.json({
    familyId: id,
    ok: true,
    received: input,
    plan: []
  });
});

// 404 JSON propre
app.use((req, res) => {
  res.status(404).json({ ok: false, error: "Not found", path: req.originalUrl });
});

app.listen(PORT, () => {
  console.log(`API up on :${PORT}`);
});